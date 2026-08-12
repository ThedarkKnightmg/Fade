-- Fixes for 20260725100000_loyalty_ledger.sql:
--   1. my_referral_code used gen_random_bytes (pgcrypto, not enabled) → 42883.
--      Rebuild it on gen_random_uuid(), which is built in and already used for
--      table defaults.
--   2. Postgres grants EXECUTE to PUBLIC by default, so anon could call the
--      money RPCs (harmless — they're auth.uid()-scoped — but untidy). Revoke
--      PUBLIC and grant only authenticated. The internal referral-credit helper
--      is revoked from everyone (only booking_complete, as definer, calls it).

create or replace function public.my_referral_code()
returns text language plpgsql security definer set search_path = public as $$
declare v_code text;
begin
  select referral_code into v_code from public.profiles where id = auth.uid();
  if v_code is null then
    loop
      v_code := 'FADE' ||
        upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 5));
      exit when not exists (select 1 from public.profiles where referral_code = v_code);
    end loop;
    update public.profiles set referral_code = v_code where id = auth.uid();
  end if;
  return v_code;
end $$;

revoke execute on function public.points_balance()         from public;
revoke execute on function public.my_referral_code()       from public;
revoke execute on function public.set_referrer(text)       from public;
revoke execute on function public.booking_complete(uuid)   from public;
revoke execute on function public.points_redeem(int)       from public;
revoke execute on function public._maybe_credit_referral(uuid) from public;

grant execute on function public.points_balance()          to authenticated;
grant execute on function public.my_referral_code()        to authenticated;
grant execute on function public.set_referrer(text)        to authenticated;
grant execute on function public.booking_complete(uuid)    to authenticated;
grant execute on function public.points_redeem(int)        to authenticated;
