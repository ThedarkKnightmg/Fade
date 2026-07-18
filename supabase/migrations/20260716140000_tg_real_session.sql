-- Telegram login → REAL Supabase session, plus device-binding against
-- deep-link phishing. Adds the columns the reworked telegram-login function
-- needs; the flow itself lives in supabase/functions/telegram-login/index.ts.
--
-- Why each column:
--   device_hash  sha256 of a per-attempt secret the APP holds. The code is
--                registered (minted) by the app BEFORE the bot link opens, and
--                the verified result is only handed back to a poller that
--                presents the matching secret — so a stranger mass-polling
--                codes can't harvest a login in progress.
--   phrase       a two-word check phrase the app shows and the bot echoes. A
--                victim who never opened Fade sees a phrase they can't match
--                plus a "don't continue" warning — the human check that blunts
--                targeted t.me-link phishing.
--   token_hash   the one-time magic-link token the webhook mints (service role)
--                once the phone is verified. The app polls, reads it once, and
--                exchanges it via verifyOtp for a genuine session.

alter table if exists public.tg_login_codes
  add column if not exists device_hash text,
  add column if not exists phrase      text,
  add column if not exists token_hash  text;

-- The table is written only by the service-role Edge Function and never read
-- by the client directly (the client goes through the function). RLS stays on
-- with no anon policies, i.e. deny-all to anon — confirm that's the case.
alter table public.tg_login_codes enable row level security;
