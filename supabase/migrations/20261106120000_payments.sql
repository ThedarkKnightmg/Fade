-- ============================================================================
-- Real payments: Payme + Click.
--
-- The app never grants anything for money. The flow is:
--   1. app  -> payments-create (Edge Function, user JWT): validates the purpose
--      and amount ON THE SERVER, inserts a `payments` row, returns checkout URLs.
--   2. user pays in the Payme / Click app or web checkout.
--   3. Payme / Click -> payme / click Edge Functions (provider-signed calls,
--      service role): run the provider protocol against this table.
--   4. On the provider's final "paid" call, payment_apply() grants the effect
--      (wallet credit / booking paid) exactly once, server-side.
--   5. app polls its own payments row (RLS: read your own) and mirrors the
--      result.
--
-- Amounts are stored in TIYIN (1 so'm = 100 tiyin), which is what Payme uses;
-- Click works in so'm and is converted at its boundary.
-- ============================================================================

-- ---------- Payments ----------
create table if not exists public.payments (
  id                 uuid primary key default gen_random_uuid(),
  user_id            uuid not null references public.profiles(id) on delete cascade,
  purpose            text not null check (purpose in ('wallet_topup','booking')),
  booking_id         uuid references public.bookings(id) on delete set null,
  amount_tiyin       bigint not null check (amount_tiyin > 0),
  status             text not null default 'created'
                       check (status in ('created','pending','paid','cancelled','failed')),
  provider           text check (provider in ('payme','click')),
  -- Provider transaction state (Payme: its transaction id + times + state;
  -- Click: click_trans_id + our prepare id).
  provider_txn_id    text,
  provider_state     int,          -- Payme: 1 created, 2 performed, -1/-2 cancelled
  provider_time      bigint,       -- Payme's create time (ms since epoch)
  create_time        bigint,       -- when WE accepted the provider transaction (ms)
  perform_time       bigint,
  cancel_time        bigint,
  cancel_reason      int,
  created_at         timestamptz not null default now(),
  paid_at            timestamptz,
  constraint booking_needs_id check (purpose <> 'booking' or booking_id is not null)
);
create index if not exists payments_user_idx on public.payments(user_id, created_at desc);
-- One provider transaction maps to exactly one payment (and back).
create unique index if not exists payments_provider_txn
  on public.payments(provider, provider_txn_id) where provider_txn_id is not null;

-- ---------- Bookings: paid flag ----------
alter table public.bookings
  add column if not exists paid_at timestamptz,
  add column if not exists payment_id uuid references public.payments(id) on delete set null;

-- ---------- Barber wallet (server-authoritative) ----------
create table if not exists public.wallets (
  user_id      uuid primary key references public.profiles(id) on delete cascade,
  balance_som  bigint not null default 0 check (balance_som >= 0),
  updated_at   timestamptz not null default now()
);
create table if not exists public.wallet_ledger (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles(id) on delete cascade,
  amount_som  bigint not null,               -- + credit, - debit
  kind        text not null check (kind in ('topup','topup_refund','commission')),
  payment_id  uuid references public.payments(id) on delete set null,
  booking_id  uuid references public.bookings(id) on delete set null,
  created_at  timestamptz not null default now()
);
create index if not exists wallet_ledger_user_idx on public.wallet_ledger(user_id, created_at desc);
-- A payment can credit a wallet once, and be refunded once.
create unique index if not exists wallet_ledger_once
  on public.wallet_ledger(payment_id, kind) where payment_id is not null;

-- ---------- RLS: read your own; no client writes at all ----------
alter table public.payments      enable row level security;
alter table public.wallets       enable row level security;
alter table public.wallet_ledger enable row level security;

drop policy if exists payments_read on public.payments;
create policy payments_read on public.payments for select
  to authenticated using (user_id = auth.uid());
drop policy if exists wallets_read on public.wallets;
create policy wallets_read on public.wallets for select
  to authenticated using (user_id = auth.uid());
drop policy if exists wallet_ledger_read on public.wallet_ledger;
create policy wallet_ledger_read on public.wallet_ledger for select
  to authenticated using (user_id = auth.uid());
-- (No insert/update/delete policies: only the Edge Functions (service role)
--  and the SECURITY DEFINER functions below write.)

-- ---------- Apply a confirmed payment, exactly once ----------
-- Called by the provider webhooks (service role) at the moment the provider
-- says the money moved. Idempotent: a second call is a no-op.
create or replace function public.payment_apply(p_payment uuid)
returns boolean language plpgsql security definer set search_path = public as $$
declare p public.payments;
begin
  select * into p from public.payments where id = p_payment for update;
  if p.id is null then return false; end if;
  if p.status = 'paid' then return true; end if;           -- already applied
  if p.status in ('cancelled','failed') then return false; end if;

  update public.payments set status = 'paid', paid_at = now() where id = p.id;

  if p.purpose = 'wallet_topup' then
    insert into public.wallets(user_id, balance_som) values (p.user_id, 0)
      on conflict (user_id) do nothing;
    insert into public.wallet_ledger(user_id, amount_som, kind, payment_id)
      values (p.user_id, p.amount_tiyin / 100, 'topup', p.id);
    update public.wallets
      set balance_som = balance_som + p.amount_tiyin / 100, updated_at = now()
      where user_id = p.user_id;
  elsif p.purpose = 'booking' then
    update public.bookings set paid_at = now(), payment_id = p.id
      where id = p.booking_id;
  end if;
  return true;
end $$;

-- ---------- Reverse a paid payment (provider refund / cancel after pay) ----------
-- Returns false when it can't be reversed: a wallet top-up that has already
-- been spent below its amount (the provider is then told "can't cancel").
create or replace function public.payment_reverse(p_payment uuid)
returns boolean language plpgsql security definer set search_path = public as $$
declare p public.payments; v_bal bigint;
begin
  select * into p from public.payments where id = p_payment for update;
  if p.id is null then return false; end if;
  if p.status <> 'paid' then
    update public.payments set status = 'cancelled' where id = p.id;
    return true;
  end if;
  if p.purpose = 'wallet_topup' then
    select balance_som into v_bal from public.wallets where user_id = p.user_id for update;
    if coalesce(v_bal, 0) < p.amount_tiyin / 100 then return false; end if;
    insert into public.wallet_ledger(user_id, amount_som, kind, payment_id)
      values (p.user_id, -(p.amount_tiyin / 100), 'topup_refund', p.id);
    update public.wallets
      set balance_som = balance_som - p.amount_tiyin / 100, updated_at = now()
      where user_id = p.user_id;
  elsif p.purpose = 'booking' then
    update public.bookings set paid_at = null where id = p.booking_id and payment_id = p.id;
  end if;
  update public.payments set status = 'cancelled' where id = p.id;
  return true;
end $$;

-- Only the service role (the webhooks) may apply or reverse payments.
revoke all on function public.payment_apply(uuid)   from public, anon, authenticated;
revoke all on function public.payment_reverse(uuid) from public, anon, authenticated;

-- ---------- My wallet balance (for the app) ----------
create or replace function public.wallet_balance()
returns bigint language sql stable security definer set search_path = public as $$
  select coalesce((select balance_som from public.wallets where user_id = auth.uid()), 0);
$$;
revoke all on function public.wallet_balance() from public, anon;
grant execute on function public.wallet_balance() to authenticated;
