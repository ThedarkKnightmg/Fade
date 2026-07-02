-- ============================================================
-- Fade — Supabase database schema (Phase 1)
--
-- HOW TO RUN:
--   1. Create a free project at https://supabase.com
--   2. Dashboard → SQL Editor → New query
--   3. Paste this whole file → Run.
--
-- Safe to re-run: it drops and recreates everything.
-- ============================================================

-- ---------- Reset (dev convenience) ----------
drop table if exists public.reviews cascade;
drop table if exists public.messages cascade;
drop table if exists public.availability cascade;
drop table if exists public.bookings cascade;
drop table if exists public.services cascade;
drop table if exists public.barbers cascade;
drop table if exists public.barbershops cascade;
drop table if exists public.profiles cascade;
drop type if exists booking_status cascade;
drop type if exists app_role cascade;

-- ---------- Enums ----------
create type app_role as enum ('client', 'barber');
create type booking_status as enum (
  'requested', 'confirmed', 'completed', 'cancelled', 'declined', 'no_show'
);

-- ---------- Profiles (1:1 with auth.users) ----------
create table public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  full_name   text not null default '',
  phone       text,
  role        app_role not null default 'client',
  avatar_url  text,
  age         int,
  created_at  timestamptz not null default now()
);

-- ---------- Barbershops ----------
create table public.barbershops (
  id          uuid primary key default gen_random_uuid(),
  owner_id    uuid references public.profiles(id) on delete set null,
  name        text not null,
  address     text not null default '',
  lat         double precision not null default 41.3111,
  lng         double precision not null default 69.2797,
  is_premium  boolean not null default false,
  created_at  timestamptz not null default now()
);

-- ---------- Barbers (a profile working at a shop) ----------
create table public.barbers (
  id            uuid primary key default gen_random_uuid(),
  profile_id    uuid not null references public.profiles(id) on delete cascade,
  shop_id       uuid references public.barbershops(id) on delete set null,
  display_name  text not null,
  bio           text default '',
  photo_url     text,
  rating        numeric(2,1) not null default 5.0,
  is_active     boolean not null default true,
  created_at    timestamptz not null default now()
);

-- ---------- Services ----------
create table public.services (
  id            uuid primary key default gen_random_uuid(),
  shop_id       uuid not null references public.barbershops(id) on delete cascade,
  name          text not null,
  price         numeric not null default 0,
  duration_min  int not null default 30
);

-- ---------- Bookings (the heart of the two-sided loop) ----------
create table public.bookings (
  id          uuid primary key default gen_random_uuid(),
  client_id   uuid not null references public.profiles(id) on delete cascade,
  barber_id   uuid not null references public.barbers(id) on delete cascade,
  shop_id     uuid references public.barbershops(id) on delete set null,
  service_id  uuid references public.services(id) on delete set null,
  start_at    timestamptz not null,
  status      booking_status not null default 'requested',
  price       numeric not null default 0,
  note        text,
  created_at  timestamptz not null default now()
);
create index bookings_barber_idx on public.bookings (barber_id, start_at);
create index bookings_client_idx on public.bookings (client_id, start_at);

-- ---------- Availability (barber working hours) ----------
create table public.availability (
  id         uuid primary key default gen_random_uuid(),
  barber_id  uuid not null references public.barbers(id) on delete cascade,
  weekday    int not null check (weekday between 0 and 6),
  start_min  int not null,   -- minutes from midnight, e.g. 540 = 09:00
  end_min    int not null
);

-- ---------- Messages (one thread per booking) ----------
create table public.messages (
  id          uuid primary key default gen_random_uuid(),
  booking_id  uuid not null references public.bookings(id) on delete cascade,
  sender_id   uuid not null references public.profiles(id) on delete cascade,
  text        text not null,
  created_at  timestamptz not null default now()
);
create index messages_booking_idx on public.messages (booking_id, created_at);

-- ---------- Reviews ----------
create table public.reviews (
  id          uuid primary key default gen_random_uuid(),
  booking_id  uuid references public.bookings(id) on delete set null,
  client_id   uuid not null references public.profiles(id) on delete cascade,
  barber_id   uuid not null references public.barbers(id) on delete cascade,
  rating      int not null check (rating between 1 and 5),
  text        text,
  created_at  timestamptz not null default now()
);

-- ============================================================
-- Auto-create a profile row whenever someone signs up.
-- ============================================================
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, phone)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    new.phone
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============================================================
-- Row Level Security — the rules that keep clients & barbers
-- seeing only what they should.
-- ============================================================
alter table public.profiles    enable row level security;
alter table public.barbershops enable row level security;
alter table public.barbers     enable row level security;
alter table public.services    enable row level security;
alter table public.bookings    enable row level security;
alter table public.availability enable row level security;
alter table public.messages    enable row level security;
alter table public.reviews     enable row level security;

-- Helper: barber ids owned by the current user.
create or replace function public.my_barber_ids()
returns setof uuid language sql stable security definer set search_path = public as $$
  select id from public.barbers where profile_id = auth.uid();
$$;

-- Profiles: everyone signed in can read; edit only your own.
create policy "profiles_read"   on public.profiles for select using (true);
create policy "profiles_update" on public.profiles for update using (auth.uid() = id);

-- Shops / barbers / services / availability: public read.
create policy "shops_read"        on public.barbershops  for select using (true);
create policy "barbers_read"      on public.barbers      for select using (true);
create policy "services_read"     on public.services     for select using (true);
create policy "availability_read" on public.availability for select using (true);

-- A barber manages their own barber row, services, availability.
create policy "barbers_write" on public.barbers for all
  using (profile_id = auth.uid()) with check (profile_id = auth.uid());
create policy "services_write" on public.services for all
  using (shop_id in (select shop_id from public.barbers where profile_id = auth.uid()))
  with check (shop_id in (select shop_id from public.barbers where profile_id = auth.uid()));
create policy "availability_write" on public.availability for all
  using (barber_id in (select public.my_barber_ids()))
  with check (barber_id in (select public.my_barber_ids()));

-- Bookings: a client sees their own; a barber sees ones assigned to them.
create policy "bookings_read" on public.bookings for select using (
  client_id = auth.uid() or barber_id in (select public.my_barber_ids())
);
create policy "bookings_client_insert" on public.bookings for insert
  with check (client_id = auth.uid());
create policy "bookings_update" on public.bookings for update using (
  client_id = auth.uid() or barber_id in (select public.my_barber_ids())
);

-- Messages: only the two parties on the booking.
create policy "messages_read" on public.messages for select using (
  booking_id in (
    select id from public.bookings
    where client_id = auth.uid() or barber_id in (select public.my_barber_ids())
  )
);
create policy "messages_insert" on public.messages for insert
  with check (sender_id = auth.uid());

-- Reviews: public read; a client writes their own.
create policy "reviews_read"   on public.reviews for select using (true);
create policy "reviews_insert" on public.reviews for insert with check (client_id = auth.uid());

-- ============================================================
-- Realtime — push live changes to clients & barbers.
-- ============================================================
alter publication supabase_realtime add table public.bookings;
alter publication supabase_realtime add table public.messages;

-- Done. Next: connect the Flutter app (Phase 2).
