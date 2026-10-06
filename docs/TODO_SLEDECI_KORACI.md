# 📌 Zabeleška za sledeću sesiju (Handover & Sledeći koraci)

**Datum ažuriranja:** 06. oktobar 2026.  
**Projekat:** Domaći Market ([domacimarket.rs](https://www.domacimarket.rs))  
**Git grana:** `master`

---

## 🏁 Trenutno stanje projekta (Gde smo stali)

1. **Desktop transformacija (Faze 1–5):**
   - Header, Hero sekcija, Kartice i 5-kolonski grid, Sidebar filteri i sortirani feed su kompletirani i pušteni u produkciju.
2. **🌐 SEO, Dinamički Sitemap & OpenGraph deljenje na mrežama (Završeno 06. okt):**
   - **Dinamički `sitemap.xml` (`api/sitemap.ts`):** Edge funkcija koja automatski dohvata sve aktivne male oglase i proizvode iz Supabase-a sa `lastmod` datumom, uz keširanje od 1h (`s-maxage=3600`) i stabilan fallback.
   - **OpenGraph za direktne linkove:** Dodati pametni Vercel rewrites sa proverom User-Agent hedera za botove (Viber, WhatsApp, Facebook, Telegram, Discord, Googlebot, Applebot...) za direktne adrese `/classifieds/ad/:id` i `/product/:id`. Sada i linkovi kopirani direktno iz browser bara generišu bogate kartice sa slikom, cenom i opisom.
   - **Usklađivanje stanja ('not_applicable'):** Ispravljen Schema.org JSON-LD i OpenGraph kod tako da se životinjama, sadnicama, voću i uslugama ne dodeljuje netačan `UsedCondition`.
   - **Verifikacija:** Svi testovi prolaze (432/432), `flutter analyze` čisto (0 issues), `npm run type-check` čisto (0 errors).

---

## 🎯 Preostali prioriteti za rad

Na stolu su sledeće teme:

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
