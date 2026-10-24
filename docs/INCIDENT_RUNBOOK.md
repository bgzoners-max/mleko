# 🚨 INCIDENT RUNBOOK — Domaći Market (mleko)

Operativni vodič za otklanjanje produkcijskih incidenata. Nije tutorial —
svaki scenario počinje simptomom, nastavlja dijagnozom i završava fix-om.

**Ključne koordinate produkcije:**

| Resurs | Vrednost |
| :--- | :--- |
| Supabase project ref | `wvqtujpurhzraptorcvl` |
| Dashboard | `https://supabase.com/dashboard/project/wvqtujpurhzraptorcvl` |
| Web (Cloudflare Pages) | `domacimarket.rs` |
| Prvi korak UVEK | [status.supabase.com](https://status.supabase.com) — nije li incident na njihovoj strani? |
| Link CLI na prod | `npm run supabase:link:prod` |

Povezana dokumentacija:
[PUSH_SETUP.md](PUSH_SETUP.md) (konfiguracija tajni) ·
[SUPABASE_DATABASE.md](SUPABASE_DATABASE.md) (deploy šeme) ·
[../supabase/functions/send-push/README.md](../supabase/functions/send-push/README.md) (API ugovor)

---

## Scenario A — „Push notifikacije ne stižu korisnicima"

### Dijagnoza (2 min)

```sql
-- 1) One-line health (prva provera)
SELECT * FROM public.push_health_summary();
-- health = 'stalled' → vidi korak A4 (pg_net)
-- health = 'degraded'/'error' → vidi A2/A3

-- 2) Da li su se notifikacije uopšte kreirale + imali li korisnik tokene?
SELECT * FROM public.push_health_user_issues;            -- korisnici sa problemima
SELECT * FROM public.push_health_dashboard;              -- dashboard pregled

-- 3) Šta je Edge funkcija odgovorila (poslednja 24h)?
SELECT request_id, user_id, type, status, token_count,
       sent_count, failed_count, errors, created_at
FROM public.push_delivery_logs
WHERE created_at > NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC
LIMIT 50;
```

Detaljna dijagnostika sekcija-po-sekcija:
`supabase/tests/push_production_diagnostics.sql` (production-safe, read-only).
U app-u: admin panel → **Push Health** ekran (`/admin/push-health`).

### A1 — `status = 'no_tokens'` (najčešće)

Korisnik nema registrovan FCM token (nema app instaliran / odbio dozvole /
token istekao). Push NIJE pao — samo nema kome da se pošalje.

- Proveri koliko tokena korisnik ima: upit #2 u `push_production_diagnostics.sql`.
- Ako je 0 za aktivnog korisnika: korisnik treba da otvori app → prijava →
  dozvola za notifikacije → token se registruje automatski
  (`PushTokenRegistrar.registerToken`).
- Ako su tokeni zastareli na MASOVnom nivou → vidi Scenario C (reset tokena).

### A2 — `status = 'error'` + `FCM_SERVICE_ACCOUNT_JSON not set` / FCM `401`

Secret je istekao/previewan ili je Firebase ključ rotiran.

```bash
# Provera postavljenih secret-a
npx supabase secrets list --project-ref wvqtujpurhzraptorcvl

# Rotacija Firebase service account ključa (Firebase Console →
# Project Settings → Service accounts → Generate new private key):
$json = [System.IO.File]::ReadAllText("service-account.json")
$b64  = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($json))
npx supabase secrets set "FCM_SERVICE_ACCOUNT_JSON=$b64" --project-ref wvqtujpurhzraptorcvl
```

> Rotacija Firebase privatnog ključa trguje 24h — stari ključ i dalje radi do isteka.

### A3 — `status = 'error'` + `401 Unauthorized` na samom `/send-push` pozivu

Trigger poziva funkciju sa zastarelim `service_role_key` iz Vault-a
(rotacija Supabase API ključeva poništava stari service_role key).

```sql
-- Provera i update vault secret-a (Dashboard → SQL Editor):
SELECT * FROM vault.decrypted_secrets WHERE name = 'service_role_key';
SELECT vault.create_secret('NOVI_SERVICE_ROLE_KEY', 'service_role_key');
-- napomena: create_secret pravi NOVI secret — obriši stari:
-- SELECT vault.delete_secret('<stari-secret-id>');
```

Vidi i [PUSH_SETUP.md](PUSH_SETUP.md) §4.

### A4 — `health = 'stalled'` (pg_net zaglavljen)

Trigger koristi `pg_net` ekstenziju za HTTP poziv. Ako je `pg_net` pao,
notifikacije se kreiraju u bazi ali Edge funkcija nikad ne bude pozvana
(**nema ni redova u `push_delivery_logs`** — ključni simptom).

```sql
-- Da li trigger pozive uopšte stigli do pg_net-a?
SELECT * FROM net._http_response ORDER BY created DESC LIMIT 10;
-- status <> 200 ili prazno → pg_net problem

-- Restart pg_net-a (bezbedno, ne briše podatke):
SELECT net.http_collect_cache();
-- Ako ne pomogne: Dashboard → Database → Extensions → pg_net → reinstall,
-- ili otvori Supabase support ticket (potencijalno infra problem na njihovoj strani).
```

---

## Scenario B — „Edge funkcija vraća 5xx / ne odgovara"

### Dijagnoza

```bash
# Logovi funkcije (poslednjih 30 dana):
npx supabase functions logs send-push --project-ref wvqtujpurhzraptorcvl
# ili Dashboard → Edge Functions → send-push → Logs
```

### Redeploy (restart funkcije)

```bash
npx supabase functions deploy send-push --project-ref wvqtujpurhzraptorcvl
```

Secret-i i Vault konfiguracija se **čuvaju** prilikom deploy-a — nije potrebno
ponovno postavljanje. Posle deploy-a verifikuj:

```bash
curl -s -o /dev/null -w "%{http_code}" -X POST \
  "https://wvqtujpurhzraptorcvl.supabase.co/functions/v1/send-push" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" -d '{"user_id":"x"}'
# 400 = funkcija živi (očekivano — "x" nije uuid); 5xx/000 = i dalje mrtva → eskaliraj
```

Ako deploy ne pomaže: proveri da secrets postoje (`npx supabase secrets list`)
i da se deploy završio bez greške. Pun API ugovor sa svim statusima:
[../supabase/functions/send-push/README.md](../supabase/functions/send-push/README.md).

---

## Scenario C — „Korisnik ne dobija push i na novom uređaju" (reset FCM tokena)

Tokeni se čuvaju u `public.user_push_tokens` (kolone: `user_id, token, platform,
installation_id`). Aplikacija automatski registruje token pri prijavi
(`PushTokenRegistrar`); ručni reset je potreban samo kad je token pasivan/zaglavljen.

```sql
-- 1) Pogledaj stanje korisnika (postojeće kolone: id, user_id, token,
--    platform, installation_id, created_at):
SELECT token, platform, installation_id, created_at
FROM public.user_push_tokens WHERE user_id = 'USER_UUID'::uuid;

-- 2) Reset: obriši sve tokene korisnika (app će registrovati svež pri sledećem otvaranju):
DELETE FROM public.user_push_tokens WHERE user_id = 'USER_UUID'::uuid;
```

Zatim korisnik: otvori app → prijavi se → prihvati notifikacije → pošalji test
notifikaciju iz admin panela ili:

```sql
-- Ručni test (kreira notifikaciju → trigger → push):
SELECT public.send_push_notification(
  p_user_id        := 'USER_UUID'::uuid,
  p_title          := 'Test push',
  p_body           := 'Ako vidite ovo, push radi.',
  p_type           := 'system'
);
```

> Masovno čišćenje zastarelih tokena radi cron posao iz migracije
> `20260326130000_push_token_cleanup_job.sql` + Edge funkcija briše
> neispravne tokene (`404/UNREGISTERED`) pri svakom slanju.

---

## Scenario D — „Chat ne radi / poruke ne stižu u realnom vremenu"

1. **Poruke se čuvaju ali ne osvežavaju uživo** → Realtime problem:
   - Dashboard → Realtime → Logs; proveri da je `messages`/`conversations`
     u Realtime publication (migracija `20260227170000_chat_orders_realtime.sql`,
     hardening `20261007080000_chat_and_realtime_hardening.sql`).
   - App koristi deliće kanale (`RealtimeChannelManager`) — RLS na
     `messages`/`conversations` mora dozvoljavati učesnicima subscribe.
2. **Poruke se ne čuvaju** → RLS/trigger problem → Scenario E.
3. **Push o novoj poruci ne stiže** → Scenario A (`type = 'new_message'`).

Brzi smoke test uz pomoć SQL Editora:

```sql
-- Da li razgovor postoji i kome pripada:
SELECT id, buyer_id, seller_id, product_id, ad_id, order_id
FROM public.conversations WHERE id = 'CONV_UUID'::uuid;

-- Da li je poruka upisana:
SELECT id, sender_id, read_at, created_at
FROM public.messages WHERE conversation_id = 'CONV_UUID'::uuid
ORDER BY created_at DESC LIMIT 5;
```

---

## Scenario E — „Korisnik ne vidi/ne može da izmeni podatke (RLS sumnja)"

### Dijagnoza

```sql
-- 1) Da li sve tabele imaju RLS uključen (rowsecurity mora biti 't',
--    a za kritične i forcerowsecurity):
SELECT schemaname, tablename, rowsecurity, forcerowsecurity
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- 2) Polise za konkretnu tabelu (simptom: koja tabela, npr. products):
SELECT policyname, cmd, roles, qual, with_check
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'products';

-- 3) Reprodukcija kao konkretan korisnik (SQL Editor → run as):
SELECT * FROM public.products LIMIT 1;  -- pokreni sa "Run as authenticated user: USER_UUID"
```

### Automatske provere (repo alati)

```bash
# Statička revizija migracija (RLS pokrivenost, permissive write, SECURITY DEFINER):
dart run tool/audit_rls_security.dart

# Heuristika za SECURITY DEFINER migracije (pokreće se i u CI):
dart run tool/scan_security_definer_migrations.dart

# Integracioni RLS test na lokalnom Supabase-u:
npx supabase start && npx supabase db reset --local --yes
psql postgresql://postgres:postgres@127.0.0.1:54322/postgres `
  -v ON_ERROR_STOP=1 -f supabase/tests/rls_security_audit_integration.sql
```

### Tipični uzroci i fix

| Simptom | Uzrok | Fix |
| :--- | :--- | :--- |
| Svi vide tuđe privatne podatke | Nedostaje `USING (auth.uid() = ...)` u polisi | Nova migracija: `DROP POLICY` + `CREATE POLICY` sa ispravnim uslovom |
| Korisnik ne može ni svoje redove | Preuska polisa / pogrešna kolona | Isti obrazac; testirati upitom #3 |
| RPC iz app-a pada sa `403` | SECURITY DEFINER funkcija bez `auth.uid()` propuštanja | Proveri `SET search_path = public` + guard; vidi [SECURITY_DEFINER_RPC.md](SECURITY_DEFINER_RPC.md) |

> RLS promene idu ISKLJUČIVO kroz novu migraciju (`supabase/migrations/`) —
> nikad direktno kroz Dashboard. Procedura: [MIGRATIONS_SOLO.md](MIGRATIONS_SOLO.md).

---

## Eskalacija i preventiva

### Redosled eskalacije

1. Ovaj runbook (dijagnoza + fix) — 15 minuta.
2. Slack/email develop timu sa: simptom, `request_id` iz `push_delivery_logs`
   (ili screenshot admin Push Health ekrana), vreme početka.
3. Supabase support (Dashboard → Support) — za infra probleme
   (pg_net, Realtime, Edge runtime); proveri da li je incident već na
   [status.supabase.com](https://status.supabase.com).
4. Za masovni zastoj: obavesti korisnike (app banner / Cloudflare Pages status).

### Preventivne provere (radi ih CI na svakom PR-u)

- `flutter analyze --fatal-infos` + 800+ testova (uključujući golden i integration E2E).
- SQL integracioni testovi: `order_status_flow_integration.sql`,
  `create_order_rpc_integration.sql` (lokalni Supabase + migracije).
- `deno check` + `deno test` za `send-push` (15 unit testova).
- Guard skripte: `audit_rls_security.dart`, `scan_security_definer_migrations.dart`,
  `check_no_committed_secrets.dart`.
- Schema drift provera: generisani `supabase/types/database.types.ts` mora
  odgovarati migracijama (CI pada na razlici).

### Ručni periodični pregled (nedeljno, 5 min)

```sql
SELECT * FROM public.push_health_summary();       -- stalled/error → Scenario A
SELECT COUNT(*) FROM public.push_delivery_logs    -- neočekivani skokovi grešaka
WHERE created_at > NOW() - INTERVAL '7 days' AND status IN ('error', 'invalid_request');
```

