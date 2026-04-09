#!/usr/bin/env node

/**
 * sync_catalog.js
 *
 * Generates Supabase seed SQL from the local restaurant_seed.json file.
 * This is the single source of truth for the catalog — the JSON file lives
 * in the iOS app bundle and this script produces the SQL that seeds Supabase.
 *
 * Usage:
 *   node scripts/sync_catalog.js                     # writes to supabase/seed.sql
 *   node scripts/sync_catalog.js --output /tmp/out.sql
 *   node scripts/sync_catalog.js --dry-run            # prints to stdout
 */

const fs = require("fs");
const path = require("path");

const SEED_JSON = path.resolve(
  __dirname,
  "../WhatToEat/Resources/restaurant_seed.json"
);

const DEFAULT_OUTPUT = path.resolve(__dirname, "../supabase/seed.sql");

function escapeSQL(str) {
  return str.replace(/'/g, "''");
}

function pgArray(arr) {
  if (!arr || arr.length === 0) return "'{}'";
  return `array[${arr.map((v) => `'${escapeSQL(v)}'`).join(", ")}]`;
}

function generateSQL(catalog) {
  const lines = [];

  // Restaurants
  lines.push("insert into restaurants (id, name, region, active)");
  lines.push("values");
  const restaurantRows = catalog.restaurants.map(
    (r) =>
      `  ('${escapeSQL(r.id)}', '${escapeSQL(r.name)}', '${escapeSQL(r.region)}', ${r.active})`
  );
  lines.push(restaurantRows.join(",\n"));
  lines.push("on conflict (id) do update set");
  lines.push("  name = excluded.name,");
  lines.push("  region = excluded.region,");
  lines.push("  active = excluded.active;");
  lines.push("");

  // Restaurant items
  lines.push("insert into restaurant_items (");
  lines.push(
    "  id, restaurant_id, name, category, serving_description,"
  );
  lines.push(
    "  calories, protein, carbs, fat, sodium_nullable,"
  );
  lines.push(
    "  source_version, source_url, contexts, tags, popularity_prior, active"
  );
  lines.push(")");
  lines.push("values");

  const itemRows = catalog.items.map((item) => {
    const sodium = item.sodium !== null && item.sodium !== undefined ? item.sodium : "null";
    return [
      "  (",
      `    '${escapeSQL(item.id)}',`,
      `    '${escapeSQL(item.restaurantID)}',`,
      `    '${escapeSQL(item.name)}',`,
      `    '${escapeSQL(item.category)}',`,
      `    '${escapeSQL(item.servingDescription)}',`,
      `    ${item.calories},`,
      `    ${item.protein},`,
      `    ${item.carbs},`,
      `    ${item.fat},`,
      `    ${sodium},`,
      `    '${escapeSQL(item.sourceVersion)}',`,
      `    '${escapeSQL(item.sourceURL)}',`,
      `    ${pgArray(item.contexts)},`,
      `    ${pgArray(item.tags)},`,
      `    ${item.popularityPrior},`,
      `    ${item.active}`,
      "  )",
    ].join("\n");
  });

  lines.push(itemRows.join(",\n"));
  lines.push("on conflict (id) do update set");
  lines.push("  restaurant_id = excluded.restaurant_id,");
  lines.push("  name = excluded.name,");
  lines.push("  category = excluded.category,");
  lines.push("  serving_description = excluded.serving_description,");
  lines.push("  calories = excluded.calories,");
  lines.push("  protein = excluded.protein,");
  lines.push("  carbs = excluded.carbs,");
  lines.push("  fat = excluded.fat,");
  lines.push("  sodium_nullable = excluded.sodium_nullable,");
  lines.push("  source_version = excluded.source_version,");
  lines.push("  source_url = excluded.source_url,");
  lines.push("  contexts = excluded.contexts,");
  lines.push("  tags = excluded.tags,");
  lines.push("  popularity_prior = excluded.popularity_prior,");
  lines.push("  active = excluded.active;");
  lines.push("");

  // Item modifications
  const allMods = catalog.items.flatMap((item) =>
    item.modifications.map((mod) => ({ ...mod, restaurantItemID: item.id }))
  );

  if (allMods.length > 0) {
    lines.push("insert into item_modifications (");
    lines.push(
      "  id, restaurant_item_id, modification_name,"
    );
    lines.push("  calorie_delta, protein_delta, carbs_delta, fat_delta");
    lines.push(")");
    lines.push("values");

    const modRows = allMods.map(
      (mod) =>
        [
          "  (",
          `    '${escapeSQL(mod.id)}',`,
          `    '${escapeSQL(mod.restaurantItemID)}',`,
          `    '${escapeSQL(mod.modificationName)}',`,
          `    ${mod.calorieDelta},`,
          `    ${mod.proteinDelta},`,
          `    ${mod.carbsDelta},`,
          `    ${mod.fatDelta}`,
          "  )",
        ].join("\n")
    );

    lines.push(modRows.join(",\n"));
    lines.push("on conflict (id) do update set");
    lines.push("  restaurant_item_id = excluded.restaurant_item_id,");
    lines.push("  modification_name = excluded.modification_name,");
    lines.push("  calorie_delta = excluded.calorie_delta,");
    lines.push("  protein_delta = excluded.protein_delta,");
    lines.push("  carbs_delta = excluded.carbs_delta,");
    lines.push("  fat_delta = excluded.fat_delta;");
  }

  return lines.join("\n") + "\n";
}

function main() {
  const args = process.argv.slice(2);
  const dryRun = args.includes("--dry-run");
  const outputIndex = args.indexOf("--output");
  const outputPath =
    outputIndex >= 0 && args[outputIndex + 1]
      ? args[outputIndex + 1]
      : DEFAULT_OUTPUT;

  const raw = fs.readFileSync(SEED_JSON, "utf-8");
  const catalog = JSON.parse(raw);

  console.log(
    `[sync_catalog] Loaded ${catalog.restaurants.length} restaurants, ${catalog.items.length} items`
  );

  const sql = generateSQL(catalog);

  if (dryRun) {
    process.stdout.write(sql);
  } else {
    fs.writeFileSync(outputPath, sql, "utf-8");
    console.log(`[sync_catalog] Written to ${outputPath}`);
  }
}

main();
