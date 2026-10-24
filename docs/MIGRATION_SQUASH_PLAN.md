# Migration squash — plan i status

> **Status (2026-10-24):**
> 1. Istorija od **228 starijih linearnih migracija** je konsolidovana u snapshot fajl `supabase/schema.sql` putem `tool/squash_migrations.dart`.
> 2. P0 seed čišćenje i RLS matrice su potpuno primenjene i zaštićene CI alatima (`tool/check_no_seed_data_in_migrations.dart`, `tool/scan_security_definer_migrations.dart`).
> 3. Novo kreirane migracije se dodaju inkrementalno od datuma cutoff-a (`20261024*`), dok `supabase/schema.sql` služi kao instant uvid u celokupnu DDL šemu.
> 4. Fizičko arhiviranje starih migracija u `supabase/migrations_archive/` podržano je kroz `dart run tool/squash_migrations.dart --apply` i zahteva prateći `supabase migration repair` na staging/prod instancama.

---

## 1. Kontekst

- `supabase/migrations/`: **231 SQL fajl** (228 istorijskih + 3 današnje inkrementalne).
- `supabase/schema.sql`: Konsolidovani DDL snapshot generisan putem `tool/squash_migrations.dart` (775 KB).
- Git tag: `migrations-pre-squash` (omogućava `git checkout migrations-pre-squash` u svakom trenutku radi uvida u istoriju pojedinačnih DDL izmena).
- CI mehanizam zaštite:
  - `tool/check_no_seed_data_in_migrations.dart` + `test/no_seed_in_migrations_test.dart` garantuju odsustvo seed naloga u migracijama.
  - `db-integration-checks` u `.github/workflows/ci.yml` automatski startuje Supabase, resetuje bazu, pokreće SQL testove i proverava `database.types.ts` schema drift.

---

## 2. Operativni koraci za izvršenje squasha

Squash se sprovodi u jednom kontrolisanom koraku kada je dostupan Docker ili Staging instanca:

### Korak A: Dump trenutne čiste šeme (Baseline)
```bash
# Opcija 1 — Ako je povezan Staging projekat (preporučeno, nula rizika po prod):
npx supabase link --project-ref <STAGING_PROJECT_REF>
npx supabase db push
npx supabase db dump --linked --schema-only -f supabase/baseline_schema.sql

# Opcija 2 — Ako je aktivan lokalni Docker:
npx supabase db reset --local --yes
npx supabase db dump --local --schema-only -f supabase/baseline_schema.sql
```

### Korak B: Arhiviranje i zamena migracija
```bash
# 1. Kreiranje arhivskog direktorijuma
mkdir -p supabase/migrations_archive

# 2. Premeštanje postojećih 221 migracija u arhivu
mv supabase/migrations/*.sql supabase/migrations_archive/

# 3. Postavljanje baseline šeme kao jedine početne migracije
mv supabase/baseline_schema.sql supabase/migrations/20261008190000_baseline_schema.sql
```

### Korak C: Lokalna i CI verifikacija
```bash
# 1. Reset sa novom baseline migracijom
npx supabase db reset --local --yes

# 2. Pokretanje integration SQL testova
psql postgresql://postgres:postgres@127.0.0.1:54322/postgres -v ON_ERROR_STOP=1 -f supabase/tests/order_status_flow_integration.sql
psql postgresql://postgres:postgres@127.0.0.1:54322/postgres -v ON_ERROR_STOP=1 -f supabase/tests/create_order_rpc_integration.sql

# 3. Regeneracija tipova i provera schema drift-a
npm run supabase:types:local
git diff --exit-code supabase/types/database.types.ts
```

### Korak D: Repair istorije na udaljenim bazama (Staging & Prod)
> **KRITIČNO:** Supabase CLI pamti verzije migracija u tabeli `supabase_migrations.schema_migrations`.
> Bez repair-a, sledeći `supabase db push` bi prijavio: `Remote migration versions not found in local`.

```bash
# Na staging bazi:
npx supabase migration repair --status reverted <stare_verzije>
npx supabase migration repair --status applied 20261008190000

# Na produkcijskoj bazi (nakon uspešne verifikacije na stagingu):
npx supabase migration repair --status reverted <stare_verzije>
npx supabase migration repair --status applied 20261008190000
```

---

## 3. Sigurnost i Rollback

- Istorija je u potpunosti zaštićena tagom `migrations-pre-squash` i folderom `supabase/migrations_archive/`.
- Povratak na staro stanje u slučaju bilo kakvog problema:
  ```bash
  git checkout migrations-pre-squash -- supabase/migrations/
  ```
- Arhivski folder `supabase/migrations_archive/` se zadržava u repozitorijumu najmanje 30 dana nakon primene na produkciji.

