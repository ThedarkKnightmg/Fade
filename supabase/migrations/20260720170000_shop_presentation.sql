-- Presentation fields for barbershops so real shops render as full cards, not
-- bare placeholders. Additive + defaulted, so existing rows and the read path
-- keep working. Owners fill these via the shop-edit flow; the seeder sets them
-- for the demo shops.
alter table public.barbershops
  add column if not exists tagline        text not null default '',
  add column if not exists description     text not null default '',
  add column if not exists cover_image_url text,
  add column if not exists gallery_urls    text[] not null default '{}',
  add column if not exists opening_hours   text not null default '',
  add column if not exists tags            text[] not null default '{}',
  add column if not exists price_level     int  not null default 2,
  add column if not exists is_featured     boolean not null default false;
