# Web performanse — Lighthouse baseline

Poslednje merenje: **2026-11-16**, commit `0fcaf672` (posle izdvajanja `js/app-shell.js`
iz `web/index.html`), produkciona adresa `https://www.domacimarket.rs/`.

## Metodologija (reprodukovanje)

```powershell
$env:CHROME_PATH = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
npx --yes lighthouse https://www.domacimarket.rs `
  --output=json --output-path=build/lh-mobile.json `
  --form-factor=mobile --screen-size=mobile --throttling-method=simulate `
  --chrome-flags='--headless=new' --quiet
```

Napomena: PSI API (`pagespeedonline`) više ne radi bez API ključa (quota 0/day),
zato se koristi lokalni Lighthouse CLI nad sistemskim Chromeom.

## Rezultati (mobile, simulate throttling)

| Metrika | Vrednost | Cilj (docs/archive/SEO_GLOBALNI_PREDLOZI.md) |
| :--- | :--- | :--- |
| Performance score | **60** | — |
| First Contentful Paint | **1,0 s** | — |
| Largest Contentful Paint | **1,0 s** | < 2,5 s ✅ |
| Cumulative Layout Shift | **0** | < 0,1 ✅ |
| Total Blocking Time | ~7,3 s | — |
| Speed Index | 12,6 s | — |
| Time to Interactive | 35,6 s | — |

## Validacija izmene „app-shell ekstrakcija" (2026-11-16)

- `render-blocking-resources` audit: **bez nalaza** — `js/app-shell.js` (sa
  `defer`) ne blokira render.
- `js/app-shell.js?v=<build-hash>` učitava se kao 200 OK, ~3,3 kB (gzip) i servira
  se sa `Cache-Control: public, max-age=31536000, immutable` (vidi `web/_headers`,
  pravilo `/js/*`). Za razliku od `index.html` (no-cache), skripta se kešira
  trajno po build hash-u → naredni loadovi ne povlače ponovo.

## Tumačenje visokih TBT / Speed Index vrednosti

Dominantni trošak na mobile throttling (4x CPU) je parsiranje i izvršavanje
`main.dart.js` (Flutter Web canvas renderer) — poznata karakteristika platforme,
nije regresija shell-a. FCP/LCP su brzi zahvaljujući statičkom HTML sadržaju
shell-a (loading ekran + SEO fallback), koji se prikazuje pre pokretanja engine-a.

### WASM build istraživanje (2026-11-16)

- **Priprema koda završena**: `lib/core/web_seo_web.dart` i `lib/core/web_seo.dart`
  migrirani su sa `dart:html` na `package:web` (`dart.library.js_interop`). Bez
  ove izmene bi WASM build tiho koristio `web_seo_stub.dart` (no-op).
- **Probni build prošao bez grešaka** (`flutter build web --release --wasm`,
  Flutter 3.47.2, sve zavisnosti kompatibilne sa WasmGC):
  - `main.dart.wasm`: **6.091,5 KB** (~5,95 MB)
  - `main.dart.mjs`: **42,4 KB**
  - `main.dart.js` (automatski JS fallback za starije pregledače): **6.427,5 KB** (~6,28 MB)
  - Svi izlazi su ispod Cloudflare Pages limita od 25 MiB po fajlu; `skwasm` se
    i dalje učitava sa Google CDN-a.
- **CSP i headers**: u `web/_headers` dodati `'wasm-unsafe-eval'` u `script-src`
  i `Content-Type`/`Cache-Control` pravila za `/main.dart.wasm` i `/main.dart.mjs`.
- **Napomene pre produkcionog uključivanja `--wasm` flaga**:
  1. **Single-threaded vs multi-threaded `skwasm`**: multi-threaded zahteva
     `COOP: same-origin` i `COEP: require-corp`, što bi moglo da blokira eksterne
     slike/tajlove (`tile.openstreetmap.org`, Google Fonts, itd.) bez
     `Cross-Origin-Resource-Policy: cross-origin`; bez `COOP`/`COEP` `skwasm`
     bezbedno radi u single-threaded režimu.
  2. **Hash-ovanje za keš**: `web/flutter_bootstrap.js` i
     `tool/prepare_cloudflare_deploy.dart` trenutno dodaju `?v=<buildHash>` samo
     na `mainJsPath` — za produkcioni WASM trebalo bi na isti način verzionisati i
     `mainWasmPath` i `jsSupportRuntimePath` (`main.dart.wasm?v=...`,
     `main.dart.mjs?v=...`).
- **Ostala preporuka**: PageSpeed API ključ u CI tajnama ukoliko se poželi automatsko praćenje.
