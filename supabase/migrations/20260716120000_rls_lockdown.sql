-- ════════════════════════════════════════════════════════════════════════
-- RLS lockdown. Fixes two holes that were LIVE on the project: a public
-- read of every user's phone number, and self-service shop takeover.
--
-- Verified before writing this, against the live database, with only the
-- publishable key that ships inside the APK:
--   curl '.../rest/v1/profiles?select=full_name,phone' -H 'apikey: sb_publishable_...'
--   → 200 [{"full_name":"Johny Johnson",...},{"full_name":"WorkFlow",...}]
-- No account, no app, no foothold. Just the key printed in the client.
-- ════════════════════════════════════════════════════════════════════════

-- ── 1. profiles: stop publishing the user directory ─────────────────────
--
-- `for select using (true)` with no `to` clause defaults to TO PUBLIC, which
-- includes the **anon** role — the role the shipped key authenticates as. The
-- comment said "everyone signed in can read"; the policy said "everyone on
-- earth can read". In Uzbekistan a SIM is registered to a passport, so a
-- name→phone dump is an identity dossier, not a mailing list.
drop policy if exists "profiles_read" on public.profiles;

-- Your own row, and only yours. Anything another user legitimately needs to
-- see about you goes through public_profiles or an explicit RPC below.
create policy "profiles_read_own" on public.profiles for select
  to authenticated using (auth.uid() = id);

-- The public face of a user: no phone, no age, no role. A view owned by the
-- table owner runs with security_invoker off by default in older PG, so pin
-- it explicitly — otherwise the view would happily bypass the policy above.
create or replace view public.public_profiles
  with (security_invoker = true) as
  select id, full_name, avatar_url from public.profiles;

-- The view is only useful if the *caller* can read the underlying rows, which
-- profiles_read_own forbids. So expose it through a definer function instead:
-- a barber may look up a client only when that client actually booked them.
create or replace function public.client_contact_for_booking(p_booking uuid)
returns table (full_name text, phone text)
language sql stable security definer set search_path = public as $$
  select p.full_name, p.phone
  from public.bookings b
  join public.profiles p on p.id = b.client_id
  where b.id = p_booking
    and b.barber_id in (select public.my_barber_ids())
    -- 'confirmed' is the DB spelling; the Dart enum calls the same state
    -- 'upcoming'. Mixing the two is a silent no-match, so keep DB names here.
    and b.status in ('confirmed', 'completed');
$$;
revoke all on function public.client_contact_for_booking(uuid) from public, anon;
grant execute on function public.client_contact_for_booking(uuid) to authenticated;

-- profiles_update had no column restriction: a user could rewrite their own
-- `role` to 'barber' and their `phone` to any number — forging a verified
-- barber identity under someone else's phone. Identity columns are now
-- server-owned; the trigger and RPCs write them, the user never does.
drop policy if exists "profiles_update" on public.profiles;
create policy "profiles_update_own" on public.profiles for update
  to authenticated using (auth.uid() = id) with check (auth.uid() = id);

revoke update (id, phone, role) on public.profiles from authenticated;
grant update (full_name, avatar_url, age) on public.profiles to authenticated;

-- ── 2. barbers: a shop is not a field you can assign yourself ───────────
--
-- barbers_write authorised on profile_id alone and never checked WHICH shop
-- was being written. services_write then derived its authority from that same
-- attacker-controlled column. So: sign up, set your own shop_id to the
-- top-rated shop in Tashkent (its uuid is public), and you are on its roster
-- with full write over its menu — free to zero every price or delete it.
drop policy if exists "barbers_write" on public.barbers;
drop policy if exists "services_write" on public.services;

-- You may manage your own barber row, but you may only point it at a shop you
-- actually own. Joining someone else's shop is an owner decision (see the
-- join-request flow), never a self-assertion.
create policy "barbers_write_own" on public.barbers for all
  to authenticated
  using (profile_id = auth.uid())
  with check (
    profile_id = auth.uid()
    and (
      shop_id is null
      or shop_id in (select id from public.barbershops where owner_id = auth.uid())
    )
  );

-- Authority over a shop's menu now derives from OWNERSHIP, not from the
-- joinable barbers.shop_id column.
create policy "services_write_owner" on public.services for all
  to authenticated
  using (shop_id in (select id from public.barbershops where owner_id = auth.uid()))
  with check (shop_id in (select id from public.barbershops where owner_id = auth.uid()));

-- ── 3. barbers.rating is a marketplace verdict, not a self-assessment ───
-- barbers_write let a barber set their own public `rating` to 5.0 — the core
-- trust signal, attacker-controlled. Ratings are derived from reviews.
revoke update (rating, shop_id) on public.barbers from authenticated;

-- ── 4. reviews: you may only review a barber who actually cut your hair ──
drop policy if exists "reviews_insert" on public.reviews;
create policy "reviews_insert_after_visit" on public.reviews for insert
  to authenticated
  with check (
    client_id = auth.uid()
    and exists (
      select 1 from public.bookings b
      where b.client_id = auth.uid()
        and b.barber_id = reviews.barber_id
        and b.status = 'completed'
    )
  );

-- One review per completed visit — stops a single booking minting unlimited
-- 5-stars, and stops competitor review-bombing.
create unique index if not exists reviews_one_per_client_barber
  on public.reviews (client_id, barber_id);

-- ── 5. messages: only the two people on the booking ─────────────────────
drop policy if exists "messages_insert" on public.messages;
create policy "messages_insert_party" on public.messages for insert
  to authenticated
  with check (
    sender_id = auth.uid()
    and exists (
      select 1 from public.bookings b
      where b.id = messages.booking_id
        and (b.client_id = auth.uid() or b.barber_id in (select public.my_barber_ids()))
    )
  );

-- ── 6. tg_login_codes: codes must expire and be consumed ────────────────
-- A verified code previously replayed forever against an unauthenticated
-- endpoint that returned the phone number. Give them a TTL; the function
-- should also delete on read (one-shot).
alter table if exists public.tg_login_codes
  add column if not exists expires_at timestamptz not null default (now() + interval '10 minutes');

create index if not exists tg_login_codes_expires_idx
  on public.tg_login_codes (expires_at);

-- Housekeeping: purge dead codes so verified phone numbers are not retained.
create or replace function public.purge_expired_login_codes()
returns void language sql security definer set search_path = public as $$
  delete from public.tg_login_codes where expires_at < now();
$$;
