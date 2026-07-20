-- Let a signed-in barber create and manage their OWN shop. Reads were already
-- public (shops_read); this adds the write side so real barbers persist onto
-- the map instead of only into the app's memory.
--
-- The matching barber-row and services inserts are already covered by
-- barbers_write_own and services_write_owner (20260716120000_rls_lockdown):
-- both authorise on ownership of the shop, which the creator has here.

-- Create: only a shop you own (owner_id must be you).
create policy "shops_insert_own" on public.barbershops for insert
  to authenticated
  with check (owner_id = auth.uid());

-- Edit: only your own shop; owner_id can't be reassigned away from you.
create policy "shops_update_own" on public.barbershops for update
  to authenticated
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());
