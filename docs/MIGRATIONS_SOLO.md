# Migracije (solo rad, bez obaveznog Docker-a)

## Šta znači greška „Remote migration versions not found in local“

Udaljeni Supabase projekat u tabeli istorije migracija ima **verzije** za koje **nema** odgovarajućih fajlova u `supabase/migrations/`. To se dešava ako su migracije radjene na drugom računaru, obrisani fajlovi, ili grananje bez merge-a.

**Bez Docker-a** ne možeš lokalno pokrenuti `supabase db pull` na isti način kao sa Docker Desktop-om (CLI koristi shadow DB). Opcije:

1. **Usaglasi repo** – vrati nedostajuće `.sql` fajlove iz backup-a / starijeg zip-a / istorije ako postoje.
2. **Supabase Dashboard** – SQL editor: proveri šemu ručno; dokumentuj šta je na produkciji.
3. **`supabase migration repair`** – samo nakon čitanja zvanične dokumentacije; menja istoriju na remote-u.

Ne pokretaj `repair` naslepo ako ne znaš koje su migracije zaista primenjene na bazu.

## Test podaci (`@test.rs`)

- **Ne** očekuj da `supabase db push` puni test korisnike – seed migracije `20260227120000` i `20260227130000` su no-op; test podaci idu samo kroz **`supabase/seed.sql`** pri **`supabase db reset`** (lokalno, sa Docker-om za lokalni stack).
- U `products` važi **`order_step <= min_order_kg`** (`products_order_step_lte_min_order`). U seed-u uvek eksplicitno postavi **`order_step`** pri INSERT-u — default kolone `1` lomi seed ako je `min_order_kg` manji od 1.

## Nova migracija: uklanjanje `recipes`

`20260321140000_drop_recipes_table.sql` uklanja tabelu `recipes` ako postoji. Primeni na remote kada budeš spreman.

---

## 🏛️ Strategija konsolidacije i „Baseline“ migracija (180+ migracija)

Trenutni repo broji preko 180 migracija u `supabase/migrations/`, od kojih mnoge predstavljaju iterativne popravke indeksa, sigurnosnih definera i polja (`fix_...`).

### Zašto ih NE brisati naprečac:
- Supabase prati verzije u sistemskoj tabeli `supabase_migrations.schema_migrations`.
- Ako se lokalni fajlovi obrišu pre usaglašavanja, Supabase CLI prijavljuje:  
  `Remote migration versions not found in local`.

### Preporučeni koraci za kreiranje čiste baseline šeme:
1. **Kreiranje stabilnog šema-dumpa**:
   ```bash
   # Dump čiste DDL šeme sa produkcije/staging-a (bez podataka)
   supabase db dump --schema-only -f supabase/baseline_schema.sql
   ```
2. **Arhiviranje starih migracija**:
   - Premestiti sve dosadašnje migracije u `docs/sql/migrations_archive/` (radi istorijskog traga).
   - Kreirati početnu baseline migraciju `20260901000000_baseline_schema.sql` koja sadrži konsolidovano stanje svih tabela, enuma, funkcija, indeksa i RLS politika.
3. **Usklađivanje okruženja**:
   - Na postojećoj remote bazi: `supabase migration repair --status applied <verzije>` ili zadržavanje inkrementalnih migracija do sledeće veće verzije (v2.0).
   - Za nova okruženja (dev, staging, novi developer): baza se instant podiže iz jednog baseline fajla.

### Kvartalna konsolidacija (novi proces od Q4 2026)

Svakog kvartala (januar, april, jul, oktobar) pregledaj migracije iz prethodnog kvartala i spoji stabilne grupe:

| Korak | Akcija | Komanda / alat |
|-------|--------|----------------|
| 1 | Identificiraj feature-grupe | Ručni pregled: npr. svi `fix_rls_*`, svi `add_index_*` |
| 2 | Proveri da su primenjene na produkciji | `supabase migration list` |
| 3 | Spoji u jednu migraciju po feature grupi | Ručno: kreiraj `YYYYMMDD_consolidated_<feature>.sql` |
| 4 | Označi stare kao `applied` | `supabase migration repair --status applied <verzija>` |
| 5 | Premesti stare u arhivu | `mv supabase/migrations/<stare> docs/sql/migrations_archive/` |
| 6 | Verifikuj | `supabase db reset --local` mora proći čisto |

**Pravila:**
- Nikada ne konsoliduj migracije koje nisu primenjene na SVA okruženja (dev, staging, prod).
- Ostavi minimum 30 dana od poslednje primene pre konsolidacije.
- Dokumentuj svaku konsolidaciju u `CHANGELOG.md` sa listom spojenih migracija.

---

## 🛡️ Bezbednost `supabase/seed.sql` i test naloga (`password123`)

- `supabase/seed.sql` sadrži test naloge sa šifrom `password123` za lokalno testiranje kupaca i prodavaca.
- **Bezbednosna garancija**:
  - Komanda `supabase db push` na remote okruženju **NIKADA** ne pokreće `seed.sql` (remote izvršava isključivo SQL skripte iz `supabase/migrations/`).
  - Stare migracije koje su imale seed logiku (`20260227120000` i `20260227130000`) su u repozitorijumu postavljene kao **no-op** (prazne).
  - Seed skripta se izvršava **isključivo lokalno** pri `supabase db reset`.
  - **Pravilo**: `seed.sql` nikada ne pokretati kroz Supabase Dashboard SQL Editor na produkcionom projektu.

