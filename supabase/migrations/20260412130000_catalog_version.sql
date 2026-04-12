-- Catalog versioning lets the client check whether a newer catalog is
-- available and fetch it on launch, so catalog updates (new items, tweaked
-- macros, dropped menu items) don't require an App Store release.
--
-- Flow:
--   1. Each catalog publish bumps `catalog_meta.current_version`.
--   2. The client stores the last-synced version in UserDefaults and calls
--      `rpc('catalog_version')` on launch.
--   3. If the remote version > local version, the client pulls
--      restaurants / restaurant_items / item_modifications and rebuilds
--      its in-memory catalog. The bundled JSON stays as a baseline/fallback.

create table if not exists catalog_meta (
  id integer primary key default 1,
  current_version text not null,
  published_at timestamptz not null default now(),
  notes text,
  constraint catalog_meta_singleton check (id = 1)
);

-- Read-only to clients: bump is performed by admin-only SQL during publish.
alter table catalog_meta enable row level security;

create policy "catalog_meta_public_read" on catalog_meta
  for select using (true);

-- Seed the current version. Subsequent publishes will update this row.
insert into catalog_meta (id, current_version, notes)
values (1, '2026-04-curated', 'Initial 68-item catalog across 9 chains.')
on conflict (id) do update set
  current_version = excluded.current_version,
  published_at = now(),
  notes = excluded.notes;

-- Helper RPC for cheap version probes. Clients call this on launch; if the
-- returned version differs from the cached one, they pull the full catalog.
create or replace function public.catalog_version()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select current_version from catalog_meta where id = 1;
$$;

grant execute on function public.catalog_version() to authenticated, anon;

-- Public read access to the catalog tables (they contain no user data).
-- RLS is off by default on these; make the intent explicit with a policy.
alter table restaurants enable row level security;
alter table restaurant_items enable row level security;
alter table item_modifications enable row level security;

drop policy if exists "restaurants_public_read" on restaurants;
create policy "restaurants_public_read" on restaurants
  for select using (true);

drop policy if exists "restaurant_items_public_read" on restaurant_items;
create policy "restaurant_items_public_read" on restaurant_items
  for select using (true);

drop policy if exists "item_modifications_public_read" on item_modifications;
create policy "item_modifications_public_read" on item_modifications
  for select using (true);
