-- ============================================================================
-- Phase 3A — Server-authoritative loyalty + referral ledger.
--
-- Moves Fade Points and referrals off the client (where a rooted phone can edit
-- SharedPreferences to mint free money) and onto the server. Balances live in
-- point_lots; every mutation goes through a SECURITY DEFINER RPC that enforces
-- the rules. RLS lets a user READ only their own rows and WRITE nothing directly
-- — the RPCs (which run as owner) are the only writers.
--
-- Money rules encoded here:
--   • Earn: 2.5% of a booking's price, once, only on a SERVER-verified completed
--     booking that belongs to the client. (= half the 5% commission.)
--   • Redeem: min 10,000, FIFO oldest-first, never more than the balance.
--   • Referral: 5,000 to the inviter, once, only when the invited friend
--     completes their FIRST cut (server-verified), never for self-referral.
--   • Expiry: points lapse 180 days after they're earned (breakage → profit).
-- ============================================================================

-- ---------- Referral code on the profile ----------
alter table public.profiles
  add column if not exists referral_code text unique;

-- ---------- Point lots (FIFO, with expiry) ----------
create table if not exists public.point_lots (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles(id) on delete cascade,
  remaining   int  not null check (remaining >= 0),
  source      text not null check (source in ('earn','referral')),
  booking_id  uuid references public.bookings(id) on delete set null,
  earned_at   timestamptz not null default now(),
  expires_at  timestamptz not null
);
create index if not exists point_lots_user_idx
  on public.point_lots(user_id, expires_at);
-- One earn per booking — makes points_earn idempotent.
create unique index if not exists point_lots_earn_once
  on public.point_lots(booking_id) where source = 'earn' and booking_id is not null;

-- ---------- Referrals ----------
create table if not exists public.referrals (
  id           uuid primary key default gen_random_uuid(),
  referrer_id  uuid not null references public.profiles(id) on delete cascade,
  referred_id  uuid not null references public.profiles(id) on delete cascade unique,
  code         text not null,
  status       text not null default 'pending'
                 check (status in ('pending','credited','void')),
  created_at   timestamptz not null default now(),
  credited_at  timestamptz,
  constraint no_self_referral check (referrer_id <> referred_id)
);

-- ---------- RLS: read your own; write only through the RPCs ----------
alter table public.point_lots enable row level security;
alter table public.referrals  enable row level security;

drop policy if exists point_lots_read on public.point_lots;
create policy point_lots_read on public.point_lots for select
  to authenticated using (user_id = auth.uid());

drop policy if exists referrals_read on public.referrals;
create policy referrals_read on public.referrals for select
  to authenticated using (referrer_id = auth.uid() or referred_id = auth.uid());
-- (No insert/update/delete policies: the SECURITY DEFINER RPCs below are the
--  only writers, so a client can never forge a lot or a referral.)

-- ---------- Balance ----------
create or replace function public.points_balance()
returns int language sql stable security definer set search_path = public as $$
  select coalesce(sum(remaining), 0)::int
  from public.point_lots
  where user_id = auth.uid() and expires_at > now();
$$;

-- ---------- Referral code (lazily generated, stable) ----------
create or replace function public.my_referral_code()
returns text language plpgsql security definer set search_path = public as $$
declare v_code text;
begin
  select referral_code into v_code from public.profiles where id = auth.uid();
  if v_code is null then
    loop
      v_code := 'FADE' || upper(substr(encode(gen_random_bytes(4), 'hex'), 1, 5));
      exit when not exists (select 1 from public.profiles where referral_code = v_code);
    end loop;
    update public.profiles set referral_code = v_code where id = auth.uid();
  end if;
  return v_code;
end $$;

-- ---------- Record who referred me (once, never myself) ----------
create or replace function public.set_referrer(p_code text)
returns boolean language plpgsql security definer set search_path = public as $$
declare v_ref uuid;
begin
  if exists (select 1 from public.referrals where referred_id = auth.uid()) then
    return false;                              -- already have a referrer
  end if;
  select id into v_ref from public.profiles
    where referral_code = upper(trim(p_code));
  if v_ref is null or v_ref = auth.uid() then
    return false;                              -- unknown code or self-referral
  end if;
  insert into public.referrals(referrer_id, referred_id, code, status)
    values (v_ref, auth.uid(), upper(trim(p_code)), 'pending');
  return true;
end $$;

-- ---------- Internal: credit the inviter on the friend's FIRST completed cut ----------
create or replace function public._maybe_credit_referral(p_user uuid)
returns void language plpgsql security definer set search_path = public as $$
declare v_ref uuid;
begin
  -- Only on the user's first completed booking.
  if (select count(*) from public.bookings
      where client_id = p_user and status = 'completed') <> 1 then
    return;
  end if;
  select referrer_id into v_ref from public.referrals
    where referred_id = p_user and status = 'pending';
  if v_ref is null then return; end if;
  update public.referrals
    set status = 'credited', credited_at = now()
    where referred_id = p_user;
  insert into public.point_lots(user_id, remaining, source, expires_at)
    values (v_ref, 5000, 'referral', now() + interval '180 days');
end $$;

-- ---------- Complete a booking (barber-only) → award points + referral ----------
-- The ONLY server path to 'completed'. The barber assigned to the booking calls
-- this (after the QR check-in). It flips status, awards the client 2.5% of the
-- price, and pays out any pending referral — all server-verified, so none of it
-- can be forged from a client.
create or replace function public.booking_complete(p_booking uuid)
returns int language plpgsql security definer set search_path = public as $$
declare v_client uuid; v_price numeric; v_status booking_status; v_pts int;
begin
  select client_id, price, status into v_client, v_price, v_status
    from public.bookings where id = p_booking;
  if v_client is null then return 0; end if;                 -- no such booking
  -- Caller must be the barber assigned to this booking.
  if not exists (
    select 1 from public.bookings b
    where b.id = p_booking and b.barber_id in (select public.my_barber_ids())
  ) then
    return 0;
  end if;
  if v_status <> 'confirmed' then return 0; end if;          -- only confirmed→completed
  update public.bookings set status = 'completed' where id = p_booking;

  -- Award the client their cashback (once per booking).
  v_pts := round(v_price * 0.025);
  if v_pts > 0 and not exists (
    select 1 from public.point_lots where booking_id = p_booking and source = 'earn'
  ) then
    insert into public.point_lots(user_id, remaining, source, booking_id, expires_at)
      values (v_client, v_pts, 'earn', p_booking, now() + interval '180 days');
  end if;

  perform public._maybe_credit_referral(v_client);
  return v_pts;
end $$;

-- ---------- Redeem points (min 10,000, FIFO oldest-first) ----------
create or replace function public.points_redeem(p_amount int)
returns int language plpgsql security definer set search_path = public as $$
declare v_bal int; v_want int; r record;
begin
  select public.points_balance() into v_bal;
  v_want := least(greatest(p_amount, 0), v_bal);
  if v_want < 10000 then return 0; end if;                   -- below minimum
  for r in
    select id, remaining from public.point_lots
    where user_id = auth.uid() and expires_at > now() and remaining > 0
    order by expires_at asc
  loop
    exit when v_want <= 0;
    if r.remaining <= v_want then
      v_want := v_want - r.remaining;
      delete from public.point_lots where id = r.id;
    else
      update public.point_lots set remaining = remaining - v_want where id = r.id;
      v_want := 0;
    end if;
  end loop;
  return least(greatest(p_amount, 0), v_bal);                -- amount applied
end $$;

-- ---------- Grants (authenticated users may call; anon may not) ----------
grant execute on function public.points_balance()          to authenticated;
grant execute on function public.my_referral_code()        to authenticated;
grant execute on function public.set_referrer(text)        to authenticated;
grant execute on function public.booking_complete(uuid)    to authenticated;
grant execute on function public.points_redeem(int)        to authenticated;
