-- ============================================================================
-- Google Play Billing: VIP subscription + Boost packs, verified server-side.
--
-- play-verify (Edge Function, user JWT) asks Google whether a purchase token
-- is real and paid, then grants through play_grant(). A token can grant once,
-- to one user: replaying a token, or someone else's token, grants nothing.
-- ============================================================================

create table if not exists public.play_purchases (
  purchase_token  text primary key,
  user_id         uuid not null references public.profiles(id) on delete cascade,
  product_id      text not null,
  order_id        text,
  granted_at      timestamptz not null default now()
);
create index if not exists play_purchases_user_idx on public.play_purchases(user_id);

create table if not exists public.entitlements (
  user_id     uuid primary key references public.profiles(id) on delete cascade,
  boosts      int not null default 0 check (boosts >= 0),
  vip_until   timestamptz,
  updated_at  timestamptz not null default now()
);

alter table public.play_purchases enable row level security;
alter table public.entitlements   enable row level security;

drop policy if exists play_purchases_read on public.play_purchases;
create policy play_purchases_read on public.play_purchases for select
  to authenticated using (user_id = auth.uid());
drop policy if exists entitlements_read on public.entitlements;
create policy entitlements_read on public.entitlements for select
  to authenticated using (user_id = auth.uid());
-- (No client writes: play_grant, called by the service role, is the writer.)

-- Grant a verified purchase once. Returns 'granted', 'already' (same user,
-- same token: a retry) or 'foreign' (token belongs to someone else).
create or replace function public.play_grant(
  p_user uuid, p_token text, p_product text, p_order text,
  p_boosts int, p_vip_until timestamptz
) returns text language plpgsql security definer set search_path = public as $$
declare v_owner uuid;
begin
  insert into public.play_purchases(purchase_token, user_id, product_id, order_id)
    values (p_token, p_user, p_product, p_order)
    on conflict (purchase_token) do nothing;
  if not found then
    select user_id into v_owner from public.play_purchases where purchase_token = p_token;
    return case when v_owner = p_user then 'already' else 'foreign' end;
  end if;

  insert into public.entitlements(user_id) values (p_user)
    on conflict (user_id) do nothing;
  update public.entitlements set
    boosts = boosts + greatest(coalesce(p_boosts, 0), 0),
    vip_until = case
      when p_vip_until is null then vip_until
      else greatest(coalesce(vip_until, p_vip_until), p_vip_until)
    end,
    updated_at = now()
  where user_id = p_user;
  return 'granted';
end $$;

revoke all on function public.play_grant(uuid, text, text, text, int, timestamptz)
  from public, anon, authenticated;
