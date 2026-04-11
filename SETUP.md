# WhatToEat — Setup & Status

Last updated: 2026-04-11

## Quick start on a new machine

### Prerequisites

- **Xcode 16+** (Swift 6.0, iOS 17+ SDK)
- **Docker Desktop** (for local Supabase)
- **Node.js 18+** (for Supabase CLI and catalog sync script)
- **XcodeGen** — install once:
  ```bash
  git clone https://github.com/yonaskolb/XcodeGen.git /tmp/XcodeGen
  cd /tmp/XcodeGen && swift build -c release
  ```

### 1. Clone and install

```bash
git clone https://github.com/edwingadiel/whattoeat.git
cd whattoeat
npm install
```

### 2. Start local Supabase

Make sure Docker Desktop is running, then:

```bash
npm run supabase:start
```

First run pulls Docker images (~2-3 min). Once ready, it prints local credentials.

Check status anytime:

```bash
npm run supabase:status
```

The local Supabase runs at `http://127.0.0.1:54321`. The Studio dashboard is at `http://127.0.0.1:54323`.

### 3. Seed the database

```bash
npm run supabase:db:reset
```

This applies all migrations (`supabase/migrations/`) and runs `supabase/seed.sql` (generated from the catalog JSON).

### 4. Generate the Xcode project

```bash
/tmp/XcodeGen/.build/release/xcodegen generate
```

This reads `project.yml` and produces `WhatToEat.xcodeproj`.

### 5. Build and run

Open `WhatToEat.xcodeproj` in Xcode, select an iOS 17+ simulator, and run.

The app connects to local Supabase automatically via the keys in `Debug.xcconfig`.

### 6. Run tests

```bash
npm run test:ios
```

Or use Cmd+U in Xcode. All 9 unit tests should pass.

---

## Supabase local architecture

| Component | Port | Purpose |
|-----------|------|---------|
| API (PostgREST) | 54321 | REST API for the app |
| Studio | 54323 | Web-based DB admin UI |
| Database (Postgres) | 54322 | The actual database |
| Auth (GoTrue) | 54321/auth | Authentication service |

### Key files

| File | Purpose |
|------|---------|
| `supabase/config.toml` | Local Supabase configuration |
| `supabase/migrations/20260408185500_init.sql` | Schema: tables, indexes, RLS policies |
| `supabase/seed.sql` | Seed data (auto-generated — do not edit directly) |
| `supabase/schema.sql` | Reference schema for documentation |
| `supabase/functions/recommendations/index.ts` | Edge function scaffold (not yet active) |
| `supabase/functions/shared/scoring.ts` | Scoring logic mirror (not yet active) |

### Catalog sync (single source of truth)

The restaurant catalog lives in `WhatToEat/Resources/restaurant_seed.json`. To regenerate the Supabase seed SQL after editing:

```bash
node scripts/sync_catalog.js
```

This writes `supabase/seed.sql`. Then reset the local DB to apply:

```bash
npm run supabase:db:reset
```

Preview without writing:

```bash
node scripts/sync_catalog.js --dry-run
```

---

## API keys needed

All SDKs are wired with auto-detection: if a key is present, the real service activates. If blank, a local fallback runs instead. The app builds and runs fine without any of these.

### Current key status

| Key | `Debug.xcconfig` | `Release.xcconfig` | What it does |
|-----|-------------------|---------------------|--------------|
| `SUPABASE_URL` | `http://127.0.0.1:54321` | BLANK | Supabase API endpoint |
| `SUPABASE_ANON_KEY` | Set (local key) | BLANK | Supabase anonymous auth key |
| `REVENUECAT_API_KEY` | BLANK | BLANK | In-app subscriptions (paywall) |
| `POSTHOG_API_KEY` | BLANK | BLANK | Product analytics |
| `POSTHOG_HOST` | BLANK | BLANK | PostHog host (optional, defaults to cloud) |
| `SENTRY_DSN` | BLANK | BLANK | Crash reporting |

### How to get each key

**RevenueCat** (free to start)
1. Sign up at [app.revenuecat.com](https://app.revenuecat.com)
2. Create a new project → add an iOS app
3. Copy the public API key
4. Paste into `REVENUECAT_API_KEY` in your xcconfig

**PostHog** (free, 1M events/month)
1. Sign up at [app.posthog.com](https://app.posthog.com)
2. Create a new project
3. Copy the project API key and host URL
4. Paste into `POSTHOG_API_KEY` and `POSTHOG_HOST`

**Sentry** (free, 5K errors/month)
1. Sign up at [sentry.io](https://sentry.io)
2. Create a new iOS project (Cocoa SDK)
3. Copy the DSN string
4. Paste into `SENTRY_DSN`

**Production Supabase** (when ready for release)
1. Create a project at [supabase.com](https://supabase.com)
2. Copy the project URL and anon key
3. Paste into `Release.xcconfig`
4. Run `supabase db push` to apply migrations to the cloud DB

### Where the keys go

The xcconfig files are at:
- `WhatToEat/Support/Debug.xcconfig` — local development
- `WhatToEat/Support/Release.xcconfig` — production builds

---

## What's next

### Immediate (before TestFlight)

1. **Get API keys** — sign up for RevenueCat, PostHog, Sentry (all free). Plug them into `Debug.xcconfig` and verify each lights up in the app's Integration Dashboard (Profile → scroll down).

2. **Production Supabase** — create a cloud project, wire `Release.xcconfig`, run `supabase db push` to deploy the schema, verify auth + RLS in hosted mode.

3. **Product validation** — test realistic queries on device. Verify recommendations feel useful, modification deltas match official nutrition data, and explanations are trustworthy.

4. **TestFlight** — ship an internal build once keys are in place.

### Future features (post-launch)

- **Query count sync** — move daily search limit from local UserDefaults to backend for reliable enforcement
- **Server-side recommendations** — port scoring logic to Supabase edge function (scaffold exists at `supabase/functions/recommendations/`)
- **Pantry mode** — "what can I make at home" with household inventory
- **More chains** — expand beyond current 6 restaurants / 24 items
- **Android** (Phase 3)
