# WhatToEat

WhatToEat is an iOS-first restaurant recommendation app for one job:

`I have X calories and need Y protein. What should I eat right now?`

This implementation ships a working SwiftUI MVP with:

- onboarding and profile capture
- local curated restaurant catalog for 6 chains
- deterministic recommendation engine
- favorites, search history, and lightweight feedback
- free vs plus gating
- a production-minded scaffold for Supabase-backed deployment

## Current shape

The iOS app runs fully offline with local seed data so the core loop works immediately.
Production integration points are abstracted behind services so Supabase, RevenueCat,
Sentry, and analytics can be wired without rewriting the UI.

## Project structure

- `WhatToEat/`: SwiftUI application
- `WhatToEatTests/`: recommendation engine tests
- `supabase/`: schema and edge-function scaffold for production rollout

## Generate the Xcode project

This repo uses XcodeGen. In this workspace, it was built locally at:

`/tmp/XcodeGen/.build/release/xcodegen`

Generate the project with:

```bash
/tmp/XcodeGen/.build/release/xcodegen generate
```

Then open `WhatToEat.xcodeproj` in Xcode.

## Local Supabase setup

This repo is now prepared for local Supabase development with the CLI.

### Prerequisites

- Node.js 20+
- Docker Desktop, OrbStack, or another Docker-compatible daemon

### Install and start

The CLI is already added as a dev dependency. From the repo root:

```bash
npm run supabase:start
```

Current blocker on this machine:

`Cannot connect to the Docker daemon at unix:///var/run/docker.sock`

That means the repo is ready, but Docker still needs to be installed and running.

### Useful commands

```bash
npm run supabase:status
npm run supabase:db:reset
npm run supabase:functions:serve
```

### Local config files

- `supabase/config.toml`
- `supabase/migrations/20260408185500_init.sql`
- `supabase/seed.sql`
- `.env.local.example`
- `WhatToEat/Support/Debug.xcconfig`
- `WhatToEat/Support/Release.xcconfig`

After `npm run supabase:start`, run `npm run supabase:status` and copy the local keys into `.env.local`.

For the iOS app, also paste the local anon key into:

`WhatToEat/Support/Debug.xcconfig`

The app now reads `SUPABASE_URL` and `SUPABASE_ANON_KEY` from build settings via `Info.plist`, signs in anonymously against Supabase when configured, and starts syncing `profiles` and `favorites` remotely while keeping local fallback behavior.

## Production integrations to wire next

- Expand Supabase sync from `profiles` and `favorites` to full query/recommendation history
- Replace `LocalSubscriptionService` with RevenueCat entitlements
- Replace `ConsoleAnalyticsService` with PostHog or Firebase Analytics
- Replace `ConsoleCrashReporter` with Sentry
- Move local search/history persistence to Supabase tables from `supabase/schema.sql`
