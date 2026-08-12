-- Close the two minor RLS gaps from the 2026-07-24 audit.

-- 1. shops_delete_own was scoped to role `public` (harmless — owner_id=auth.uid()
--    still blocks anon — but inconsistent with insert/update which are
--    `authenticated`). Re-create it scoped to authenticated.
drop policy if exists "shops_delete_own" on public.barbershops;
create policy "shops_delete_own" on public.barbershops for delete
  to authenticated
  using (owner_id = auth.uid());

-- 2. Reviews had insert but no update/delete policy, so an author could never
--    edit or remove their own review. Add owner-scoped update + delete. The
--    update CHECK repeats the insert guard (a real completed booking with that
--    barber) so a review can't be edited onto a barber the author never visited.
drop policy if exists "reviews_update_own" on public.reviews;
create policy "reviews_update_own" on public.reviews for update
  to authenticated
  using (client_id = auth.uid())
  with check (
    client_id = auth.uid()
    and exists (
      select 1 from public.bookings b
      where b.client_id = auth.uid()
        and b.barber_id = reviews.barber_id
        and b.status = 'completed'
    )
  );

drop policy if exists "reviews_delete_own" on public.reviews;
create policy "reviews_delete_own" on public.reviews for delete
  to authenticated
  using (client_id = auth.uid());

-- Re-attach the audit probe just long enough to verify the above landed; the
-- next migration drops it again.
create or replace function public._audit()
returns jsonb
language sql
security definer
set search_path = public, pg_catalog
as $$
  select jsonb_agg(jsonb_build_object(
           't', tablename, 'name', policyname, 'cmd', cmd,
           'roles', roles::text, 'using', qual, 'check', with_check)
         order by tablename, cmd)
  from pg_policies
  where schemaname = 'public' and tablename in ('barbershops','reviews');
$$;
grant execute on function public._audit() to anon;
