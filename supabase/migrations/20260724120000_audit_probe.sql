-- TEMPORARY security-audit probe. Returns RLS on/off per table and every
-- policy's USING / WITH CHECK expression, so we can verify the live rules
-- match intent for authenticated (cross-tenant) access. Dropped immediately
-- after by 20260724120100_audit_probe_drop.sql. Reveals policy logic only,
-- never data.
create or replace function public._audit()
returns jsonb
language sql
security definer
set search_path = public, pg_catalog
as $$
  select jsonb_build_object(
    'rls', (
      select jsonb_agg(jsonb_build_object('t', c.relname, 'enabled', c.relrowsecurity)
                       order by c.relname)
      from pg_class c
      join pg_namespace n on n.oid = c.relnamespace
      where n.nspname = 'public' and c.relkind = 'r'
    ),
    'policies', (
      select jsonb_agg(jsonb_build_object(
               't', tablename, 'name', policyname, 'cmd', cmd,
               'roles', roles::text, 'using', qual, 'check', with_check)
             order by tablename, cmd)
      from pg_policies
      where schemaname = 'public'
    )
  );
$$;
grant execute on function public._audit() to anon;
