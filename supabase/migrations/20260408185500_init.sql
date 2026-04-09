create extension if not exists "pgcrypto";

create table if not exists profiles (
  user_id uuid primary key,
  goal text not null,
  calorie_target_default integer not null,
  protein_target_default integer not null,
  diet_flags text[] not null default '{}',
  disliked_foods text[] not null default '{}',
  created_at timestamptz not null default now()
);

create table if not exists restaurants (
  id text primary key,
  name text not null unique,
  region text not null,
  active boolean not null default true
);

create table if not exists restaurant_items (
  id text primary key,
  restaurant_id text not null references restaurants(id) on delete cascade,
  name text not null,
  category text not null,
  serving_description text not null,
  calories integer not null check (calories >= 0),
  protein integer not null check (protein >= 0),
  carbs integer not null check (carbs >= 0),
  fat integer not null check (fat >= 0),
  sodium_nullable integer,
  source_version text not null,
  source_url text not null,
  contexts text[] not null default '{}',
  tags text[] not null default '{}',
  popularity_prior numeric not null default 0.5,
  active boolean not null default true
);

create table if not exists item_modifications (
  id text primary key,
  restaurant_item_id text not null references restaurant_items(id) on delete cascade,
  modification_name text not null,
  calorie_delta integer not null default 0,
  protein_delta integer not null default 0,
  carbs_delta integer not null default 0,
  fat_delta integer not null default 0
);

create table if not exists queries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  target_calories integer not null,
  target_protein integer not null,
  target_carbs_nullable integer,
  target_fat_nullable integer,
  context text,
  top_result_name text not null,
  created_at timestamptz not null default now()
);

create table if not exists recommendations_served (
  id uuid primary key default gen_random_uuid(),
  query_id uuid not null references queries(id) on delete cascade,
  restaurant_item_id text not null references restaurant_items(id) on delete cascade,
  final_score numeric not null,
  explanation_short text not null,
  rank_position integer not null
);

create table if not exists favorites (
  user_id uuid not null,
  restaurant_item_id text not null references restaurant_items(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, restaurant_item_id)
);

create table if not exists feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  recommendation_id uuid references recommendations_served(id) on delete cascade,
  restaurant_item_id text not null references restaurant_items(id) on delete cascade,
  sentiment text not null,
  reason text not null,
  created_at timestamptz not null default now()
);

create table if not exists entitlements (
  user_id uuid primary key,
  subscription_status text not null,
  plan_name text not null,
  provider_customer_id text,
  updated_at timestamptz not null default now()
);

alter table profiles enable row level security;
alter table queries enable row level security;
alter table recommendations_served enable row level security;
alter table favorites enable row level security;
alter table feedback enable row level security;
alter table entitlements enable row level security;

create policy "profiles_select_own" on profiles
for select using (auth.uid() = user_id);

create policy "profiles_modify_own" on profiles
for all using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "queries_own" on queries
for all using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "recommendations_select_own" on recommendations_served
for select using (
  exists (
    select 1 from queries
    where queries.id = recommendations_served.query_id
      and queries.user_id = auth.uid()
  )
);

create policy "recommendations_insert_own" on recommendations_served
for insert with check (
  exists (
    select 1 from queries
    where queries.id = recommendations_served.query_id
      and queries.user_id = auth.uid()
  )
);

create policy "favorites_own" on favorites
for all using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "feedback_own" on feedback
for all using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "entitlements_own" on entitlements
for select using (auth.uid() = user_id);

create index if not exists restaurant_items_active_idx on restaurant_items(active);
create index if not exists restaurant_items_restaurant_idx on restaurant_items(restaurant_id);
create index if not exists queries_user_created_idx on queries(user_id, created_at desc);
