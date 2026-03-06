# Migracija na Supabase – kompletni setup

Aplikacija sada koristi samo Supabase. Firebase je uklonjen.

## 1. Pokreni SQL schema

U Supabase Dashboard → **SQL Editor** → New query. Kopiraj sadržaj iz `supabase_schema.sql` i izvrši.

## 2. Kreiraj Storage bucket-e

### product-images (već imaš)
- Public bucket
- Policies: Public read, Public insert

### profiles (novo)
1. **Storage** → **New bucket**
2. Ime: `profiles`
3. **Public bucket**: uključi
4. **Create bucket**
5. **Policies** za `profiles`:
   - INSERT: `auth.role() = 'authenticated'` (ili `true` za MVP)
   - SELECT: `true`

## 3. Auth podešavanja

**Authentication** → **Providers**:
- **Email**: uključen
- **Confirm email**: isključi (za brži razvoj; možeš uključiti kasnije)

**Authentication** → **Providers** → **Anonymous**:
- Uključi (za prijavu kao gost)

## 4. Konfiguracija u app-u

`lib/supabase_config.dart` treba da sadrži tvoj URL i anon key (već je upisano).

## 5. Pokretanje

```bash
flutter pub get
flutter run -d chrome
```

---

## Važne napomene

- **Podaci**: Stari Firestore podaci se ne migriraju automatski. Korisnici moraju da se ponovo registruju.
- **Realtime**: Stream-ovi koriste polling (svakih 5 sekundi) – nije potrebna Realtime konfiguracija.
