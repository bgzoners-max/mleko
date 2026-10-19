# 📌 Zabeleška za sledeću sesiju (Handover & Sledeći koraci)

**Datum ažuriranja:** 19. oktobar 2026.  
**Projekat:** Domaći Market ([domacimarket.rs](https://www.domacimarket.rs))  
**Git grana:** `master`

---

## 🏁 Trenutno stanje projekta (Gde smo stali)

1. **Desktop transformacija (Faze 1–5):**
   - Header, Hero sekcija, Kartice i 5-kolonski grid, Sidebar filteri i sortirani feed su kompletirani i pušteni u produkciju.
2. **🌐 SEO, Dinamički Sitemap & Server-Rendered Bot HTML (Završeno 19. okt):**
   - **Cloudflare Pages Middleware (`functions/_middleware.ts`):** Servira pravi `application/xml` sitemap direktno pre statičkog catch-all-a. Povezane `SUPABASE_URL` i `SUPABASE_ANON_KEY` secrets preko Wranglera.
   - **Dinamički `sitemap.xml`:** Uspešno izlistava 42 URL-a (38 statičkih ruta/kategorija + 4 dinamička proizvoda sa tačnim `lastmod` i prioritetima). Ispravljen SQL select upit uklanjanjem nepostojeće kolone `updated_at` na tabeli `products`.
   - **Bot SSR & OpenGraph:** Botovi (Googlebot, Viber, WhatsApp, Facebook) dobijaju čist SEO HTML sa unikatnim naslovima, opisima i kanonskim linkovima za svaku rutu i proizvod.
   - **Robots.txt & GSC 404:** Dodat `Disallow: /cdn-cgi/` u `robots.txt` radi sprečavanja grešaka 404 na Cloudflare sistemskim putanjama.
   - **308 Redirect Loop Fix:** Statičke stranice (`/politika-privatnosti`, `/uslovi-koriscenja`) konfigurisane preko čistih `index.html` direktorijuma, eliminisan 308 redirect loop.
   - **Automatski GitHub Actions CI/CD (`deploy-cloudflare.yml`):** Konfigurisan `CLOUDFLARE_API_TOKEN` i `npm ci` korak; svaki `git push origin master` automatski pokreće release build i deploy na Cloudflare Pages. Status: **success**.

---

## 🎯 Preostali prioriteti za rad

Na stolu su sledeće teme:

3. **🔔 Push Notifikacije – Produkciona verifikacija i popravka (Završeno 06. okt):**
   - **Vault konfiguracija:** Uneti `functions_base_url` i moderni `service_role_key` (`sb_secret_...`) u Supabase Vault. Rešen uzrok ranije greške `UNAUTHORIZED_LEGACY_JWT` gde je Supabase odbacivao stare HS256 JWT tokene.
   - **Baza i trigger migracija (`20261006160000`):** Primenjena migracija koja u `send_push_notification` dodaje `apikey` heder i prosleđuje `classified_ad_id` kroz `p_data` payload.
   - **Edge funkcija `send-push` (v49):** Ažurirana da prima i u FCM payload ubacuje `classified_ad_id` i `ticket_id` za instant otvaranje oglasa/tiketa na klik, i deploy-ovana na produkciju.
   - **End-to-end verifikacija:** Uspešno testiran kompletan lanac (`notifications` INSERT trigger -> `invoke_send_push` -> `pg_net` -> `send-push` Edge funkcija -> Google Firebase FCM v1 API). `edge_config_ok = true`, `anon_key_present = true`.
4. **📲 PWA Mobilno iskustvo & Galerija slika (Završeno 06. okt):**
   - **PWA Install Banner (`web/index.html`):** Dodat prilagođeni, moderni plutajući baner sa podrškom za `beforeinstallprompt` i pametnim 7-dnevnim odlaganjem ako korisnik klikne na zatvori.
   - **Galerija slika na oglasima (`ClassifiedImageGallery`):** Dodat brojač slika (`1 / N` pill bedž) i strelice za brzu navigaciju levo/desno preko fotografija.

---

5. **🛒 Tok porudžbina, Korpa & Retention (Završeno 06. okt):**
   - **Usklađivanje `LOGIKA_PORUDZBINE.md`:** Dokumentacija usklađena sa realnim produkcionim ponašanjem baze (ručno arhiviranje završenih porudžbina + dnevni `pg_cron` retention job u 03:00 UTC koji briše arhivirane porudžbine starije od 12 meseci i čisti agregate).
   - **UI poruke arhive (`OrdersScreen` & `SellerOrdersScreen`):** Ažurirana objašnjenja za kupce i prodavce sa jasnom napomenom o 12 meseci čuvanja u arhivi pre trajnog uklanjanja.
   - **Kartica prodavca u korpi (`CartSellerGroupCard`):** Poboljšana napomena o minimalnom iznosu (pojašnjeno da se minimum odnosi na termine lične dostave domaćina, dok su kurir i lično preuzimanje takođe opcije na checkout-u).
6. **🗺️ Seoska gazdinstva & Mapa domaćinstava (Završeno 06. okt):**
   - **Ispravka rute i taba:** Klik na tab "Seoska gazdinstva" u desktop navigaciji (`DesktopHeader`) sada direktno otvara interaktivnu mapu (`/sellers-map`), umesto preusmeravanja na početni feed pijace hrane.
   - **Desktop prikaz mape (`SellersMapScreen`):** Integrisan `DesktopHeader(isStandalone: true)` na desktop rezolucijama, postavljen jasan naslov ("Seoska gazdinstva na mapi"), dodat bedž sa brojem gazdinstava i dugme za automatsko centriranje svih markera ("Centriraj sve").
   - **Ispravka `permission denied for table profiles`:** U Supabase pogledu `public.public_profiles` eksplicitno isključen `security_invoker` (`ALTER VIEW ... SET (security_invoker = false);`) čime je rešen problem gde javni posetioci i kupci nisu mogli da učitaju stranicu profila prodavca (`/seller/:id`).
7. **🌙 Čitljivost u tamnoj temi – Svetlo zelena / Žuta (Završeno 06. okt):**
   - **Problem:** Tamno zelena slova i ikonice (`#2E7D32` i `#245938`) su se u tamnoj temi stopile sa tamnozelenom/crnom pozadinom (`#121714` i `#1B241E`), čineći aktivne tabove, kategorije, bedževe i linkove nečitljivim.
   - **Rešenje:** Uveden `AmazonColors.lightGreen` (`#81C784`, kontrast >8.5:1, WCAG AAA) i `AmazonColors.lightYellow` (`#FFD54F`). Zamenjena tamnozelena slova svetlo zelenim na svim ključnim mestima: aktivni navigacioni tabovi zaglavlja, birač regiona, nazivi kategorija na karticama proizvoda, linkovi "Promeni", "Vidi sve", "Poništi filtere", baneri porudžbina i bedž "BESPLATNO".
   - **Verifikacija:** Svi testovi prošli (432/432), `flutter analyze` 0 grešaka, izmene puštene na produkciju (`domacimarket.rs`).
8. **🧹 Čišćenje Desktop Zaglavlja – Uklanjanje suvišnog horizontalnog skrola kategorija (Završeno 06. okt):**
   - **Problem:** Horizontalni skrol sa kategorijama ("Poljoprivreda & Mehanizacija", itd.) u gornjem meniju zauzimao je vertikalni prostor i stvarao neudobno horizontalno skrolovanje mišem, dok su sve te iste kategorije već dostupne u bočnom levom panelu (sidebar) i u glavnom gridu na stranici.
   - **Rešenje:** Uklonjen `_buildCategoriesStrip` i pripadajući horizontalni skrol kontejner iz `DesktopHeader`. Zaglavlje je time znatno čistije, kompaktnije i preglednije.

---

## 🎯 Preostali prioriteti za rad

Na stolu su sledeće teme:

### Opcija B: 📱 Android Release Potpisivanje (Google Play Store)
- **Cilj:** Pripremiti i potpisati aplikaciju upload keystore-om umesto debug ključa.
- **Koraci:**
  - Pratiti uputstvo u [`docs/ANDROID_RELEASE_SIGNING.md`](./ANDROID_RELEASE_SIGNING.md).
  - Kreirati lokalni `android/app/upload-keystore.jks` i `android/key.properties`.
  - Sinhronizovati otisak u `web/.well-known/assetlinks.json` preko `dart run tool/sync_assetlinks.dart`.
  - Pokrenuti `flutter build appbundle --release -PrequireReleaseSigning=true` i verifikovati generisani `.aab` paket.

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
