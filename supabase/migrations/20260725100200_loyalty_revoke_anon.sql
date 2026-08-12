-- Supabase grants EXECUTE on public functions to the `anon` role directly, so
-- `revoke ... from public` didn't stop unauthenticated calls. They're harmless
-- (every function is scoped to auth.uid(), which is null for anon → no-op), but
-- money RPCs should not be reachable without a session. Revoke from anon.
revoke execute on function public.points_balance()             from anon;
revoke execute on function public.my_referral_code()           from anon;
revoke execute on function public.set_referrer(text)           from anon;
revoke execute on function public.booking_complete(uuid)       from anon;
revoke execute on function public.points_redeem(int)           from anon;
revoke execute on function public._maybe_credit_referral(uuid) from anon;
