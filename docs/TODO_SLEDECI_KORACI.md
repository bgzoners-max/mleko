# 📌 Zabeleška za sledeću sesiju (Handover & Sledeći koraci)

**Datum ažuriranja:** 05. oktobar 2026.  
**Projekat:** Domaći Market ([domacimarket.rs](https://www.domacimarket.rs))  
**Git grana:** `master` (čisto radno stablo, verifikovano i sinhronizovano sa `origin/master`)

---

## 🏁 Trenutno stanje projekta (Gde smo stali)

Uspešno je završena i puštena u produkciju kompletna **Desktop transformacija (Faze 1–5)**:
1. **Faza 1: Desktop Header & Mega Nav:**
   - Implementiran top utility bar, search sa izborom regiona, prečice (korpa, poruke, porudžbine, notifikacije, dark/light tema) i Bitter tipografija.
2. **Faza 2: Desktop Hero sekcija & Široki layout:**
   - Ruralni fotorealistični baner sa Bitter naslovom, 3 trust bedža, direktnim CTA dugmićima i tagovima kategorija. Širina layouta podešena na 1280–1360px.
3. **Faza 3: Kartice proizvoda i oglasa (Hover efekti & 5-kolonski grid):**
   - Dodat "PROVERENO" bedž, hover animacija uzdizanja (`-4px`), plutajući bedževi "Pogledaj detalje" i "Detalji oglasa", i integracija novog headera na detaljima oglasa/proizvoda.
4. **Faza 4: Desktop bočni filter panel & Grid feed:**
   - `ClassifiedsDesktopSidebar` sa stablom kategorija i brojem oglasa, cenovnim filterom (EUR), brzim rasponima, filterom po gradovima, stanju, tipu prodavca i promocijama (hitno / istaknuto).
   - Dvo-kolonski feed na `ClassifiedsFeedScreen` sa sortiranjem i uklanjanjem aktivnih filtera.
5. **Faza 5: Poliranje, Testovi i Release:**
   - 22/22 widget testova prolaze (`flutter test`).
   - `flutter analyze` prolazi bez ijedne greške ili upozorenja (0 issues).
   - Aplikacija je izgrađena i deploy-ovana na Vercel produkciju na `https://www.domacimarket.rs`.

---

## 🎯 Prioriteti i opcije za sledeći put

Kada nastavimo, na stolu su sledeće teme prema želji i prioritetu:

### Opcija A: 🔔 Push Notifikacije – Produkciona verifikacija
- **Cilj:** Verifikovati da FCM i Supabase Edge funkcije (`send-push`) pouzdano dostavljaju notifikacije na produkciji.
- **Koraci:**
  - Pokrenuti u Supabase SQL Editoru:
    ```sql
    SELECT * FROM public.push_health_summary();
    ```
  - Proveriti da li je `service_role_key` unet u Supabase Vault i proveriti tok slanja notifikacija za poruke i nove oglase prema [`docs/PUSH_SETUP.md`](./PUSH_SETUP.md).

### Opcija B: 📱 Android & iOS Native Release (Google Play / App Store)
- **Cilj:** Pripremiti i potpisati aplikaciju za Play Store.
- **Koraci:**
  - Pratiti uputstvo u [`docs/ANDROID_RELEASE_SIGNING.md`](./ANDROID_RELEASE_SIGNING.md).
  - Kreirati lokalni keystore i `android/key.properties`.
  - Pokrenuti `flutter build appbundle --release` i testirati generisani `.aab` paket.

### Opcija C: 🌐 SEO, OpenGraph & Deljenje na mrežama
- **Cilj:** Kada se link oglasa ili proizvoda pošalje na Viber, WhatsApp, Facebook ili Telegram, prikazuje se lepa kartica sa slikom, cenom i naslovom.
- **Koraci:**
  - Konfiguracija dinamičkih meta tagova / OpenGraph protokola na web shell-u.
  - Generisanje `sitemap.xml` i provera indeksiranja na Google Search Console za `domacimarket.rs`.

### Opcija D: 📲 PWA Mobilno iskustvo
- **Cilj:** Poboljšati instalaciju i rad web aplikacije na telefonima.
- **Koraci:**
  - Dodavanje prilagođenog "Instaliraj aplikaciju" banera (`beforeinstallprompt`) umesto generičkog browser prompta.
  - Provera dodirnih gestova (swipe u galeriji slika na oglasima).

### Opcija E: 💼 Prodajne i analitičke funkcije
- **Cilj:** Dodati metriku i alate za prodavce:
  - Brojač pregleda oglasa i brojač klikova na "Pozovi prodavca".
  - Dodatna unapređenja toka naručivanja prema [`docs/LOGIKA_PORUDZBINE.md`](./LOGIKA_PORUDZBINE.md).

---

## 🛠️ Brze komande za start sledeći put

```bash
# Provera koda
flutter analyze

# Pokretanje testova
flutter test

# Ponovni deploy na produkciju (ako se naprave izmene)
npm run deploy:all
```
