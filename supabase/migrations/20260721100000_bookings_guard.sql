-- SECURITY FIX — the booking write rules in schema.sql were never actually
-- live on this database. Verified by exploit: a signed-in client PATCHed
-- /bookings?id=eq.<own booking> with {"price":1} and the row's price really
-- became 1. That lets a client zero out what they owe (and, symmetrically,
-- lets a barber rewrite price/time on a booking). This migration re-asserts
-- the intended rules idempotently on the live schema.

-- 1. Drop any blanket/legacy UPDATE policy. `for update using (party)` lets
--    EITHER party rewrite ANY column straight from supabase-js, which is what
--    allowed the price rewrite above.
drop policy if exists "bookings_update"        on public.bookings;
drop policy if exists "bookings_write"         on public.bookings;
drop policy if exists "bookings_party_update"  on public.bookings;
drop policy if exists "bookings_update_party"  on public.bookings;
drop policy if exists "bookings_update_own"    on public.bookings;

-- 2. Only the two safe, self-serve transitions are allowed directly. Every
--    money/trust transition (completed, no_show, price) must go through a
--    SECURITY DEFINER RPC instead.
drop policy if exists "bookings_client_cancel" on public.bookings;
create policy "bookings_client_cancel" on public.bookings for update
  using (client_id = auth.uid() and status in ('requested','confirmed'))
  with check (client_id = auth.uid() and status = 'cancelled');

drop policy if exists "bookings_barber_respond" on public.bookings;
create policy "bookings_barber_respond" on public.bookings for update
  using (barber_id in (select public.my_barber_ids()) and status = 'requested')
  with check (barber_id in (select public.my_barber_ids())
              and status in ('confirmed','declined'));

-- 3. Belt-and-braces: make the money/identity/time columns immutable no matter
--    which policy a future change might open up.
create or replace function public.bookings_guard_immutable()
returns trigger language plpgsql as $$
begin
  if new.price     is distinct from old.price     then raise exception 'price is immutable'; end if;
  if new.client_id is distinct from old.client_id then raise exception 'client_id is immutable'; end if;
  if new.barber_id is distinct from old.barber_id then raise exception 'barber_id is immutable'; end if;
  if new.start_at  is distinct from old.start_at  then raise exception 'start_at is immutable'; end if;
  return new;
end $$;

drop trigger if exists trg_bookings_guard on public.bookings;
create trigger trg_bookings_guard before update on public.bookings
  for each row execute function public.bookings_guard_immutable();
