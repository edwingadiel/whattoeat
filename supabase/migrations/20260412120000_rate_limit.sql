-- Server-side rate limiting for free-tier daily search quota.
--
-- Rationale: the client previously enforced the free-tier cap (5 searches/day)
-- in UserDefaults, which is trivially bypassable. This moves the check to a
-- Postgres function + trigger so the server is the authority. The client still
-- shows a local usage gauge for UX, but the backend is the source of truth.

create or replace function public.search_count_today(target_user uuid)
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select count(*)::integer
  from queries
  where user_id = target_user
    and created_at >= (now() at time zone 'utc')::date;
$$;

grant execute on function public.search_count_today(uuid) to authenticated, anon;

-- Daily limit for free users. Plus users bypass via entitlements table.
create or replace function public.enforce_search_quota()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  plan_status text;
  today_count integer;
  daily_limit integer := 5;
begin
  -- Plus users bypass the quota entirely
  select subscription_status into plan_status
  from entitlements
  where user_id = new.user_id;

  if plan_status is not null and plan_status in ('active', 'trialing') then
    return new;
  end if;

  -- Count searches so far today (UTC) for this user
  select count(*) into today_count
  from queries
  where user_id = new.user_id
    and created_at >= (now() at time zone 'utc')::date;

  if today_count >= daily_limit then
    raise exception 'daily_search_limit_exceeded'
      using hint = 'Free tier allows 5 searches per day. Upgrade to Plus for unlimited.',
            errcode = 'P0001';
  end if;

  return new;
end;
$$;

drop trigger if exists enforce_search_quota_trigger on queries;
create trigger enforce_search_quota_trigger
  before insert on queries
  for each row
  execute function public.enforce_search_quota();

-- Similar guard for favorites (free cap of 5)
create or replace function public.enforce_favorites_quota()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  plan_status text;
  current_count integer;
  favorites_limit integer := 5;
begin
  select subscription_status into plan_status
  from entitlements
  where user_id = new.user_id;

  if plan_status is not null and plan_status in ('active', 'trialing') then
    return new;
  end if;

  select count(*) into current_count
  from favorites
  where user_id = new.user_id;

  if current_count >= favorites_limit then
    raise exception 'favorites_limit_exceeded'
      using hint = 'Free tier allows 5 saved meals. Upgrade to Plus for unlimited.',
            errcode = 'P0001';
  end if;

  return new;
end;
$$;

drop trigger if exists enforce_favorites_quota_trigger on favorites;
create trigger enforce_favorites_quota_trigger
  before insert on favorites
  for each row
  execute function public.enforce_favorites_quota();
