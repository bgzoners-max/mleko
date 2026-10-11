# Changelog

Sve značajne promene na projektu **Domaći Market** (`mleko`) dokumentuju se u ovom fajlu.
Format prati [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

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
