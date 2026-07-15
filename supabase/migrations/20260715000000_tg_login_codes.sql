-- One-time login codes for "Continue with Telegram".
-- The app mints a code, opens t.me/<bot>?start=<code>; the bot webhook (the
-- telegram-login Edge Function, service role) flips it to verified. RLS is on
-- with NO policies on purpose: only the service role may read/write this — the
-- app polls through the function, never the table directly.
create table if not exists tg_login_codes (
  code text primary key,
  status text not null default 'pending',
  telegram_id bigint,
  name text,
  created_at timestamptz not null default now()
);

alter table tg_login_codes enable row level security;

-- Housekeeping: codes are short-lived; keep the table from growing forever.
create index if not exists tg_login_codes_created_at_idx
  on tg_login_codes (created_at);
