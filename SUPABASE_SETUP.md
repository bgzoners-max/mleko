# Supabase setup – potpuna konfiguracija

Aplikacija koristi **Supabase** za bazu podataka, storage i autentifikaciju.
*Napomena: Firebase jeste uklonjen za ove servise, ali se **FCM (Firebase Cloud Messaging) i dalje aktivno koristi za Push notifikacije** (pogledaj `PUSH_SETUP.md` i `FIREBASE_SETUP.md`).*

## 1. Kreiraj projekat

1. Idi na https://supabase.com i registruj se
2. **New Project** → unesi ime (npr. `mleko`), lozinku za DB, region (npr. `Frankfurt`)
3. Sačekaj da se projekat kreira (~2 min)

## 2. Pokreni SQL migracije (OBAVEZNO)

Bez ovoga aplikacija neće raditi – šema zahteva tabele `profiles`, `products`, `orders`, `classified_ads`, `notifications`, itd.

Zvanični i jedini izvor istine za bazu su migracije u folderu **`supabase/migrations/`**.

**Preporučeni način (Supabase CLI):**
```bash
supabase db push
# ili
supabase migration up
```

**Ručni način (preko Supabase Dashboard SQL Editora):**
Ukoliko postavljate novu bazu bez CLI alata, primenite migracije redom po timestamp prefiksu iz foldera `supabase/migrations/`.
*(Fajl `supabase_schema.sql` u root-u je označen kao legacy i služi samo kao istorijska referenca početne šeme).*

## 3. Auth podešavanja

**Anonymous sign-ins** (za „Nastavi kao gost”):
1. **Authentication** → **Providers** → **Anonymous sign-ins** → uključi

**Email potvrda** (za brži razvoj možeš isključiti):
1. **Authentication** → **Providers** → **Email**
2. „Confirm email“ isključi ako želiš odmah da se korisnik uloguje nakon registracije

## 4. URL i ključ u aplikaciji

1. **Project Settings** (zupčanik) → **API**
2. Kopiraj **Project URL** i **anon public** key
3. Otvori `lib/supabase_config.dart` i unesi vrednosti

## 5. Storage – bucketovi i RLS (obavezno)

Bez ovoga profilna slika i slike proizvoda neće raditi – greške "Bucket not found" ili "Unauthorized".

1. **Storage** → **New bucket**
2. Ime: **`profiles`** → **Public bucket** ✓ → **Create bucket**
3. Ponovi: Ime: **`product-images`** → **Public bucket** ✓ → **Create bucket**
4. Ponovi: Ime: **`farm-gallery`** → **Public bucket** ✓ → **Create bucket** (za galeriju gazdinstva)

**RLS policy-ji** su uključeni u `supabase_schema.sql` – pokreni ceo SQL (korak 2) da bi se kreirali. Dozvoljavaju:
- čitanje slika svima
- upload profilne slike samo na svoj fajl (`userId.jpg`)
- upload slika proizvoda autentifikovanim korisnicima

## 6. Pokretanje

```bash
flutter pub get
flutter run -d chrome
```
