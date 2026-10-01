# Migration squash — plan (NIJE IZVRŠEN, čeka staging verifikaciju)

> Status (2026-10-01): **plan dokumentovan, squash NIJE izvršen**.
> Razlog: Docker nije dostupan lokalno (`supabase start` ne radi bez
> Docker Desktop-a), pa baseline dump i `db reset` verifikacija nisu mogući
> bez staging Supabase projekta. Brisati migracije naslepo = rizik od
> `Remote migration versions not found in local` i divergencije prod šeme.

## Kontekst

- `supabase/migrations/`: 210 fajlova, ~15541 linija, ~670KB.
- Istorija je linearna (bez grananja), od `20260226100000_initial_schema.sql`
  do `20261001110000_scoped_item_conversations.sql`.
- Repo već dokumentuje proceduru u `docs/MIGRATIONS_SOLO.md` (§ Strategija
  konsolidacije) i `docs/STAGING_ENVIRONMENT.md` (§ 4 Supabase Staging baza).
- CI (`db-integration-checks`) radi `supabase start` + `db reset` + SQL testove
  + drift-check `database.types.ts` — to je kapija za squash.

## Predloženi koraci (redom, svaki se verifikuje pre sledećeg)

1. **Staging Supabase projekat** (po `docs/STAGING_ENVIRONMENT.md` § 4):
   `supabase link --project-ref <STAGING_REF>` → `supabase db push`
   (svih 210 migracija) → `UPDATE edge_config SET functions_base_url`.
2. **Baseline dump sa staging-a** (NE sa prod, da se ne optereti prod):
   `supabase db dump --linked --schema-only -f supabase/baseline_schema.sql`
   (očekivano ~600-700KB konsolidovanog DDL-a).
3. **Lokalna verifikacija** (zahteva Docker): `supabase db reset --local`
   sa samo baseline fajlom → svi SQL testovi iz `supabase/tests/` moraju proći
   → `npm run supabase:types:local` → diff `database.types.ts` mora biti prazan.
4. **Zamena**: `supabase/migrations/*.sql` → `supabase/migrations_archive/`,
   novi `supabase/migrations/20261002000000_baseline_schema.sql`.
5. **Repair istorije** na staging + prod (samo nakon § 2-3 zelenih):
   `supabase migration repair --status applied <svih 210 verzija>`.
6. **CI provera**: full `ci.yml` (flutter-checks + db-integration-checks) zelen
   na feature grani → merge u `staging` → smoke na staging URL-u →
   merge u `master`.

## Rollback

- `migrations_archive/` ostaje u gitu; povratak = `git revert` baseline commit-a.
- Nikada ne brisati `migrations_archive/` pre 30 dana nakon uspešnog prod push-a.
