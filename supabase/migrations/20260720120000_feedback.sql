-- Feedback / bug reports / ideas from inside the app. Written ONLY by the
-- service-role `feedback` Edge Function (the app posts to the function, never
-- to this table directly), so RLS is on with no policies: deny-all to the anon
-- key, while the function's service role bypasses RLS to insert, and the owner
-- reads in the Supabase dashboard.
create table if not exists public.feedback (
  id         uuid primary key default gen_random_uuid(),
  category   text not null default 'other',   -- bug | idea | other
  message    text not null,
  contact    text,                            -- optional phone/telegram they left
  role       text,                            -- client | barber
  platform   text,
  created_at timestamptz not null default now()
);

create index if not exists feedback_created_idx on public.feedback (created_at desc);

alter table public.feedback enable row level security;
-- Intentionally no policies (deny-all to anon; service role bypasses RLS).
