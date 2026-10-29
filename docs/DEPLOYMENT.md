# Deployment & rollback — Domaći Market (mleko)

Ovaj dokument opisuje kako se deploy-uje web verzija na Cloudflare Pages,
kako se vraća (rollback) prethodna verzija u slučaju incidensa, i kako se
proverava da je novi deployment zdrav (`/health.json`).

## 1. Build i deploy (automatizovano)

Pomocu GitHub Actionsa (`deploy-cloudflare.yml`):

```
push na master  →  flutter build web --release
                  →  dart run tool/prepare_cloudflare_deploy.dart   (build/cloudflare-deploy)
                  →  npx wrangler pages deploy ... --branch=main
                  →  post-deploy smoke test: https://domacimarket.rs/health.json
```

Pripremni skript (`prepare_cloudflare_deploy.dart`):

- kopira `build/web` → `build/cloudflare-deploy`
- kopira Cloudflare Pages Functions iz `functions/`
- kopira `web/.well-known`, `_headers`, `_redirects`, ikone, sitemap, robots
- generiše **statički `/health.json`** sa verzijom, commitu i vremenu gradnje
- ispisuje veličinu bundle-a

### Lokalno (bez GitHub Actionsa)

```bash
# 1. Skupljanje tajni iz Supabase (ne commitovati!)
export SUPABASE_URL="https://wvqtujpurhzraptorcvl.supabase.co"
export SUPABASE_ANON_KEY="..."

# 2. Build web-a
flutter pub get
flutter build web --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"

# 3. Priprema deploy bundla
dart run tool/copy_web_shell_assets.dart
dart run tool/prepare_cloudflare_deploy.dart

# 4. Deploy
npx wrangler pages deploy build/cloudflare-deploy \
  --project-name domacimarket --branch main \
  --token $CLOUDFLARE_API_TOKEN

# 5. Health check
curl https://domacimarket.rs/health.json
# Očekivano: {"status":"ok","app":"domaci-market","version":"1.1.6+16","commit":"abc1234","built_at":"..."}
```

Tajne se čuvaju u **GitHub Secrets** (`SUPABASE_URL`, `SUPABASE_ANON_KEY`,
`CLOUDFLARE_API_TOKEN`) — nikada u repozitorijumu
(vidi `tool/check_no_committed_secrets.dart` i `.gitignore`).
`CLOUDFLARE_ACCOUNT_ID` nije tajna (javni identifikator naloga) i stoga je
direktno definisan u `.github/workflows/deploy-cloudflare.yml`.

---

## 2. Rollback (vraćanje prethodne verzije)

Ako novi deployment proveri negdje pronaći grešku (npr. health check padne
u CI-j, ili se prijavi korisnički incident), postupak je:

### Korak 1 — Odredi koji commit želis vratiti

Deployment bundle se izgradi iz trenutnog HEAD-a `mastera`. Za rollback
vraćaš se na prethodni *dobro poznat* commit:

```bash
# Lista poslednjih deployovanih kommitova (PR je squash-ovan ili mergeovan):
git log --oneline master -10

# Primer: vraćanje na commit b5e4815 (prethodna stabilna verzija):
git checkout b5e4815
```

### Korak 2 — Rebuild i deploy starije verzije

```bash
flutter pub get
flutter build web --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"

dart run tool/copy_web_shell_assets.dart
dart run tool/prepare_cloudflare_deploy.dart

npx wrangler pages deploy build/cloudflare-deploy \
  --project-name domacimarket --branch main
```

Cloudflare Pages ne čuva „stare build-ove" automatski — rollback je
**re-deploy istog koda sa prethodnog commita**. To je dovoljno zato što
web verzija nije svrstana pod verzije (jedna produkcijska verzija u jednom
branču).

### Korak 3 — Proveri da je rollback uspeo

```bash
curl https://domacimarket.rs/health.json
# Proveri da se 'commit' poklapa sa za kojim vraćam, a 'status' je 'ok'.
```

Ako health check i dalje pada, problem nije u Flutter web kodu već
verovatno u Supabase-u / Edge funkcijama / Cloudflare-u — vidi
`docs/INCIDENT_RUNBOOK.md`.

---

## 3. Health endpoint (`/health.json`)

Generiše se stavom `prepare_cloudflare_deploy.dart`, bez pokretanja app
koda (čisto statički fajl,.cache-Control: `s-maxage=60`).

```jsonc
{
  "status": "ok",
  "app": "domaci-market",
  "version": "1.1.6+16",
  "commit": "abc12345",
  "built_at": "2026-10-24T10:00:00.000Z"
}
```

**Korišćenje:**

- Post-deploy smoke test u `deploy-cloudflare.yml` (5 pokušaja × 20s).
- Uptime monitoring (npr. UptimeRobot / Cloudflare monitoring) može
  pokućati ovaj endpoint.
- Ako vraća `status != "ok"` ili HTTP ≠ 200 → deployment se smatra
  neuspešnim (trigger za rollback).

---

## 4. Pre-commit githook (9.3)

Repozitorijum ima `.githooks/pre-commit` koji pokreće pre svakog
`git commit-a`:

1. `dart run tool/check_no_committed_secrets.dart` — ne dozvoljava
   `.env`, `key.properties`, `.jks`, `.keystore`, `service-account*.json`
   pod verzionom kontrolom.
2. `dart analyze --fatal-infos lib tool` — nula info/upozorenja/grešaka.

### Instalacija (jednokratno, posle kloniranja)

```bash
dart run scripts/setup_githooks.dart
```

Ovo kopira `.githooks/pre-commit` u `.git/hooks/pre-commit`.
Hook se ponegde ignoriše sa `--no-verify`, ali to se **ne preporučuje**.

---

## 5. Pre-producijsi peek (preview deploy)

Za svaki PR se pokreće `web-preview.yml` (Firebase Hosting, channel
`pr-<broj>`), što omogućava pregled promena pre merge-a u `master`.
Cloudflare Pages produkcija se deploy-uje samo nakon merge-a u `master`
kroz `deploy-cloudflare.yml`.

---

## 6. Troubleshooting deploy-a

| Simptom | Uzrok | Fix |
| :--- | :--- | :--- |
| `health.json` vraća 404 | Prepare skripta nije generisala fajl ili deploy nije poslao bundle | Pokreni `prepare_cloudflare_deploy.dart` i re-deploy-uj |
| `health.json` vraća `status != ok` | Greška pri generisanju (npr. pubspec.version nedostaje) | Proveri `pubspec.yaml` i pokreni skriptu ponovo |
| Deploy uspeo ali app se ne učitava | Cloudflare propagation (do 1–2 min) | Čekaj i pokini health check ponovo |
| Tajne nisu postavljene | `SUPABASE_URL`/`ANON_KEY` prazni | GitHub Secrets → ponovo pokreni deploy |
