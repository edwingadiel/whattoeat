# WhatToEat Project Context

Last updated: 2026-04-08

## Product summary

WhatToEat is an iOS-first nutrition utility app focused on one job:

`I have X calories and need Y protein. What should I eat right now?`

This is not intended to become a full food logging platform like MyFitnessPal.
The MVP focuses on fast restaurant recommendations that fit calorie and macro goals,
with low-friction onboarding, deterministic ranking, and a lightweight paid tier.

## Original MVP plan

### Product direction

- Focus on speed, trust, and clarity.
- Return 3 strong recommendations rather than a giant list.
- Use curated nutrition data, not AI-generated nutrition truth.
- Monetize simply with a low-cost `Plus` plan.

### Core audience

- Gym-active or macro-aware adults
- Users who think in calories/protein
- People who eat fast food or chain restaurants often
- People who want to stay on track without tracking an entire day

### V1 scope

Included:

- iOS app only
- Onboarding
- Query flow for calories + protein
- Optional context: breakfast, lunch, dinner, snack, post-workout
- Recommendations from a limited set of chain restaurants
- Recommendation detail view with macros, explanation, and modifications
- Favorites
- Lightweight feedback
- Free + paid gating
- Supabase-backed persistence path

Explicitly deferred:

- Pantry / home mode
- Barcode scanning
- Full food logging
- Meal planning
- Grocery product support
- Android
- Coach/chat UI

### Initial restaurant set

- McDonald's
- Wendy's
- Taco Bell
- Subway
- Chipotle
- Chick-fil-A

## Current implementation status

The repo now contains a working SwiftUI MVP plus a real local Supabase development setup.

### Implemented in the app

- SwiftUI app shell
- Onboarding and profile capture
- Home/query builder
- Results screen
- Recommendation detail screen
- Favorites screen
- Profile screen
- Paywall screen
- Deterministic recommendation engine
- Local curated restaurant seed dataset
- Local persistence fallback
- Supabase local integration for:
  - anonymous auth
  - profile sync
  - favorites sync
  - query/history sync
  - feedback sync

### Still mocked or local-only

- RevenueCat subscriptions
- Analytics
- Crash reporting
- Recommendation serving persistence
- Recommendation engine execution still happens locally in-app
- Catalog still loads from local JSON, not from Supabase

## Repo structure

- `WhatToEat/`
  - SwiftUI app
- `WhatToEatTests/`
  - unit and integration tests
- `supabase/`
  - local schema, migration, seed, and edge-function scaffold
- `project.yml`
  - XcodeGen project definition
- `WhatToEat.xcodeproj`
  - generated project
- `PROJECT_CONTEXT.md`
  - this file

## Important app files

### App and architecture

- `/Users/sarasarai/Documents/whattoeat/WhatToEat/App/WhatToEatApp.swift`
- `/Users/sarasarai/Documents/whattoeat/WhatToEat/Views/RootView.swift`
- `/Users/sarasarai/Documents/whattoeat/WhatToEat/Core/AppServices.swift`
- `/Users/sarasarai/Documents/whattoeat/WhatToEat/Core/AppStore.swift`
- `/Users/sarasarai/Documents/whattoeat/WhatToEat/Core/RecommendationEngine.swift`
- `/Users/sarasarai/Documents/whattoeat/WhatToEat/Core/SupabaseConfig.swift`
- `/Users/sarasarai/Documents/whattoeat/WhatToEat/Core/SupabaseSyncService.swift`

### UI

- `/Users/sarasarai/Documents/whattoeat/WhatToEat/Views/OnboardingView.swift`
- `/Users/sarasarai/Documents/whattoeat/WhatToEat/Views/HomeView.swift`
- `/Users/sarasarai/Documents/whattoeat/WhatToEat/Views/ResultsView.swift`
- `/Users/sarasarai/Documents/whattoeat/WhatToEat/Views/RecommendationDetailView.swift`
- `/Users/sarasarai/Documents/whattoeat/WhatToEat/Views/FavoritesView.swift`
- `/Users/sarasarai/Documents/whattoeat/WhatToEat/Views/ProfileView.swift`
- `/Users/sarasarai/Documents/whattoeat/WhatToEat/Views/PaywallView.swift`

### Data and models

- `/Users/sarasarai/Documents/whattoeat/WhatToEat/Models/AppModels.swift`
- `/Users/sarasarai/Documents/whattoeat/WhatToEat/Resources/restaurant_seed.json`

### Tests

- `/Users/sarasarai/Documents/whattoeat/WhatToEatTests/RecommendationEngineTests.swift`
- `/Users/sarasarai/Documents/whattoeat/WhatToEatTests/SupabaseSyncIntegrationTests.swift`

## Local environment and installations

### Docker

Installed on this machine:

- App: `/Applications/Docker.app`
- CLI is available through `~/.local/bin/docker`
- `~/.zshrc` was updated to add `~/.local/bin` to `PATH`

Verified:

- `docker --version`
- `docker info`

### Supabase CLI

Installed as a project dev dependency through npm.

Relevant file:

- `/Users/sarasarai/Documents/whattoeat/package.json`

Useful scripts:

- `npm run supabase:start`
- `npm run supabase:stop`
- `npm run supabase:status`
- `npm run supabase:db:reset`
- `npm run supabase:db:push`
- `npm run supabase:functions:serve`

### XcodeGen

The project was bootstrapped using a locally built XcodeGen binary:

- `/tmp/XcodeGen/.build/release/xcodegen`

Regenerate the Xcode project with:

```bash
/tmp/XcodeGen/.build/release/xcodegen generate
```

## Supabase local setup

### Local config files

- `/Users/sarasarai/Documents/whattoeat/supabase/config.toml`
- `/Users/sarasarai/Documents/whattoeat/supabase/migrations/20260408185500_init.sql`
- `/Users/sarasarai/Documents/whattoeat/supabase/seed.sql`
- `/Users/sarasarai/Documents/whattoeat/.env.local.example`
- `/Users/sarasarai/Documents/whattoeat/.env.local`
- `/Users/sarasarai/Documents/whattoeat/WhatToEat/Support/Debug.xcconfig`
- `/Users/sarasarai/Documents/whattoeat/WhatToEat/Support/Release.xcconfig`

### Current local endpoints

From `supabase status`:

- Project URL: `http://127.0.0.1:54321`
- REST: `http://127.0.0.1:54321/rest/v1`
- GraphQL: `http://127.0.0.1:54321/graphql/v1`
- Database: `postgresql://postgres:postgres@127.0.0.1:54322/postgres`
- Mailpit: `http://127.0.0.1:54324`

### Auth keys

The app currently uses the local publishable key via:

- `/Users/sarasarai/Documents/whattoeat/WhatToEat/Support/Debug.xcconfig`

Secrets and local service-role credentials are stored in:

- `/Users/sarasarai/Documents/whattoeat/.env.local`

Do not copy local secrets into tracked docs or production config.

### Important xcconfig note

In Xcode `.xcconfig`, raw `http://...` values get truncated because `//` is parsed as a comment.

The correct debug value is written as:

```xcconfig
SUPABASE_URL = http:/$()/127.0.0.1:54321
```

That expands correctly to `http://127.0.0.1:54321` in the built app.

## Database design

### Current schema decisions

The local Supabase schema was adjusted to match the app's actual identifiers.

Key decision:

- `restaurants.id`, `restaurant_items.id`, and related item references use `text`
- This matches app IDs like `chipotle_chicken_bowl`
- We intentionally did not keep UUIDs for restaurant/item IDs because the app seed data is keyed by stable text identifiers

### Tables

#### `profiles`

- `user_id uuid primary key`
- `goal text`
- `calorie_target_default integer`
- `protein_target_default integer`
- `diet_flags text[]`
- `disliked_foods text[]`
- `created_at timestamptz`

#### `restaurants`

- `id text primary key`
- `name text unique`
- `region text`
- `active boolean`

#### `restaurant_items`

- `id text primary key`
- `restaurant_id text references restaurants(id)`
- `name text`
- `category text`
- `serving_description text`
- `calories integer`
- `protein integer`
- `carbs integer`
- `fat integer`
- `sodium_nullable integer`
- `source_version text`
- `source_url text`
- `contexts text[]`
- `tags text[]`
- `popularity_prior numeric`
- `active boolean`

#### `item_modifications`

- `id text primary key`
- `restaurant_item_id text references restaurant_items(id)`
- `modification_name text`
- `calorie_delta integer`
- `protein_delta integer`
- `carbs_delta integer`
- `fat_delta integer`

#### `queries`

- `id uuid primary key`
- `user_id uuid`
- `target_calories integer`
- `target_protein integer`
- `target_carbs_nullable integer`
- `target_fat_nullable integer`
- `context text`
- `top_result_name text`
- `created_at timestamptz`

#### `recommendations_served`

- `id uuid primary key`
- `query_id uuid references queries(id)`
- `restaurant_item_id text references restaurant_items(id)`
- `final_score numeric`
- `explanation_short text`
- `rank_position integer`

#### `favorites`

- `user_id uuid`
- `restaurant_item_id text references restaurant_items(id)`
- `created_at timestamptz`
- composite primary key: `(user_id, restaurant_item_id)`

#### `feedback`

- `id uuid primary key`
- `user_id uuid`
- `recommendation_id uuid nullable references recommendations_served(id)`
- `restaurant_item_id text references restaurant_items(id)`
- `sentiment text`
- `reason text`
- `created_at timestamptz`

#### `entitlements`

- `user_id uuid primary key`
- `subscription_status text`
- `plan_name text`
- `provider_customer_id text`
- `updated_at timestamptz`

### RLS and policies

RLS is enabled on user-owned tables:

- `profiles`
- `queries`
- `recommendations_served`
- `favorites`
- `feedback`
- `entitlements`

Policies are scoped to `auth.uid() = user_id` where applicable.

### Seed data

Seed file:

- `/Users/sarasarai/Documents/whattoeat/supabase/seed.sql`

The seed is currently a minimal backend seed aligned with the app's text IDs.
The app still primarily uses the richer local JSON catalog:

- `/Users/sarasarai/Documents/whattoeat/WhatToEat/Resources/restaurant_seed.json`

## Supabase sync behavior

### What syncs today

On bootstrap:

- anonymous auth user is created or restored
- `profile` is fetched
- `favorites` are fetched
- `history` is fetched from `queries`
- `feedback` is fetched from `feedback`

When local backend state is empty:

- local favorites seed into Supabase
- local history seeds into Supabase
- local feedback seeds into Supabase

During normal app use:

- saving profile writes to `profiles`
- toggling favorites writes to `favorites`
- searches write to `queries`
- feedback writes to `feedback`

### What does not sync yet

- `recommendations_served`
- entitlements
- catalog
- full recommendation explanations or ranked result sets

## Recommendation engine

Location:

- `/Users/sarasarai/Documents/whattoeat/WhatToEat/Core/RecommendationEngine.swift`

Current behavior:

- deterministic scoring
- exact tolerance first
- expanded tolerance fallback if needed
- weighted scoring based on:
  - calorie fit
  - protein fit
  - context fit
  - favorites and feedback history
  - popularity prior
  - carbs/fat bonus for Plus users

Recommendation execution is still local in the app.

## Testing and verification

### Main test command

```bash
xcodebuild test -project WhatToEat.xcodeproj -scheme WhatToEat -destination 'platform=iOS Simulator,id=FD2F97EC-1502-4207-9339-07488BB2521C'
```

### Verified passing tests

- `RecommendationEngineTests`
- `SupabaseSyncIntegrationTests`

Latest verified result:

- `4 tests`
- `0 failures`

### What the integration test proves

The integration test verifies against local Supabase that:

- anonymous sign-in works
- profile save works
- favorites save works
- history save works
- feedback save works
- data can be read back successfully

### Latest confirmed persisted rows

Confirmed in local Postgres:

- `profiles` contains a user row
- `favorites` contains:
  - `chipotle_chicken_bowl`
  - `cfa_grilled_nuggets_12`
- `queries` contains:
  - `610 calories`
  - `46 protein`
  - `post-workout`
  - `Chicken Burrito Bowl`
- `feedback` contains:
  - `restaurant_item_id = chipotle_chicken_bowl`
  - `sentiment = positive`
  - `reason = good-pick`

## Known constraints and decisions

### Current monetization implementation

The pricing strategy is defined, but the actual purchase stack is still local/mock.

Intended launch pricing:

- `Plus monthly`: `$3.99`
- `Plus yearly`: `$29.99`

Currently:

- `LocalSubscriptionService` simulates free vs plus
- no real RevenueCat integration yet

### Current analytics and crash reporting

Currently mocked:

- `ConsoleAnalyticsService`
- `ConsoleCrashReporter`

Planned:

- PostHog or Firebase Analytics
- Sentry

### Backend recommendation path

There is a Supabase function scaffold:

- `/Users/sarasarai/Documents/whattoeat/supabase/functions/recommendations/index.ts`

But the app does not call it yet. Recommendations are still computed in Swift locally.

## Where the project stands now

This is no longer just a concept doc or static prototype.

Current maturity:

- real iOS MVP
- real local backend
- real anonymous auth
- real persistence for key user state
- real automated integration test against local Supabase

What it is not yet:

- production wired
- cloud deployed
- subscription-enabled
- analytics-instrumented
- TestFlight validated with real users

## Recommended next steps

### Highest-priority next step

Connect `recommendations_served` so feedback can attach to a concrete recommendation record,
not just a `restaurant_item_id`.

That will improve:

- product analytics
- future ranking feedback loops
- traceability

### After that

1. Decide whether the source of truth for restaurant catalog stays local JSON or moves to Supabase.
2. Integrate RevenueCat for real entitlements.
3. Integrate Sentry and analytics.
4. Add richer history UI and backend status/error states.
5. Ship internal TestFlight and validate whether the top 3 results are actually helpful in real life.

## Runbook

### Start local backend

```bash
cd /Users/sarasarai/Documents/whattoeat
npm run supabase:start
```

### Check backend status

```bash
npm run supabase:status
```

### Reset local database

```bash
npm run supabase:db:reset
```

### Generate Xcode project

```bash
/tmp/XcodeGen/.build/release/xcodegen generate
```

### Run tests

```bash
xcodebuild test -project WhatToEat.xcodeproj -scheme WhatToEat -destination 'platform=iOS Simulator,id=FD2F97EC-1502-4207-9339-07488BB2521C'
```

## Context notes for future work

- If local Supabase keys change, update:
  - `/Users/sarasarai/Documents/whattoeat/.env.local`
  - `/Users/sarasarai/Documents/whattoeat/WhatToEat/Support/Debug.xcconfig`
- If new test files are added, regenerate the Xcode project with XcodeGen.
- If Supabase local schema changes, run `npm run supabase:db:reset` to get a clean local state.
- The app intentionally keeps local persistence as fallback even when remote sync exists.
- Release config is intentionally blank right now because production Supabase is not configured yet.
