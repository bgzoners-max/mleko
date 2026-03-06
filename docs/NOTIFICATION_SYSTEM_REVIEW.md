# Pregled sistema notifikacija

## Tok podataka

```
[Trigger] → notifications (INSERT) → invoke_send_push (pg_net) → Edge Function send-push → FCM → uređaj
```

---

## 1. Baza podataka

### Tabele

| Tabela | Namena |
|--------|--------|
| `notifications` | In-app obaveštenja + izvor za push (trigger na INSERT) |
| `user_push_tokens` | FCM tokeni po korisniku (više uređaja) |
| `edge_config` | `functions_base_url`, `anon_key` za poziv Edge Function |

### Triggeri koji ubacuju u `notifications`

| Trigger | Tabela | Tip | Primaoc |
|---------|--------|-----|---------|
| `on_new_order` | orders (INSERT) | new_order | prodavac |
| `on_order_status_change` | orders (UPDATE) | order_status | kupac |
| `on_new_message` | messages (INSERT) | new_message | drugi učesnik razgovora |

### Trigger na `notifications`

- `on_notification_insert_send_push` → poziva `invoke_send_push()` → `net.http_post` na Edge Function

### Zahtevi

- **pg_net** extension mora biti uključen (Dashboard → Database → Extensions)
- Za produkciju: `UPDATE edge_config` sa pravim `functions_base_url` i `anon_key`

---

## 2. Edge Function `send-push`

- **Ulaz:** `user_id`, `title`, `body`, `type`, `order_id` (iz body ili body.record)
- **Logika:** čita token(e) i platform iz `user_push_tokens`, šalje FCM v1 za svaki token
- **Secret:** `FCM_SERVICE_ACCOUNT_JSON` (base64 ili raw JSON)
- **Android payload:** `notification` + `data` + `android` (channel_id: mleko_push, priority: high, sound, visibility)
- **iOS payload:** `notification` + `data` + `apns` (alert, sound, badge)

---

## 3. Flutter (Android)

### PushService

- `initialize()` – zahteva dozvolu (Android 13+), registruje background handler
- `registerToken(userId)` – upisuje FCM token u `user_push_tokens` (poziva se pri loginu)
- `unregisterToken(userId)` – briše token pri odjavi (poziva se u `AuthService.signOut()` pre `signOut`)
- `setMessageOpenedHandler` – navigacija pri tapu na notifikaciju
- `getInitialMessage` – app pokrenut iz notifikacije

### MainActivity (Android)

- Kanal `mleko_push` – IMPORTANCE_HIGH, zvuk, vibracija, badge, VISIBILITY_PUBLIC

### AndroidManifest

- `POST_NOTIFICATIONS`
- `com.google.firebase.messaging.default_notification_channel_id` = mleko_push

---

## 4. Navigacija po tipu

| type | Odredište |
|------|-----------|
| new_order, order_status | /orders |
| new_message | /conversations |

---

## 5. Provera liste

- [ ] pg_net uključen
- [ ] edge_config postavljen (produkcija)
- [ ] FCM_SERVICE_ACCOUNT_JSON secret
- [ ] google-services.json u android/app/
- [ ] Migracije primenjene (uključujući notify_order_status_change)
- [ ] Edge Function deploy: `supabase functions deploy send-push`

---

## 6. Optimizacija po platformi

### Xiaomi / Huawei / Oppo / Samsung
- **Optimizacija baterije:** Obaveštenja → meni (⋮) → „Optimizacija baterije (Xiaomi, Huawei...)“ – otvara dijalog za isključivanje optimizacije
- **Pomoć:** „Pomoć: obaveštenja ne stižu“ – link na dontkillmyapp.com
- **Autostart (Xiaomi):** Postavke → Aplikacije → Autostart → uključi za Naše Selo
- **Baterija:** Postavke → Baterija → Izaberi aplikacije → Naše Selo → „Bez ograničenja“

### iOS
- APNs certifikat mora biti uploadovan u Firebase Console
- GoogleService-Info.plist u ios/Runner/

### Android (standardni)
- Kanal mleko_push sa zvukom i vibracijom
- Heads-up: Postavke → Aplikacije → Naše Selo → Obaveštenja → „Prikaži kao pop-up“

---

## 7. Poznate ograničenja

- **Foreground:** flutter_local_notifications prikazuje notifikacije kada je app otvoren
- **Heads-up:** Na nekim uređajima korisnik mora ručno uključiti „Prikaži kao pop-up“
- **Badge:** Android badge zavisi od launcher-a
