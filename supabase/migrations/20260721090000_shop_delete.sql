-- Let a shop owner remove their own shop. The write path already lets owners
-- create (shops_insert_own) and edit (shops_update_own) their shop, but there
-- was no delete policy — so an owner could never take their shop down. This
-- closes that gap, owner-scoped like the others. Services/barbers cascade or
-- null out via their existing FKs.
create policy "shops_delete_own" on public.barbershops for delete
  using (owner_id = auth.uid());
