# Bezbednosna politika i mrežna zaglavlja (Security & Headers)

> **Napomena (2026-10-30):** Vercel stack (`vercel.json`, `api/`) je uklonjen iz
> repozitorijuma — produkcija je isključivo na Cloudflare Pages. Sva bezbednosna
> zaglavlja sada žive u `web/_headers` (kopira se u deploy bundle kroz
> `tool/prepare_cloudflare_deploy.dart`).

## 1. Mrežna bezbednosna zaglavlja (Cloudflare Pages, `web/_headers`)

U `web/_headers` su konfigurisana sledeća bezbednosna zaglavlja za sve rute (`/*`):

- **Strict-Transport-Security (HSTS)**: `max-age=63072000; includeSubDomains; preload`
  - Prisiljava sve pretraživače da isključivo komuniciraju putem HTTPS protokola naredne 2 godine, uključujući sve poddomene.
- **X-Content-Type-Options**: `nosniff`
  - Sprečava MIME-sniffing napade.
- **X-Frame-Options**: `DENY`
  - Sprečava clickjacking i ugrađivanje aplikacije unutar `<iframe>` elemenata.
- **Referrer-Policy**: `strict-origin-when-cross-origin`
- **Permissions-Policy**: `camera=(), microphone=(), geolocation=(self), payment=()`

---

## 2. Content Security Policy (CSP) i Prihvaćen rizik (`unsafe-eval`)

### Trenutno stanje (Flutter Web CanvasKit)
U `web/_headers` CSP direktiva glasi:
```text
default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://www.gstatic.com blob:; ...
```

### Zašto je `unsafe-eval` prisutan?
Standardni Flutter Web bild (`flutter build web --release` sa `dart2js` i `CanvasKit`) interno koristi `eval` i dinamičku generaciju koda za JavaScript interop i CanvasKit WebAssembly module. Bez `unsafe-eval`, Flutter klijent se ne može inicijalizovati u veb pretraživačima.

### Prihvaćen rizik
Ovo je dokumentovan i prihvaćen arhitekturni rizik za trenutnu verziju Flutter web-a. Rizik je ublažen sledećim kontrolama:
1. `default-src 'self'` i restriktivna lista eksternih skripti (samo `self` i `gstatic.com`).
2. Stroga sanitizacija svih korisničkih unosa u pretragama i opisima (vidi `sanitizeProductSearchInput`).
3. Izolacija kolačića i nepostojanje osetljivih sesijskih tokena unutar globalnog DOM-a.

### Roadmap: Tranzicija na WASM (WasmGC)
Sa stabilizacijom Flutter Web WasmGC kompajlera (`flutter build web --wasm`):
- WasmGC uklanja potrebu za `dart2js` runtime generatorom.
- Kada se produkcijski build prebaci na WASM, `unsafe-eval` će biti uklonjen iz `script-src` u `web/_headers`.
