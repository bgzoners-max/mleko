# Naše mleko – MVP (B2C)

[![CI](https://github.com/bgzoners-max/mleko/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/bgzoners-max/mleko/actions/workflows/ci.yml)

Marketplace za domaće mlečne proizvode (kupuj direktno od proizvođača).

## CI

GitHub Actions workflow `.github/workflows/ci.yml` pokreće:

- `flutter-checks`: `flutter analyze` + `flutter test`
- `db-integration-checks`: lokalni Supabase stack + reset migracija + SQL integration provere

DB integration skripta:

- `supabase/tests/order_status_flow_integration.sql`

Ove provere pokrivaju ključne delove status flow-a: tranzicije, trigger-e, audit log i ručno arhiviranje.

## Šta je urađeno (MVP ekrani)

- **Splash** → Login
- **Login / Register** – email + lozinka, „Nastavi kao gost”, Zaboravljena lozinka
- **Home** – lokacija, search bar, kategorije (Sir, Kačkavalj, Kajmak), lista proizvoda (kartice)
- **Search + filter** – kategorija, region, dostupno sada
- **Product details** – carousel slika, naziv, cena, opis, min porudžbina, način preuzimanja, CTA „Pošalji porudžbinu”
- **Checkout-lite** – količina, napomena, grad, telefon, „Pozovi me” / „Pošalji poruku” → „Pošalji upit prodavcu”
- **Orders** – lista porudžbina sa statusom (Poslato, Prihvaćeno, Odbijeno, Isporučeno)
- **Profile** – moji podaci, „Postani prodavac”, Podrška, Logout
- **Postani prodavac** – Ime gazdinstva, Mesto, Telefon
- **Seller: Moji proizvodi** – lista, „Dodaj proizvod”
- **Add/Edit proizvod** – kategorija, naziv, cena/kg, min porudžbina, količina, opis, slike (1–5), način preuzimanja
- **Seller Inbox** – lista upita, „Pozovi”, „Označi kao rešeno”

**Navigacija:** donji bar – kupac: Home | Pretraga | Porudžbine | Profil; prodavac: Home | Moji proizvodi | Upiti | Profil.

## Pokretanje

1. **Flutter**  
   Instaliraj [Flutter](https://docs.flutter.dev/get-started/install) i u PATH dodaj `flutter`.

2. **Supabase**  
   Aplikacija koristi Supabase za auth, bazu i storage. Vidi **[SUPABASE_SETUP.md](SUPABASE_SETUP.md)** – posebno važno je pokrenuti `supabase_schema.sql` u SQL Editor-u u Supabase Dashboard-u.

3. **Projekat**
   ```bash
   cd d:\mleko
   flutter pub get
   ```

   **Nova obaveza: Environment vars (.env)**
   ```
   cp .env.example .env
   # Popuni SUPABASE_URL i SUPABASE_ANON_KEY iz Supabase Dashboard → Settings → API
   ```

   flutter run -d chrome
   ```

Ako nemaš još uvek platforme (android/ios/web), u root-u pokreni:

```bash
flutter create . --project-name mleko --org com.mleko
```

pa ponovo `flutter pub get` i `flutter run`.

## Supabase struktura

- **profiles** – email, phone, display_name, city, role (buyer/seller), is_guest, farm_name, location
- **products** – seller_id, category, name, price_per_kg, min_order_kg, available_kg, description, image_urls[], pickup_options[], location, is_domestic, available_now
- **orders** – buyer_id, seller_id, product_id, product_name, quantity_kg, note, buyer_city, buyer_phone, prefer_call, status (sent/accepted/rejected/delivered)

Slike proizvoda i profila se čuvaju u **Supabase Storage** (bucketovi `product-images` i `profiles`).

## Šta nije u MVP-u (nice to have)

- Recenzije  
- Online plaćanje  
- Integracija dostave  
- Geo „najbliže tebi”  
- Chat (samo kontakt: Pozovi / poruka)
