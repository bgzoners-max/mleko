# send-push — Edge Function (API referenca)

Šalje FCM (HTTP v1) push notifikacije registrovanim uređajima korisnika.
Setup tajni i Vault konfiguraciju vidi u [docs/PUSH_SETUP.md](../../../docs/PUSH_SETUP.md) —
ovde je **ugovor zahteva/odgovora** i operativni detalji.

## Tok (arhitektura)

```
DB: INSERT INTO notifications
 └─ TRIGGER on_notification_insert_send_push → invoke_send_push() (pg_net HTTP POST)
     └─ POST /functions/v1/send-push  (service_role autorizacija)
         └─ user_push_tokens → FCM v1 messages:send (batch ≤ 100)
             └─ push_delivery_logs (status svakog pokušaja)
```

Direktan poziv (bez triggera) je takođe podržan — npr. iz admin alata.

## Autorizacija (obavezno `Authorization: Bearer <token>`)

| Token | Ponašanje |
| :--- | :--- |
| `SUPABASE_SERVICE_ROLE_KEY` (tačno poklapanje) | Sistemski pristup — sme slati bilo kome (ovako zove DB trigger) |
| JWT potpisan `SUPABASE_JWT_SECRET`, `role = service_role` | Sistemski pristup (kao iznad) |
| JWT `role = authenticated` | **Sme slati isključivo sebi** (`sub == user_id`), inače `403` |
| Nepotpisan / neispravan / bez headera | `401` |

CORS: `https://domacimarket.rs`, `https://www.domacimarket.rs`
(plus `http://localhost:3000/8080` kada je `ENVIRONMENT=development`).

## Request

`POST /functions/v1/send-push` — `Content-Type: application/json`.

### Oblik 1: direktni poziv

```jsonc
{
  "user_id": "uuid-korisnika",        // OBAVEZNO
  "title": "Status porudžbine 📦",    // opciono — auto-po-tipu ako je "Obaveštenje"
  "body":  "Vaš sir je poslat.",      // tekst poruke (lockscreen, max 88 znakova)
  "type":  "order_status",            // new_order|order_status|new_message|new_review|...
  "notification_id": "...",           // opciono — za dedup/prikaz u Notification Center-u
  "order_id": "", "conversation_id": "", "ticket_id": "", "classified_ad_id": "",
  "route": "/orders/xyz",             // opciono — deep-link pri tapu (whitelist u app-u)
  "data": { "custom_key": "vrednost" } // opciono — dodata u FCM data payload
}
```

### Oblik 2: trigger/webhook (`body.record` — red iz tabele `notifications`)

Ista polja, ali ugnježdena pod `record` (tako je slao stari `invoke_send_push`):
`record.user_id/title/body/type/id/created_at/order_id/conversation_id/ticket_id/classified_ad_id/route`.

### Auto-personalizacija naslova

Ako je `title` prazan ili `"Obaveštenje"`/`"Notification"`, postavlja se po tipu:

| `type` | Naslov |
| :--- | :--- |
| `new_order` | Nova porudžbina 🛒 |
| `order_status`, `order_status_changed` | Status porudžbine 📦 |
| `new_message` | Nova poruka 💬 |
| `new_review`, `new_buyer_review` | Nova recenzija ⭐ |

## Response

| Status | Body | Kada |
| :--- | :--- | :--- |
| `200` | `{"message":"OK","sent":N,"errors":[...],"request_id":"uuid"}` | Uspeh (`errors` prazan) ili delimičan uspeh |
| `200` | `{"message":"No push tokens","sent":0,"token_count":0}` | Korisnik nema registrovane tokene (nije greška) |
| `400` | `{"error":"Invalid JSON body"}` / `{"error":"Request body is required"}` / `{"error":"user_id required"}` | Loš body |
| `401` | `{"error":"Missing or invalid authorization header"}` | Nema/neispravan Bearer token |
| `401` | `{"error":"Unauthorized: Signature verification required"}` | Token se ne poklapa sa service_role key, a `SUPABASE_JWT_SECRET` nije podešen |
| `403` | `{"error":"Forbidden: insufficient permissions"}` | JWT bez odgovarajuće role |
| `403` | `{"error":"Forbidden: cannot send push notifications to other users"}` | `authenticated` korisnik pokušava slati tuđem `user_id` |
| `500` | `{"error":"FCM not configured"}` | Nije postavljen `FCM_SERVICE_ACCOUNT_JSON` |
| `500` | `{"error":"<detalj>"}` | Neočekivana greška (logovana) |

Svaki pokušaj se upisuje u `public.push_delivery_logs`
(`request_id, user_id, title, type, token_count, sent_count, failed_count, status
= success|partial|error|no_tokens|invalid_request, errors, payload`).

## Ponašanje po platformi

- **Android**: `priority: HIGH`, kanal `orders_high_v2` (porudžbine) ili
  `mleko_urgent_v2` (ostalo), `visibility: PUBLIC`, `ttl: 86400s`, ikona `ic_notification`.
- **iOS**: `apns-priority: 10`, badge/sound, lockscreen body sečen na granici reči
  (max 88 znakova + `...`).
- Svi polja idu i u `data` payload (data-only poruke rade i u background handleru).
- Neispravni tokeni (FCM `404` / `UNREGISTERED` / `INVALID_ARGUMENT`) se brišu iz
  `user_push_tokens` u chunk-ovima od 50. FCM `401` invalidira keš access tokena.

## Environment (Supabase secrets)

| Varijabla | Namena |
| :--- | :--- |
| `FCM_SERVICE_ACCOUNT_JSON` | Firebase service account (JSON ili base64) — **obavezno** |
| `SUPABASE_SERVICE_ROLE_KEY` | Autorizacija poziva + service klijent ka bazi |
| `SUPABASE_JWT_SECRET` | Kriptografska provera JWT pozivaoca |
| `SUPABASE_URL` | URL Supabase projekta |
| `LOG_LEVEL` | `debug|info|warn|error` (default `info`) |
| `ENVIRONMENT` / `ALLOW_LOCAL_CORS` | `development` dodaje localhost CORS origine |

## Primer poziva

```bash
# Direktan poziv (service_role key — ovako zove i DB trigger)
curl -X POST "https://wvqtujpurhzraptorcvl.supabase.co/functions/v1/send-push" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
        "user_id": "3f2b8c1a-9d4e-4f7b-b2c1-8e9f0a1b2c3d",
        "title": "Status porudžbine 📦",
        "body": "Vaša porudžbina je prihvaćena od strane gazdinstva",
        "type": "order_status",
        "order_id": "11111111-2222-3333-4444-555555555555",
        "route": "/orders/active"
      }'
# → {"message":"OK","sent":2,"errors":[],"request_id":"..."}
```

> Pošalji push **samo sebi** iz app koda (anon JWT korisnika):
> isti body, ali `Authorization: Bearer <korisnički JWT>` i `user_id` mora biti
> svoj `auth.uid()` — inače sledi `403`.

## Testovi i provere

```bash
deno check --config supabase/functions/deno.json supabase/functions/send-push/index.ts
deno test supabase/functions/send-push/push_helpers.test.ts   # 15 unit testova
```

Obe komande pokreće CI (`db-integration-checks` job). Health-check SQL
(produkcija): `push_health_summary()`, `push_health_dashboard`,
`push_health_user_issues` — vidi [docs/INCIDENT_RUNBOOK.md](../../../docs/INCIDENT_RUNBOOK.md).
