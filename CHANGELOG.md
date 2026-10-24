# Changelog

Sve značajne promene na projektu **Domaći Market** (`mleko`) dokumentuju se u ovom fajlu.
Format prati [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

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
