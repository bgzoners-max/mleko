# Naše Selo (mleko) — Marketplace & Oglasnik Domaćih Proizvoda

[![CI](https://github.com/bgzoners-max/mleko/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/bgzoners-max/mleko/actions/workflows/ci.yml)
[![Coverage](https://img.shields.io/badge/Coverage-35.17%25-yellowgreen)](STATUS.md)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Postgres%20%7C%20Auth%20%7C%20Storage-3ECF8E?logo=supabase)](https://supabase.com)
[![License](https://img.shields.io/badge/License-Proprietary-blue.svg)]()

**Naše Selo** je moderna multiplatformska platforma (Web, Android, iOS) koja direktno povezuje lokalne poljoprivredne proizvođače i seoska gazdinstva sa krajnjim kupcima širom Srbije, uz integrisane male oglase za poljoprivredu.

---

## 🌟 Ključne Funkcionalnosti

### 1. Pijaca i Katalog Proizvoda
- **Direktna kupovina**: Pretraga domaćih proizvoda (mleko i sir, meso, voće, povrće, jaja, med, zimnica...) direktno od seoskih gazdinstava.
- **Fleksibilne merne jedinice**: Podrška za `kg`, `L`, `kom`, `pak`, `veza` sa definisanim minimalnim količinama i koracima naručivanja (`min_order`, `order_step`).
- **Geo-lokacija i gradovi**: Filtriranje i sortiranje po gradovima i opštinama u Srbiji, opcije preuzimanja (lično, dostava, dogovor).
- **Korpa (Cart) i Upiti**: Dodavanje artikala od više proizvođača, automatsko grupisanje porudžbina po prodavcima i slanje upita za rezervaciju.

### 2. Mali Oglasi za Poljoprivredu (Classifieds)
- Oglasi specijalizovani za ruralni sektor: poljoprivredne mašine, stoka i živina, stočna hrana, oprema, sadnice i usluge.
- Napredna pretraga sa filterima, galerija slika, brojač jedinstvenih pregleda sa zaštitom od zloupotrebe.
- Mogućnost direktnog kontakta prodavca putem poziva ili chata.

### 3. Direktni Real-time Chat
- Integrisana razmena poruka između kupca i prodavca u realnom vremenu (Supabase Realtime).
- Kontekst razgovora vezan za konkretne proizvode, porudžbine ili oglase.
- Prikaz nepročitanih poruka (unread badges) i push notifikacije o novim porukama.

### 4. Push Notifikacije i Centar za Obaveštenja
- **FCM (Firebase Cloud Messaging)**: Pozadinska i in-app dostava notifikacija na mobilnim i web uređajima.
- **Bezbedna arhitektura**: Obaveštenja se kreiraju isključivo na serveru (PostgreSQL `SECURITY DEFINER` trigeri) i isporučuju kroz `send-push` Edge funkciju autorizovanu striktno preko `service_role`.
- **Centar za obaveštenja**: Pregled istorije obaveštenja, statusa porudžbina, poruka i sistemskih preporuka.

### 5. Gazdinstva i Prodavci
- Jednostavna registracija gazdinstva sa verifikacijom lokacije i kontakt telefona.
- Dashboard za prodavce: upravljanje zalihama, cenama, dostupnošću („Dostupno odmah”) i praćenje statusa pristiglih upita/porudžbina.

### 6. Admin Panel i Moderacija
- Moderacija malih oglasa, odobravanje i suspenzija sumnjivih objava.
- Verifikacija profila prodavaca i uvid u audit logove.

---

## 🏗️ Tehnološki Stack

- **Frontend**: [Flutter 3](https://flutter.dev) (Dart), State Management (`Provider`), Navigacija (`GoRouter` sa `StatefulShellRoute`).
- **Backend & Baza**: [Supabase](https://supabase.com) (PostgreSQL 15+, Row Level Security, Realtime, Edge Functions u Deno/TypeScript).
- **Push Notifikacije**: Firebase Cloud Messaging (FCM) + Supabase Edge Functions (`send-push`).
- **Pohrana datoteka**: Supabase Storage (`product-images`, `classified-images`, `avatars`).
- **Hosting / Deploy**: Cloudflare Pages (`domacimarket.rs`), CI/CD preko GitHub Actions.

---

## 🚀 Brzi Start

### 1. Preduslovi
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.2.0`)
- [Node.js](https://nodejs.org) (v18+) & `npm`
- [Supabase CLI](https://supabase.com/docs/guides/cli)

### 2. Podešavanje okruženja
Klonirajte repozitorijum i instalirajte zavisnosti:
```bash
git clone https://github.com/bgzoners-max/mleko.git
cd mleko
flutter pub get
```

Iz bezbednosnih razloga i sprečavanja slučajnog pisanja u produkcionu bazu, debug pokretanje zahteva eksplicitno navođenje okruženja (`APP_ENV=local|staging|prod`) ili konfiguracionog fajla.

Za lokalni razvoj (podrazumevani lokalni Supabase na `http://127.0.0.1:54321`):
```bash
# Direktno preko parametra:
flutter run --dart-define=APP_ENV=local

# Ili preko konfiguracionog fajla (preporučeno):
cp config/local.json.example config/local.json
flutter run --dart-define-from-file=config/local.json
```

Za povezivanje na staging ili sopstveni Supabase projekat:
```bash
# Web
flutter run -d chrome --dart-define=APP_ENV=staging --dart-define=SUPABASE_URL="TvojUrl" --dart-define=SUPABASE_ANON_KEY="TvojKljuc"

# Mobilni
flutter run --dart-define-from-file=config/staging.json
```

Za pokretanje debug režima protiv produkcije (zahteva eksplicitnu nameru):
```bash
flutter run --dart-define=APP_ENV=prod
```

---

## 🧪 Testiranje i CI/CD

Na projektu se primenjuje striktna automatizovana kontrola kvaliteta:
```bash
# Statička analiza koda
dart analyze

# Pokretanje Flutter testova
flutter test

# Regeneracija Supabase TypeScript tipova
npm run supabase:types
```

GitHub Actions workflow (`.github/workflows/ci.yml`) automatski izvršava:
1. `flutter-checks`: Statičku analizu (uz `--no-fatal-infos`) i testove sa pokrivenošću od ~32%.
2. `db-integration-checks`: Podizanje lokalnog Supabase okruženja, primenu migracija i izvršavanje SQL integracionih provera (`supabase/tests/order_status_flow_integration.sql`).
   > **Napomena**: Folder `supabase/migrations/` predstavlja jedini i kanonski izvor istine za strukturu baze podataka (zastareli snapshot fajlovi šeme su uklonjeni).

---

## 📚 Dokumentacija Repozitorijuma

Za detaljnije tehničke specifikacije pogledajte prateću dokumentaciju u repozitorijumu:

| Dokument | Sadržaj |
| :--- | :--- |
| **[REPO_BIBLE.md](REPO_BIBLE.md)** | **Kanonski izvor istine**: pravila za merne jedinice, korake naručivanja, statuse porudžbina, RLS matrice i filozofiju zaliha. |
| **[CHANGELOG.md](CHANGELOG.md)** | Istorijat verzija, promena, ispravki i produkcionih izdanja. |
| **[CONTRIBUTING.md](CONTRIBUTING.md)** | Pravila grananja, kodiranja, konvencija commit poruka i kreiranja PR-ova. |
| **[docs/SUPABASE_SETUP.md](docs/SUPABASE_SETUP.md)** | Uputstvo za konfiguraciju lokalnog i udaljenog Supabase projekta (inicijalni setup). |
| **[docs/SUPABASE_DATABASE.md](docs/SUPABASE_DATABASE.md)** | Izvor istine za bazu, pravila migracija, deploy procedura (`supabase db push`) i RLS. |
| **[docs/MIGRATIONS_SOLO.md](docs/MIGRATIONS_SOLO.md)** | Rad sa SQL migracijama, rešavanje konflikata i postupak deploymenta šeme. |
| **[docs/PUSH_SETUP.md](docs/PUSH_SETUP.md)** | Arhitektura i podešavanje FCM push notifikacija i Edge funkcija. |
| **[docs/LOGIKA_PORUDZBINE.md](docs/LOGIKA_PORUDZBINE.md)** | Detaljan tok kreiranja porudžbina, validacija i bezbednosni triggeri. |
| **[docs/ERROR_HANDLING_GUIDE.md](docs/ERROR_HANDLING_GUIDE.md)** | Standardizovani obrasci rukovanja greškama i mrežnim prekidima. |
| **[docs/OFFLINE_MODE_GUIDE.md](docs/OFFLINE_MODE_GUIDE.md)** | Keširanje podataka, offline režim rada i sinhronizacija. |
| **[docs/ANDROID_RELEASE_SIGNING.md](docs/ANDROID_RELEASE_SIGNING.md)** | Potpisivanje Android release builda, keystore i Digital Asset Links (App Links). |
| **[docs/archive/README.md](docs/archive/README.md)** | Arhivirani izveštaji o završenim fazama razvoja (Faza 3, Faza 4, UI/UX auditi). |

---

## 🚢 Produkcijski Deploy

Za produkcioni deploy Web verzije na Cloudflare Pages koristi se skripta:
```bash
npm run deploy:all
```
Ova skripta kompajlira optimizovani Flutter Web bundle (`build/web`), priprema `build/cloudflare-deploy` (sa `_headers`, `_routes.json`, `.well-known` i Cloudflare funkcijama) i vrši bezbedan deploy na Cloudflare Pages projekat `domacimarket` (`domacimarket.rs`).
