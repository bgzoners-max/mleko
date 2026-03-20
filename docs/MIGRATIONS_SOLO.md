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
