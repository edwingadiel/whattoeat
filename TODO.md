# WhatToEat TODO

Last updated: 2026-04-09

## Completed

### Connect `recommendations_served` (P0 — DONE)

- Served recommendations persisted for each search
- Feedback links to `recommendation_id` when available
- Supabase sync wired for `recommendations_served` table
- RLS insert policy added so authenticated users can write served rows for their own queries

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

### Scenario-based context tags (P2 — DONE)

- Added new `MealContext` cases: `driveThru`, `cheap`, `noCook`, `mealPrep`, `latenight`
- Each context has a dedicated SF Symbol icon (`car.fill`, `dollarsign.circle.fill`, etc.)
- HomeView "Scenario" picker uses `ContextPillButton` with icon + label
- All 24 catalog items tagged with appropriate scenario contexts in `restaurant_seed.json`
- Recommendation engine scoring rewards items matching the requested scenario
- Context-specific explanations ("Cheap and filling", "Lights-out fuel", "Bulk-friendly meal prep", etc.)

### Enhanced recommendation scoring (P2 — DONE)

- Composite weights now: 35% calorie match, 30% protein match, 10% context fit, 10% preferences, 5% popularity, 5% protein density, 5% satiety, plus secondary macro bonuses
- `proteinDensityBonus` rewards items with high protein-per-calorie (target ≥0.08g/cal)
- `satietyBonus` favors items with high protein, moderate fat, and low refined carbs
- Feedback weighting: `wouldNotEat` heavily penalizes; `goodPick` boosts
- Disliked-foods filter substring-matches item names against profile dislikes
- Vegetarian/vegan/glutenAware diet flags filter out incompatible items
- 9 unit tests cover scoring, filtering, feedback weighting, favorites boost, expanded tolerance, and empty results

### Fast food intelligence — modification suggestions (P2 — DONE)

- `RecommendationDetailView` rewritten with interactive "Make it better" section
- Each modification (e.g., "Sub brown rice", "No mayo", "Grilled instead of crispy") displays its delta on cal/protein/carbs/fat
- Tap a modification to toggle it; nutrition card switches to "Modified nutrition" with live macro updates
- Reset button clears all selections
- Protein density badge shown on items with ≥0.07 g/cal ("HIGH PROTEIN DENSITY")

### Catalog source-of-truth pipeline (P1 — DONE)

- `scripts/sync_catalog.js` generates Supabase seed SQL from `WhatToEat/Resources/restaurant_seed.json`
- `restaurant_seed.json` is now the single source of truth
- Script supports `--dry-run` (stdout) and `--output <path>` (custom file)
- Default output: `supabase/seed.sql`
- Run with `node scripts/sync_catalog.js` whenever the catalog changes

### Sync coordinator extraction (P2 — DONE)

- New `WhatToEat/Core/SyncCoordinator.swift` owns all remote sync orchestration
- `AppStore` no longer holds private sync* methods — delegates to `syncCoordinator`
- Coordinator surfaces `bootstrap`, `syncProfile`, `syncFavorites`, `syncHistoryEntry`, `syncFeedbackEntry`, `syncServedRecommendations`, `seedRemoteStateIfNeeded`
- `remoteSyncEnabled` is now a computed property reading from the coordinator
- AppStore is significantly slimmer and easier to test

### Bug fixes (DONE)

- `AppTheme.Color(hex:)` no longer uses deprecated `Scanner.scanHexInt64`
- Removed dead `purchase()` and `restore()` methods from `ProfileViewModel`
- `recommendations_served` had only a SELECT policy — added `recommendations_insert_own`
- Integration test was creating a feedback entry but never persisting it before assertions — fixed

## Remaining

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
