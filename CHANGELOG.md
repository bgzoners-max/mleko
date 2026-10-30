# Changelog

Sve značajne promene na projektu **Domaći Market** (`mleko`) dokumentuju se u ovom fajlu.
Format prati [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Nepotpisano] - 2026-10-30 — Uklanjanje Vercel legacy stacka (hosting konsolidacija)

### Removed
- **`api/` direktorijum (Vercel serverless funkcije)** — 6 fajlova koji su
  duplikat novije Cloudflare Pages varijante u `functions/api/` (koja je
  nadskup: sadrži i `static-seo-pages.ts` i `upload.ts`) i već su **divergirali**
  (npr. `sitemap.ts`). Vercel deploy je ionako bio onemogućen
  (`"deploymentEnabled": false`), pa je ovo bio mrtav kod sa rizikom drift-a.
- **`vercel.json`** — sva bezbednosna zaglavlja (CSP, HSTS, X-Frame-Options...)
  već žive u `web/_headers` za Cloudflare Pages, koja je **nadskup** (uključuje
  i R2 storage domen u CSP-u kojeg vercel.json nije imao). Cache pravila su
  identična.
- **`.vercelignore`** — bez funkcije bez Vercel deploja.

### Changed
- **Jezička strategija (l10n odluka — samo srpski `sr-RS`)**: formalizovana odluka da platforma koristi isključivo srpski jezik (`sr-RS`, latinica direktno u kodu bez `.arb` i `AppLocalizations` sloja). Pojednostavljen `functions/api/_shared/locales.ts`, uklonjen prazan `lib/l10n/` direktorijum, dokumentovano pravilo u `CONTRIBUTING.md` i arhiviran nacrt višejezične SEO strategije u `docs/archive/SEO_GLOBALNI_PREDLOZI.md`.
- **Refaktor velikih ekrana (#6)**: razbijeno 6 najvećih ekrana (`about_screen`, `seller_guide_screen`, `classifieds_feed_screen`, `classified_ad_detail_screen`, `home_screen`, `search_screen`) u 10 modularnih vidžeta i ispražnjena `ignoreFiles` lista u `tool/check_file_size.dart`.
- **`tsconfig.json`**: `include` sada pokriva samo `functions/**/*.ts`.
- **CI (`ci.yml`)**: korak preimenovan u „TypeScript type-check (Cloudflare
  Pages functions)" (bilo „Vercel edge functions").
- **`web-preview.yml`**: uklonjen `push` trigger na master — Firebase Hosting
  deploy se sada dešava **samo za PR-ove** (channel `pr-<broj>`). Time je
  uklonjen neočekivani treći „produkcioni" deploy na Firebase `live` kanal
  koji je bio van smoke testa i rollback procedure iz `docs/DEPLOYMENT.md`.
  Produkciona verzija ide isključivo kroz `deploy-cloudflare.yml`.
- **`.gitignore`**: uklonjena dupla `.vercel` stavka.
- **Dokumentacija**: `docs/SECURITY.md` (zaglavlja sada u `web/_headers`),
  `docs/STAGING_ENVIRONMENT.md` (označeno zastarelim — staging treba graditi
  na Cloudflare stacku), `docs/DEPLOYMENT.md` (dopuna o PR-only preview deployu).

### Fixed
- **Ćirilični karakteri u poštanskim brojevima (pre-existing CI break):** 9 unosa u
  `lib/constants/serbian_postal_codes_data_*.dart` je sadržalo ćirilično slovo
  č (U+0447) umesto latiničnog č (U+010D) (npr. `Lipnički Šor`, `Čačak`,
  `Dubočane`, `Novi Bračin`) —
  komit `fd4ab97` je time lomio CI korak „Enforce cyrillic-free code”
  (`tool/check_cyrillic_strings.dart`). Zamenjeno svih 9 pojavljivanja;
  `test/serbian_postal_codes_test.dart` (9 testova) prolazi.

### Added
- **Identifikacija proizvođača hrane (BPG / PIB), pravna odgovornost i bedž poverenja**:
  - Migracija `20261030170000_seller_bpg_pib_and_liability.sql`: kolone `legal_type` (`rpg` / `company`), `bpg` (12 cifara), `pib` (9 cifara + ISO 7064 MOD 11-10 kontrolna cifra preko `public.is_valid_serbian_pib`), `legal_liability_accepted_at` i zaštita punog BPG broja u `public_profiles` (`bpg_masked`).
  - Validator `SellerRegistrationValidator` + 9 jediničnih testova u `test/seller_registration_validator_test.dart`.
  - UI izbor RPG (BPG) / Pravno lice (PIB) i obavezna potvrda sanitarne i poreske odgovornosti na `BecomingSellerScreen`, `SellerSettingsScreen` (`SellerLegalRegistrationSection`) i `AddEditProductScreen`.
  - Javni bedž „Verifikovano gazdinstvo (BPG)" / „Registrovani proizvođač (PIB)" na profilu prodavca i stranici proizvoda + dopunjen Član 4 u `web/uslovi-koriscenja.html` (status informatičkog posrednika po čl. 16–20. Zakona o elektronskoj trgovini).
- **Testovi kritičnih putanja (repositories + cart widgeti, 36 novih testova):**
  - `test/repositories/orders_repository_test.dart` (18): `SupabaseOrdersRepository`
    kroz MockHttpHandlerClient obrazac — `getOrderById`/`getOrderItems`/
    `getOrderStatusAuditLogs`/stats mapiranje; **sve validacije**
    `createOrderWithItems` (prazne stavke, nepostojeći proizvod, seller
    mismatch, količina van `order_step`) + happy put sa proverom
    `create_order_with_items` RPC parametara; arhiviranje (PATCH filteri po
    buyer/seller, `archive_order` RPC) i `confirmOrderReceivedByBuyer`
    (uspeh/odbitak).
  - `test/repositories/products_repository_test.dart` (13):
    `getProduct` happy put iz view-a, **fallback na `products` tabelu kad view
    pukne (500)**, null kada ne postoji; `getProductsByIds`/`getProductsByCategories`
    (prazni ulazi bez ijednog HTTP poziva, `hasMore` semantika); `createProduct`/
    `updateProduct`/`deleteProduct` (INSERT/PATCH/DELETE + `toDbMap` bez `id`/`created_at`).
  - `test/cart_widgets_test.dart` (5): `CartGuestBanner` (prikaz + onDismiss),
    `CartItemTile` (naziv/količina/izračunata cena + onRemove) i
    `CartSellerGroupCard` (render grupe, navigacija „Naruči" na
    `/checkout-seller/:id`, uklanjanje stavke uz `onRefresh` i animaciju).
- **Schema snapshot drift guard**: `tool/squash_migrations.dart --check` —
  regeneriše očekivani sadržaj `supabase/schema.sql` u memoriji (bez pisanja
  na disk) i poredi ga sa commitovanom verzijom (ignoriše `-- Generated at`
  oznaku i CRLF razlike). Novi CI korak „Verify schema.sql snapshot sync" u
  `ci.yml` garantuje da snapshot ne može tiho da zastari ili bude ručno
  izmenjen bez uočavanja. Prilikom refaktora alata očišćena su sva 10 info
  nalaza analyzer-a (`prefer_final_locals`, `cascade_invocations`) — fajl je
  sada čist pod `--fatal-infos` pravilima.

## [Nepotpisano] - 2026-10-24 — Testiranje i CI/CD (tačka 7 hardening audita)

### Added
- **Unit testovi za `ErrorHandlerService`** (`test/error_handler_service_test.dart`, 13 testova): notifikacija listenera, retry semantika (`shouldRetry` override, non-retryable greške, centralno `handleError` po iscrpljenju pokušaja) i `Result` tip semantika.
- **Golden testovi za `ProductCard`** (`test/golden/product_card_golden_test.dart`, 4 goldena): svetla/tamna tema, statusni bedževi (RASPRODATO/NOVO/PROVERENO/25+ PRODAJA) i omiljeni (puno srce). Deterministički — bez mrežnih poziva (`RusticImagePlaceholder`).
- **Deljeni golden helper** (`test/golden/golden_test_helpers.dart`): `TolerantGoldenFileComparator` izdvojen iz `theme_toggle_switch_golden_test.dart` radi reuse-a u budućim golden testovima.
- **Unit testovi za Repository delegaciju u `OrdersService`** (`test/orders_service_repository_delegation_test.dart`, 11 testova): mock `OrdersRepository` snima sve pozive; pokriveno svih 23 delegirajućih metoda + `forTesting`/factory semantika.
- **Deno unit testovi za `send-push` Edge funkciju** (`supabase/functions/send-push/push_helpers.test.ts`, 15 testova): `shortId`, `redactText`, `getLockscreenBody` (normalizacija razmake, sečenje na granici reči), `resolveLogLevel`, `isLogLevelEnabled`.
- CI korak `deno test` za Edge function helper testove u `db-integration-checks` job-u.

### Changed
- **Stroži analyzer gate u CI**: `flutter analyze --no-fatal-infos` → `flutter analyze --fatal-infos` — svaki budući info nalaz je sada fatalan. Uz to je povučen `cascade_invocations` lint (sistematski narušavan na 40+ fajlova, 73 info nalaza; forsiranje kaskada uvodilo rizik regresija bez koristi).
- **Refaktor `send-push/index.ts`**: čisti helperi (log-level logika, PII redakcija, lockscreen body) izdvojeni u `push_helpers.ts` bez promene ponašanja — omogućava unit-testiranje bez pokretanja servera.
- Coverage ratchet podignut: ukupno **35.42% → 36.04%**, `lib/services/orders` **55.27% → 58.76%**.

### Changed (dopuna 2026-10-24 — cascade cleanup)
- **`cascade_invocations` lint vraćen i SVIH 75 nalaza očišćeno** u kaskade (45 u `lib/`, 30 u `test/`+`integration_test/`): painter grupe u `rustic_illustration.dart`/`rustic_image_placeholder.dart`/`google_icon.dart`, `clear/addAll` parovi u `CartProvider`, `toList()..sort()` obrasci, provider filter kaskade, `AppState` test setup-i i `FakeProductsService` mock setup-i. Ponašanje nepromenjeno — 133 testa izmenjenih fajlova + integration E2E prolaze; pokrivenost stabilna na 36.04%.

### Added (dopuna 2026-10-24 — tačka 10: Dokumentacija)
- **`supabase/functions/send-push/README.md`** — API ugovor Edge funkcije: autorizacioni model (service_role/authenticated-samo-sebi), oba oblika zahteva (direktni + trigger `body.record`), tabela svih response kodova, auto-personalizacija naslova, ponašanje po platformi (Android kanali, iOS APNs), env secrets i primer curl poziva.
- **`docs/INCIDENT_RUNBOOK.md`** — operativni runbook: 5 scenarija (push ne stiže → dijagnoza po `push_health_summary`/`push_delivery_logs`; pg_net stalled; Edge redeploy + smoke test; reset FCM tokena sa verifikacijom kroz `send_push_notification` RPC; chat/Realtime; RLS revizija sa `pg_policies` upitima i repo alatima) + redosled eskalacije i preventivne provere.
- README.md tabela dokumentacije + `PUSH_SETUP.md` povezani sa novim dokumentima.

### Added (dopuna 2026-10-24 — tačka 9: DevOps & Deploy)
- **`docs/DEPLOYMENT.md`** — deploy & rollback vodič: Cloudflare Pages pipeline, `/health.json` smoke test sa 5 pokušaja u CI, rollback procedura (re-deploy prethodnog commita), pre-commit githook, preview deploy (Firebase PR kanali).
- **Statički `/health.json`** — generiše se u `tool/prepare_cloudflare_deploy.dart` sa `status`, `version`, `commit` i `built_at`; servira se kao statički fajl bez pokretanja app koda. Pravilo u `web/_headers` (`application/json`, `s-maxage=60`).
- **Post-deploy smoke test** u `.github/workflows/deploy-cloudflare.yml` — 5 pokušaja × 20s provere da je `domacimarket.rs/health.json` dostupan i `status == "ok"`; inače workflow pada i signalizuje rollback.
- **Pre-commit githook** (`.githooks/pre-commit` + `scripts/setup_githooks.dart`) — pokreće `check_no_committed_secrets.dart` i `dart analyze --fatal-infos` pre svakog commita.

### Stats
- Test fajlovi: 127 → **134**; test slučajevi: **815 prolazi** (0 padova).

## [1.1.6+16] - 2026-10-09

### Added
- Cloudflare `<!--email_off-->` direktive oko svih `mailto:` linkova radi sprečavanja greške 404 na `/cdn-cgi/l/email-protection`.
- Vercel fallback preusmeravanje sa `/cdn-cgi/l/email-protection(.*)` na početnu stranu.
- Automatska invalidacija keša pretrage (`ProductCacheService.invalidateSearchCache()`) pri promenama proizvoda i realtime događajima.
- Skraćeni TTL za keširanje rezultata pretrage (5 minuta).
- Logovanje upozorenja (`LoggerService.warning`) u `QuantityEngine.resolveStep` ukoliko nedostaje eksplicitni `order_step`.
- Jasan offline status i obaveštenje za porudžbine u `CheckoutMultiForm`.

### Changed
- Uklonjen kompletan mrtvi `l10n` sistem (`lib/l10n/`, `l10n.yaml`, `generate: true` u `pubspec.yaml`), pošto je aplikacija 100% na srpskoj latinici sa punom podrškom za dijakritike (č, ć, ž, š, đ).
- Potvrđeno korišćenje standardnog logičkog operatora `||` u `OrderStatusFlowRules.isAllowedTransition`.
- Ažurirana dokumentacijska tabela u `README.md` sa vezama ka `SUPABASE_DATABASE.md` i `CHANGELOG.md`.

## [1.1.5] - 2026-10-08

### Added
- Nova verzija logotipa `domaci_market_logo_v2.png` sa transparentnom pozadinom.
- Podešavanja boje dugmadi u tamnoj temi (`#ffe082`).
- Nova struktura hijerarhije kategorija i integrisana podrška za male oglase.
