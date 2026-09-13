# Naše Selo (mleko) — Marketplace & Oglasnik Domaćih Proizvoda

[![CI](https://github.com/bgzoners-max/mleko/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/bgzoners-max/mleko/actions/workflows/ci.yml)
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
- **Hosting / Deploy**: Vercel za Web distribuciju, CI/CD preko GitHub Actions.

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

Kopirajte šablon promenljivih okruženja:
```bash
cp .env.example .env
```
Popunite `SUPABASE_URL` i `SUPABASE_ANON_KEY` kredencijalima iz vašeg Supabase projekta.

### 3. Pokretanje aplikacije
```bash
# Pokretanje u Chrome pregledaču
flutter run -d chrome

# Pokretanje na povezanom mobilnom uređaju ili emulatoru
flutter run
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
1. `flutter-checks`: Analizu i testove sa nula dozvoljenih upozorenja.
2. `db-integration-checks`: Podizanje lokalnog Supabase okruženja, primenu migracija i izvršavanje SQL integracionih provera (`supabase/tests/order_status_flow_integration.sql`).

---

## 📚 Dokumentacija Repozitorijuma

Za detaljnije tehničke specifikacije pogledajte prateću dokumentaciju u repozitorijumu:

| Dokument | Sadržaj |
| :--- | :--- |
| **[REPO_BIBLE.md](REPO_BIBLE.md)** | **Kanonski izvor istine**: pravila za merne jedinice, korake naručivanja, statuse porudžbina, RLS matrice i filozofiju zaliha. |
| **[CONTRIBUTING.md](CONTRIBUTING.md)** | Pravila grananja, kodiranja, konvencija commit poruka i kreiranja PR-ova. |
| **[docs/SUPABASE_SETUP.md](docs/SUPABASE_SETUP.md)** | Uputstvo za konfiguraciju lokalnog i udaljenog Supabase projekta. |
| **[docs/MIGRATIONS_SOLO.md](docs/MIGRATIONS_SOLO.md)** | Rad sa SQL migracijama, rešavanje konflikata i postupak deploymenta šeme. |
| **[docs/PUSH_SETUP.md](docs/PUSH_SETUP.md)** | Arhitektura i podešavanje FCM push notifikacija i Edge funkcija. |
| **[docs/LOGIKA_PORUDZBINE.md](docs/LOGIKA_PORUDZBINE.md)** | Detaljan tok kreiranja porudžbina, validacija i bezbednosni triggeri. |
| **[docs/ERROR_HANDLING_GUIDE.md](docs/ERROR_HANDLING_GUIDE.md)** | Standardizovani obrasci rukovanja greškama i mrežnim prekidima. |
| **[docs/OFFLINE_MODE_GUIDE.md](docs/OFFLINE_MODE_GUIDE.md)** | Keširanje podataka, offline režim rada i sinhronizacija. |
| **[docs/archive/README.md](docs/archive/README.md)** | Arhivirani izveštaji o završenim fazama razvoja (Faza 3, Faza 4, UI/UX auditi). |

---

## 🚢 Produkcijski Deploy

Za produkcioni deploy Web verzije koristi se skripta:
```bash
npm run vercel:deploy
```
Ova skripta kompajlira optimizovani Flutter Web bundle (`build/web`), priprema `build/vercel-deploy` i vrši bezbedan deploy na produkcioni Vercel projekat.
