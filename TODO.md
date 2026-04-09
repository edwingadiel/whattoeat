# WhatToEat TODO

Last updated: 2026-04-08

## Priority 0

### Connect `recommendations_served`

Why:

- feedback should attach to a concrete recommendation record
- this unlocks better ranking and analytics later

Tasks:

- persist recommendation results for each search
- write `query_id`, `restaurant_item_id`, `final_score`, `explanation_short`, `rank_position`
- update feedback flow to pass `recommendation_id` when available
- keep `restaurant_item_id` as a fallback for simple UI feedback

Files likely involved:

- [AppStore.swift](/Users/sarasarai/Documents/whattoeat/WhatToEat/Core/AppStore.swift)
- [SupabaseSyncService.swift](/Users/sarasarai/Documents/whattoeat/WhatToEat/Core/SupabaseSyncService.swift)
- [RecommendationDetailView.swift](/Users/sarasarai/Documents/whattoeat/WhatToEat/Views/RecommendationDetailView.swift)
- [20260408185500_init.sql](/Users/sarasarai/Documents/whattoeat/supabase/migrations/20260408185500_init.sql)

## Priority 1

### Decide catalog source of truth

Open question:

- should the restaurant catalog stay local JSON for MVP simplicity
- or move to Supabase for centralized updates

Recommended short-term path:

- keep local JSON for app recommendations
- build a script or pipeline to generate Supabase seed from the same source

Tasks:

- document one source of truth
- remove duplicated divergence risk between JSON and SQL seed
- decide whether app reads catalog locally, remotely, or hybrid

### RevenueCat integration

Why:

- current `Plus` state is mocked
- need real entitlements before TestFlight validation of pricing

Tasks:

- add RevenueCat SDK
- replace `LocalSubscriptionService`
- map entitlement to `UserEntitlement`
- support restore purchases
- confirm paywall gating still works cleanly

### Analytics integration

Why:

- need visibility into activation and conversion

Track at minimum:

- onboarding completed
- query submitted
- recommendations viewed
- recommendation opened
- favorite added
- feedback submitted
- paywall viewed
- subscription started
- subscription restored

Recommended providers:

- PostHog or Firebase Analytics

### Sentry integration

Why:

- app already has multiple async/network boundaries
- real crash/error visibility will matter once external testers use it

## Priority 2

### Improve profile/history UX

Current state:

- history is visible in the profile screen
- useful, but basic

Tasks:

- show timestamp formatting
- allow tapping a history item to re-run the query
- show backend sync state more clearly
- expose recent feedback history if useful

### Improve network failure handling

Tasks:

- add lightweight user-facing status when backend is unavailable
- avoid silent fallback where it could confuse users
- surface whether sync is local-only or remote-enabled

### Add query count sync strategy

Current issue:

- free-tier daily query limit is still tracked locally in `UserDefaults`

Tasks:

- decide whether this should remain local for MVP
- or move to backend-backed counting for more reliable enforcement

## Priority 3

### Move recommendation execution server-side

Current state:

- recommendation engine runs in Swift locally
- Supabase function exists as scaffold only

Why this matters later:

- shared business logic across clients
- more consistent analytics and recommendation auditing
- easier experimentation

Tasks:

- port scoring logic cleanly to backend
- compare backend results vs current local engine
- decide whether app should fully switch or stay hybrid

### Add production Supabase environment

Tasks:

- create cloud project when ready
- wire Release config
- move secrets and keys to proper environment management
- verify auth and RLS behavior in hosted environment

### TestFlight internal release

Why:

- need product validation, not just technical validation

Questions to validate:

- do users understand the home screen quickly
- do top 3 recommendations feel useful
- does anyone save favorites naturally
- would users pay at the current price

## Product validation tasks

### Validate recommendation usefulness

Tasks:

- test realistic calorie/protein targets
- test edge cases with few or no matches
- verify explanations feel trustworthy
- verify suggestions feel like real meals, not “technically correct” but weird picks

### Validate data quality

Tasks:

- re-check nutrition values against official sources
- validate modification deltas
- remove stale or suspicious items
- document data review cadence

## Code quality tasks

### Add more integration coverage

Useful future tests:

- bootstrapping remote history into a fresh local store
- seeding local history into empty remote state
- query persistence order
- feedback merge behavior
- favorites replacement after toggle/remove cycles

### Refactor sync boundaries if needed

Current state:

- `AppStore` owns a lot of orchestration

Potential improvement:

- extract a dedicated sync coordinator if remote logic grows further

## Nice-to-have later

### Pantry mode

Deferred by design.

Only revisit after:

- restaurant flow proves useful
- retention justifies more scope

### More chains

Only add more restaurants after:

- existing chain data is stable
- recommendation usefulness is validated
- retention shows the app is worth expanding

## Suggested execution order

1. `recommendations_served`
2. RevenueCat
3. analytics + Sentry
4. catalog source-of-truth cleanup
5. TestFlight internal release
6. recommendation backend migration if needed
