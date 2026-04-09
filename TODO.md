# WhatToEat TODO

Last updated: 2026-04-09

## Completed

### Connect `recommendations_served` (P0 — DONE)

- Served recommendations persisted for each search
- Feedback links to `recommendation_id` when available
- Supabase sync wired for `recommendations_served` table

### RevenueCat integration (P1 — DONE)

- RevenueCat SDK added and wired
- `RevenueCatSubscriptionService` implements `SubscriptionProviding`
- Paywall with monthly ($3.99) and annual ($29.99) pricing cards
- Restore purchases flow working
- Auto-selects real service when `REVENUECAT_API_KEY` is set, falls back to local mock

### Analytics integration (P1 — DONE)

- PostHog SDK added and wired via `PostHogAnalyticsService`
- Tracks: onboarding_completed, query_submitted, recommendations_viewed, recommendation_opened, favorite_added, feedback_submitted, paywall_viewed, subscription_started, subscription_restored
- User identification on bootstrap
- Auto-selects when `POSTHOG_API_KEY` is set, falls back to console

### Sentry integration (P1 — DONE)

- Sentry SDK added and wired via `SentryCrashReporter`
- Captures errors with breadcrumbs and user context
- Auto-selects when `SENTRY_DSN` is set, falls back to console

### Improve profile/history UX (P2 — DONE)

- Relative timestamps (just now, Xm ago, Xh ago, yesterday, Xd ago)
- Tap history entry to re-run that query (navigates to HomeView with prefilled values)
- Color-coded query stats (calories in accent, protein in teal)
- History count indicator for free users (showing X of Y)
- Unlock full history upsell for free users

### Improve network failure handling (P2 — DONE)

- Sync status banner in ProfileView (synced vs local-only with cloud icon)
- Integration dashboard (2x2 grid showing Supabase, PostHog, Sentry, RevenueCat status)
- Clear visual indicators for connected vs not-configured services

### Add search count indicator (P2 — DONE)

- Free users see "X searches left today" under the search CTA
- Usage gauge in ProfileView showing searches used/5 and favorites saved/5
- Warning state when limit is reached
- Progress bar visualization

### Improve empty states (P2 — DONE)

- ResultsView: icon + helpful suggestions when no matches found
- FavoritesView: centered icon with contextual guidance
- ProfileView history: search icon with "no searches yet" message

### Polish animations (P2 — DONE)

- Staggered card entrance animations on ResultsView (spring with delay per card)
- Fade + slide transitions for recommendation cards

## Remaining

### Decide catalog source of truth (P1)

Open question:

- Should the restaurant catalog stay local JSON for MVP simplicity?
- Or move to Supabase for centralized updates?

Recommended short-term path:

- Keep local JSON for app recommendations
- Build a script or pipeline to generate Supabase seed from the same source

Tasks:

- Document one source of truth
- Remove duplicated divergence risk between JSON and SQL seed
- Decide whether app reads catalog locally, remotely, or hybrid

### Add query count sync strategy (P2)

Current issue:

- Free-tier daily query limit is tracked locally in `UserDefaults`

Tasks:

- Decide whether this should remain local for MVP
- Or move to backend-backed counting for more reliable enforcement

### Move recommendation execution server-side (P3)

Current state:

- Recommendation engine runs in Swift locally
- Supabase function exists as scaffold only

Tasks:

- Port scoring logic cleanly to backend
- Compare backend results vs current local engine
- Decide whether app should fully switch or stay hybrid

### Add production Supabase environment (P3)

Tasks:

- Create cloud project when ready
- Wire Release config
- Move secrets and keys to proper environment management
- Verify auth and RLS behavior in hosted environment

### TestFlight internal release (P3)

Questions to validate:

- Do users understand the home screen quickly?
- Do top 3 recommendations feel useful?
- Does anyone save favorites naturally?
- Would users pay at the current price?

## Product validation tasks

### Validate recommendation usefulness

- Test realistic calorie/protein targets
- Test edge cases with few or no matches
- Verify explanations feel trustworthy
- Verify suggestions feel like real meals

### Validate data quality

- Re-check nutrition values against official sources
- Validate modification deltas
- Remove stale or suspicious items

## Code quality tasks

### Add more integration coverage

Useful future tests:

- Bootstrapping remote history into a fresh local store
- Seeding local history into empty remote state
- Query persistence order
- Feedback merge behavior
- Favorites replacement after toggle/remove cycles

### Refactor sync boundaries if needed

Current state:

- `AppStore` owns a lot of orchestration

Potential improvement:

- Extract a dedicated sync coordinator if remote logic grows further

## Nice-to-have later

### Pantry mode (Phase 2)

Only revisit after restaurant flow proves useful and retention justifies more scope.

### More chains

Only add more restaurants after existing chain data is stable and recommendation usefulness is validated.

## Setup keys still needed

All three SDKs are wired and auto-select based on key presence. Fill these in when ready:

| Key | Debug.xcconfig | Release.xcconfig |
|-----|---------------|-----------------|
| `SUPABASE_URL` | Set (localhost) | BLANK |
| `SUPABASE_ANON_KEY` | Set (local) | BLANK |
| `REVENUECAT_API_KEY` | BLANK | BLANK |
| `POSTHOG_API_KEY` | BLANK | BLANK |
| `POSTHOG_HOST` | BLANK (optional) | BLANK |
| `SENTRY_DSN` | BLANK | BLANK |
