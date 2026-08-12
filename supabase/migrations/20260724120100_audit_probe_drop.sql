-- Remove the temporary security-audit probe from 20260724120000_audit_probe.sql.
drop function if exists public._audit();
