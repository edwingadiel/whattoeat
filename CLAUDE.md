# CLAUDE.md

Guidance for Claude Code sessions working in this repository. Read this
before touching anything non-trivial — there are decisions encoded here
that aren't obvious from reading the code.

## Product

**WhatToEat** is an iOS-first restaurant recommendation app answering a
single, narrow question: *"I have X calories and need Y protein. What
should I eat right now?"*. The recommendation engine returns three top
picks and a few alternates from a curated multi-chain catalog, filtered
by meal context (breakfast, post-workout, drive-thru, etc.), dietary
flags, and disliked foods.

Monetization is freemium: free tier = 5 searches/day + 5 saved meals +
calorie & protein targeting. Plus = unlimited + carbs/fat targeting.

## Stack at a glance

- **iOS app:** SwiftUI, Swift 6.0, iOS 17+, generated via XcodeGen
  (`project.yml`). Main targets: `WhatToEat` (app) and `WhatToEatTests`.
- **Backend:** Supabase (Postgres, anonymous auth, RLS). Local dev via
  `supabase/config.toml`. Schema lives in `supabase/migrations/`.
- **Third-party SDKs:** RevenueCat (subscriptions), PostHog (analytics),
  Sentry (crash reporting). All pluggable via protocols — see
  `AppServices.swift`.
- **Catalog:** Bundled JSON at `WhatToEat/Resources/restaurant_seed.json`
  is the single source of truth. `scripts/sync_catalog.js` generates
  `supabase/seed.sql` from it.

## Architecture

Follow the existing layering — don't invent new patterns unless a clear
reason forces you to:

```
Views/           SwiftUI screens. One @StateObject view model per screen.
ViewModels/      Screen-scoped state + validation. @MainActor.
Core/
  AppStore       The single @MainActor ObservableObject. All shared state
                 lives here. Views observe it directly.
  AppServices    Dependency injection: AppEnvironment wires real or mock
                 services at app launch. Tests construct mock environments.
  RecommendationEngine   Pure function-of-inputs scoring. No I/O, no
                 async, deterministic — so it's unit-testable.
  SupabaseSyncService    Actor conforming to RemoteUserSyncing. Never
                 touch MainActor state from here.
  SyncCoordinator        Orchestrates sync. Background Tasks, fire-and-
                 forget with crash-reporter error capture.
  LocalPersistenceStore  UserDefaults-backed offline cache. First-class,
                 not a fallback: the app starts with local data and
                 reconciles with remote in `AppStore.bootstrap()`.
Models/AppModels.swift   All shared data types. Codable + Sendable.
Components/              Reusable SwiftUI pieces (PillButton, MetricChip,
                 RecommendationCard, OfflineBanner, etc).
```

### Data flow is one-way

`View → ViewModel (for input) → AppStore (mutations) → @Published → View`.
Views don't call sync code directly. ViewModels don't hold remote state.
AppStore is the single owner of domain state.

### Local-first with reconciliation

On launch the app shows local state immediately. `AppStore.bootstrap()`
then fetches a `RemoteBootstrapSnapshot`, merges by id/timestamp, and
saves back. If the network is unavailable the app stays fully functional
— `SyncStatus` goes to `.offline` and the `OfflineBanner` surfaces a
retry. Never assume the network is reachable.

### Row-level security

Every user-owned table (`profiles`, `queries`, `favorites`, `feedback`,
`entitlements`, `recommendations_served`) has `auth.uid() = user_id`
policies. Catalog tables (`restaurants`, `restaurant_items`,
`item_modifications`, `catalog_meta`) are publicly readable. If you add
a new table that holds user data, enable RLS and add the policy in the
same migration.

## Commands

```bash
# Generate Xcode project from project.yml
xcodegen generate

# Regenerate Supabase seed SQL from the JSON catalog (validates as part
# of this — will fail on macro math drift, duplicate IDs, tag conflicts)
node scripts/sync_catalog.js

# Run the local Supabase stack (needs Docker)
supabase start

# Apply migrations locally
supabase db reset

# Run tests (replace the simulator UDID as needed)
xcodebuild test -project WhatToEat.xcodeproj -scheme WhatToEat \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Things that will bite you

- **Catalog IDs are `text`, not UUID.** They match the JSON seed
  (e.g. `chipotle_chicken_bowl`). The local engine and remote tables
  must agree on these strings exactly.
- **Free-tier limits are enforced server-side too.** See migration
  `20260412120000_rate_limit.sql`. The client check is for UX; the
  trigger is the authority. Don't rip out the triggers thinking they're
  redundant.
- **`sourceVersion` is per-item but effectively global.** The current
  catalog refresh flow uses the first item's `sourceVersion` as the
  bundled-catalog signal. If you ever allow per-item versions to drift,
  revisit `AppStore.bundledCatalogVersion`.
- **Paywall reason matters.** `PaywallReason` is more than a label —
  analytics and in-app copy depend on which reason triggered the wall.
  Always use the narrowest reason (e.g. `.dailySearchLimit` not
  `.advancedMacros`) when opening the paywall.
- **RevenueCat/PostHog/Sentry services may be "disabled" stubs.**
  Check `store.remoteSyncEnabled` / `analyticsEnabled` / etc. before
  assuming a third-party is active. Release builds without keys still
  run — they just use no-op services.
- **`RestaurantCatalog.fallback` is the nuclear backup.** If the
  bundled JSON fails to decode, the app shows a one-item Chipotle-only
  catalog rather than crashing. Keep it valid.

## Conventions

- **Colors:** use `AppTheme.*` tokens. Don't hardcode `Color.white` or
  hex values in views — `AppTheme` provides adaptive light/dark colors
  via `Color.adaptive(light:dark:)`. Brand colors (accent, teal, gold)
  stay constant across modes.
- **Accessibility:** every interactive control gets
  `.accessibilityLabel` and `.accessibilityHint` where helpful; group
  data-heavy cards with `.accessibilityElement(children: .combine)`;
  headings get `.accessibilityAddTraits(.isHeader)`.
- **Validation:** user input passes through view-model validation
  before reaching the store. See `HomeViewModel.validate()` for the
  pattern — inline error strings on the view model, rendered by
  `LabeledTextField(validationError:)`.
- **Error handling at the edges:** view models expose user-facing
  error state (`searchError`, `calorieError`). Actors and sync code
  capture errors to the crash reporter but don't throw up to views;
  they surface failures via `AppStore.syncStatus`.
- **Analytics:** every meaningful user action fires a PostHog event
  from `AppStore`, not from views. Event names are snake_case
  (`query_submitted`, `paywall_viewed`, `favorite_added`).
- **Commits:** descriptive imperative subject line, body explains the
  *why*. Include trailing `https://claude.ai/code/...` session link
  when the work was Claude-assisted.

## When adding features

1. Add the type to `AppModels.swift` (Codable + Sendable).
2. If persisted locally, extend `LocalPersistenceStore`.
3. If synced remotely, extend `RemoteUserSyncing` (with a default
   implementation to keep existing conformers compiling) and the
   `SupabaseSyncService` actor. Add a Supabase migration.
4. Wire the mutation through `AppStore` — view models don't mutate
   remote state directly.
5. Add a `RecommendationEngineTests` case if the feature affects
   ranking. Unit tests use constructed catalogs, not the bundled JSON.
6. For UI changes, add accessibility and check both light + dark mode.

## Catalog changes

Edit `WhatToEat/Resources/restaurant_seed.json`, then run
`node scripts/sync_catalog.js`. The script validates macro math, tag
coherency, and referential integrity before regenerating
`supabase/seed.sql`. Bump `catalog_meta.current_version` in the next
migration when publishing a new catalog snapshot — clients detect the
version change via `catalog_version()` RPC and can surface a refresh
affordance.

## What not to do

- Don't put secrets in `Debug.xcconfig` / `Release.xcconfig` that
  should come from `.env.local` or the CI keychain.
- Don't bypass `SyncCoordinator` to talk to Supabase from views or
  view models. The coordinator centralizes error capture and
  enabled-state checks.
- Don't add client-only paywall gates without a corresponding
  server-side check in `enforce_*_quota` triggers. The client is UX;
  the server is truth.
- Don't add new third-party SDKs without a protocol abstraction in
  `AppServices`. We want to be able to swap in mock implementations
  for tests and release builds without keys.
