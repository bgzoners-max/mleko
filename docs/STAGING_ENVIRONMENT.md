# Staging okruženje (D2)

> **Zastarelo (2026-10-30):** Vercel stack (`vercel.json`, `api/`, `.vercelignore`)
> je uklonjen iz repozitorijuma — hosting je isključivo Cloudflare Pages.
> Staging okruženje treba graditi na istom stacku: poseban Cloudflare Pages
> projekat (npr. `domacimarket-staging`) + poseban Supabase projekat, deploy kroz
> `npx wrangler pages deploy ... --branch staging`. Sekcije ispod koje opisuju
> Vercel projekat, `VERCEL_*` secret-e i `deploy-staging.yml` više nisu relevantne
> i zadržane su samo kao istorijski kontekst.

Ovaj dokument opisuje arhitekturu, postavljanje i održavanje izolovanog **Staging** okruženja za Domaći market.

---

## 1. Arhitektura

| Resurs | Produkcija | Staging |
|---|---|---|
| **Git grana** | `master` | `staging` |
| **Supabase Project Ref** | `wvqtujpurhzraptorcvl` | Novi staging ref (npr. `mleko-staging`) |
| **Vercel Project** | `mleko` | `mleko-staging` |
| **Glavni URL / Alias** | `https://domacimarket.rs` | `https://staging.domacimarket.rs` (ili `mleko-staging.vercel.app`) |
| **CI/CD Workflow** | `.github/workflows/deploy.yml` | `.github/workflows/deploy-staging.yml` |

Staging okruženje je 100% odvojeno:
- Baza podataka je nezavisna (testne narudžbine, proizvodi i nalozi ne prljaju produkciju).
- Vercel Edge Serverless funkcije (`/api/product-preview`, `/api/classified-preview`) koriste staging bazu.
- Deep linkovi i deljenje proizvoda na stagingu automatski pokazuju na staging domen zahvaljujući `SHARE_BASE_URL`.

---

## 2. GitHub Secrets konfiguracija

U GitHub repozitorijumu (**Settings -> Secrets and variables -> Actions**) konfigurišu se sledeći secret-i:

| Secret | Opis |
|---|---|
| `VERCEL_TOKEN` | *Već postoji* — tvoj lični/timski Vercel API token |
| `VERCEL_ORG_ID` | *Već postoji* — `team_HC3fIUGj1ZMlVbwoicfiCWfD` (`vrvladas-projects`) |
| `VERCEL_PROJECT_ID_STAGING` | **Novi** — Project ID iz novog Vercel projekta (`mleko-staging`) |
| `SUPABASE_URL_STAGING` | **Novi** — Staging Supabase URL (`https://<staging-ref>.supabase.co`) |
| `SUPABASE_ANON_KEY_STAGING` | **Novi** — Staging Supabase anon / public API key |
| `STAGING_BASE_URL` | *(Opciono)* — `https://staging.domacimarket.rs` (default ako se ne unese) |

---

## 3. Vercel Staging projekat — podešavanje

1. Na Vercelu kreiraj projekat pod timom `vrvladas-projects` povezan sa repozitorijumom `mleko`.
2. U **Settings -> Environment Variables** dodaj:
   - `SUPABASE_URL` = `<SUPABASE_URL_STAGING>`
   - `SUPABASE_ANON_KEY` = `<SUPABASE_ANON_KEY_STAGING>`
3. U **Settings -> General** kopiraj `Project ID` i unesi ga u GitHub Secrets kao `VERCEL_PROJECT_ID_STAGING`.
4. U **Settings -> Domains** proveri dodeljeni domen (npr. `mleko-staging.vercel.app`) ili dodaj `staging.domacimarket.rs` (postavi CNAME zapis kod DNS provajdera na `cname.vercel-dns.com`).

---

## 4. Supabase Staging baza — migracije i seed

### Prvo podizanje šeme
Da bi se na novu bazu primenile sve migracije iz `supabase/migrations/`:

```bash
# 1. Povezivanje CLI sa staging projektom
npx supabase link --project-ref <STAGING_PROJECT_REF>

# 2. Puštanje svih migracija na staging bazu
npx supabase db push
```

> **Važna napomena za Edge Functions na Stagingu:**
> Stare migracije sadrže hardkodovan `functions_base_url` za produkciju. Na novoj staging bazi, u Supabase SQL Editoru pokrenite:
> ```sql
> UPDATE public.edge_config 
> SET value = 'https://<STAGING_PROJECT_REF>.supabase.co' 
> WHERE key = 'functions_base_url';
> ```


### Povratak na produkciju u lokalnom CLI-ju
Kada želiš ponovo da povežeš CLI sa produkcijom:
```bash
npm run supabase:link:prod
```

### Punjenje testnim podacima (Seed)
Za kreiranje test prodavaca, test kupaca (`password123`) i početnih kategorija/proizvoda:
- Otvori **Supabase Dashboard -> SQL Editor** na Staging projektu.
- Nalepi sadržaj fajla `supabase/seed.sql` i pokreni (Run).
*(Nikada ne pokretati `seed.sql` na produkciji!)*

---

## 5. Radni tok (Workflow)

1. Radite na feature grani ili direktno na `staging`.
2. Push na granu `staging`:
   ```bash
   git checkout staging
   git merge master # ili tvoj feature branch
   git push origin staging
   ```
3. GitHub Actions automatski pokreće `.github/workflows/deploy-staging.yml`:
   - Kompajlira Flutter Web aplikaciju sa staging parametrima.
   - Priprema optimizovani bundle sa keš hešom.
   - Deploy-uje na Vercel staging projekat.
4. Testirate izmene na staging linku.
5. Kada je sve provereno, `staging` se spaja u `master` i ide automatski deploy na produkciju (`https://domacimarket.rs`).
