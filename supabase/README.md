# Supabase Scaffold

This folder captures the production-facing backend shape for WhatToEat.

## Included

- `schema.sql`: core tables, indexes, and RLS starter policies
- `migrations/20260408185500_init.sql`: local/remote migration source of truth
- `seed.sql`: local development seed data
- `functions/recommendations/index.ts`: edge-function entrypoint
- `functions/shared/scoring.ts`: deterministic recommendation logic mirror

## Notes

The iOS app currently runs with local seed data so the core loop works immediately.
When moving to production:

1. Apply `schema.sql`
2. Load the curated chain data into `restaurants`, `restaurant_items`, and `item_modifications`
3. Swap the client repository from local JSON to the Supabase endpoint
4. Replace local purchase state with RevenueCat entitlement sync

## Local development

Run from the repo root:

```bash
npm run supabase:start
npm run supabase:status
```

If Docker is not running, the CLI will fail before services boot.
