# Deployment & Hosting Rules (Cloudflare Pages Canon)

> **STRICT RULE**: Cloudflare Pages je **jedina i isključiva** produkcijska platforma za hosting i deployment web verzije aplikacije Naše Selo (`domacimarket.rs` / `domacimarket.pages.dev`).
> **Vercel je trajno ukinut i zabranjen za deploy.** Nikada nemoj predlagati niti pokretati deploy na Vercel.

---

### 1. Produkcijski projekat i nalozi
- **Platforma**: Cloudflare Pages
- **Projekat**: `domacimarket`
- **Produkcijski domeni**:
  - `https://domacimarket.rs`
  - `https://www.domacimarket.rs`
  - `https://domacimarket.pages.dev`
- **Wrangler nalog**: `bgzoners@gmail.com` (Account ID: `11626edfa0823bc02363325d0792c18f`)
- **Produkcijska grana**: `main`

---

### 2. Komande za Deployment
- **Kompletan build i deploy (preporučeno)**:
  ```bash
  npm run deploy:all
  ```
  Ova komanda automatski:
  1. Kompajlira Flutter Web release bundle bez tree-shaking ikonica (`flutter build web --release --no-tree-shake-icons`).
  2. Kopira shell assete (`dart run tool/copy_web_shell_assets.dart`).
  3. Priprema optimizovani Cloudflare deploy bundle sa `_headers`, `_routes.json`, `.well-known` i Pages funkcijama (`dart run tool/prepare_cloudflare_deploy.dart`).
  4. Pokreće Wrangler Pages deploy (`npx wrangler pages deploy build/cloudflare-deploy --project-name domacimarket --branch main`).

- **Deploy već kompajliranog web bundle-a**:
  ```bash
  npm run pages:deploy
  ```

---

### 3. Zabrana Vercela
- Sve Vercel skripte (`vercel:deploy`, `vercel:prepare`) su dekomisionirane i vraćaju grešku.
- Bilo kakav Vercel CLI poziv (`vercel deploy`, `vercel build`) je strogo zabranjen.
