# WhatToEat Handoff

## What this is

WhatToEat is an iOS-first app that answers:

`I have X calories and need Y protein. What should I eat right now?`

It is intentionally not a full calorie tracker.

## Current state

Working today:

- SwiftUI iOS MVP
- onboarding
- recommendation flow
- detail screen
- favorites
- history
- feedback
- local restaurant seed data
- local Supabase backend
- anonymous auth
- Supabase sync for:
  - profile
  - favorites
  - queries/history
  - feedback

Still mocked:

- RevenueCat
- analytics
- crash reporting
- production cloud backend

## Key files

Start here:

- [PROJECT_CONTEXT.md](/Users/sarasarai/Documents/whattoeat/PROJECT_CONTEXT.md)
- [AppStore.swift](/Users/sarasarai/Documents/whattoeat/WhatToEat/Core/AppStore.swift)
- [SupabaseSyncService.swift](/Users/sarasarai/Documents/whattoeat/WhatToEat/Core/SupabaseSyncService.swift)
- [RecommendationEngine.swift](/Users/sarasarai/Documents/whattoeat/WhatToEat/Core/RecommendationEngine.swift)
- [project.yml](/Users/sarasarai/Documents/whattoeat/project.yml)

Database:

- [20260408185500_init.sql](/Users/sarasarai/Documents/whattoeat/supabase/migrations/20260408185500_init.sql)
- [seed.sql](/Users/sarasarai/Documents/whattoeat/supabase/seed.sql)

Tests:

- [RecommendationEngineTests.swift](/Users/sarasarai/Documents/whattoeat/WhatToEatTests/RecommendationEngineTests.swift)
- [SupabaseSyncIntegrationTests.swift](/Users/sarasarai/Documents/whattoeat/WhatToEatTests/SupabaseSyncIntegrationTests.swift)

## Local setup

Docker is installed and working.

Supabase local commands:

```bash
cd /Users/sarasarai/Documents/whattoeat
npm run supabase:start
npm run supabase:status
npm run supabase:db:reset
```

Generate the Xcode project:

```bash
/tmp/XcodeGen/.build/release/xcodegen generate
```

Run tests:

```bash
xcodebuild test -project WhatToEat.xcodeproj -scheme WhatToEat -destination 'platform=iOS Simulator,id=FD2F97EC-1502-4207-9339-07488BB2521C'
```

## Important config

Local env files:

- [.env.local](/Users/sarasarai/Documents/whattoeat/.env.local)
- [Debug.xcconfig](/Users/sarasarai/Documents/whattoeat/WhatToEat/Support/Debug.xcconfig)

Important `.xcconfig` note:

- `http://...` must be written in escaped form there
- current value is already correct

## Verified working

Verified by automated test:

- anonymous sign-in
- profile persistence
- favorites persistence
- query/history persistence
- feedback persistence

Latest test status:

- `4 tests`
- `0 failures`

## Biggest next step

Implement `recommendations_served` properly and connect feedback to concrete recommendation records.

That is the cleanest next move because it improves:

- ranking feedback quality
- analytics
- traceability

## After that

1. Decide whether catalog remains local JSON or moves to Supabase.
2. Integrate RevenueCat.
3. Integrate analytics and Sentry.
4. Improve product polish and error states.
5. Ship internal TestFlight.
