# 🔍 Analiza Push Notifikacija – Pronađeni Problemi i Rešenja

## 📋 Rezime

Pronašao sam **nekoliko kritičnih problema** koji sprečavaju prikaz push notifikacija. Svi su ispravljeni.

---

## 🐛 Problem 1: Background Handler Ignoriše Notifikacije

**Fajl:** `lib/services/communication/push_service.dart` (linija 87)

### Šta je bilo pogrešno:
```dart
if (message.notification != null) return;  // ❌ KRIVO!
```

Ovaj kod kaže: "Ako poruka IMA notifikaciju iz FCM, ignoriši je i nemoj da je obradi." To je suprotno od onoga što trebalo!

### Šta je ispravljeno:
```dart
// Sada se koriste OBA izvora - notification i data payload
final data = message.data.isNotEmpty ? message.data : <String, dynamic>{};
final title = message.notification?.title ?? data['title'] ?? 'Obaveštenje';
final body = message.notification?.body ?? data['body'] ?? '';
```

**Status:** ✅ ISPRAVLJENO

---

## 🐛 Problem 2: Foreground Handler Ignoriše Notifikacije

**Fajl:** `lib/services/communication/push_service.dart` (linija 348)

### Šta je bilo pogrešno:
```dart
final title = data['title'] as String? ?? 'Obaveštenje';  // Ignoriše notification.title
```

Kod je ekstraktovao podatke samo iz `message.data`, ignorirajući `message.notification` koje FCM šalje.

### Šta je ispravljeno:
```dart
final title = message.notification?.title ?? data['title'] ?? 'Obaveštenje';
final body = message.notification?.body ?? data['body'] ?? '';
```

**Status:** ✅ ISPRAVLJENO

---

## 🐛 Problem 3: iOS Notifikacije Nisu Pravilno Inicijalizovane

**Fajl:** `lib/services/communication/push_service.dart` (linija 124)

### Šta je bilo pogrešno:
- iOS dozvole su traživane ali bez pravilne inicijalizacije
- Kanali nisu kreirani za iOS (ne trebaju, jer iOS koristi drugačiji sistem)
- DarwinInitializationSettings nije imao flag za zahtevanje dozvola

### Šta je ispravljeno:
```dart
const darwin = DarwinInitializationSettings(
  requestAlertPermission: true,
  requestBadgePermission: true,
  requestSoundPermission: true,  // Zatraži dozvole prilikom inicijalizacije
);
await FirebaseMessaging.instance.requestPermission(
  alert: true,
  badge: true,
  sound: true,
  provisional: false,  // Zahtevaj eksplicitnu dozvolu, ne samo privremenu
);
```

**Status:** ✅ ISPRAVLJENO

---

## 🐛 Problem 4: Android Dozvole Nisu Traživane pri Inicijalizaciji

**Fajl:** `lib/services/communication/push_service.dart` (linija 130)

### Šta je bilo pogrešno:
Android dozvole za notifikacije nisu traživane pri inicijalizaciji, što znači da aplikacija neće imati dozvolu za prikazivanje notifikacija.

### Šta je ispravljeno:
```dart
// Zatraži Android notifikacijske dozvole
final status = await Permission.notification.status;
if (status.isDenied || status.isRestricted) {
  await Permission.notification.request();
}
```

**Status:** ✅ ISPRAVLJENO

---

## 📡 Serverski Sistem (Edge Function)

### Šta je OK:
1. **send-push Edge Function** pravilno koristi FCM HTTP v1 API
2. **Kanali** su ispravno konfigurirani:
   - `mleko_urgent` za obične poruke
   - `orders_high` za porudžbine
3. **Trigger** pravilno poziva send-push funkciju kada se notifikacija unese

### Šta sam Poboljšao:
Dodao sam detaljno logovanje u send-push funkciju za dijagnostiku:

```typescript
console.log("FCM: Primljena zahteva:", {...})
console.log("FCM: Pretraga tokena:", {...})
console.log(`FCM: Slanje notifikacije (${platform}):`, {...})
```

**Status:** ✅ POBOLJŠANO

---

## 🔧 Kako Testirati Push Notifikacije

### 1. Kreiraj Test Notifikaciju
```sql
-- Pronađi korisnika sa tokenom i kreiraj test notifikaciju
SELECT * FROM user_push_tokens LIMIT 5;

-- Kreiraj test notifikaciju za tog korisnika
INSERT INTO notifications (user_id, type, title, body)
VALUES (
  'USER_ID_OVDE',
  'test_notification',
  '🧪 Test Notifikacija',
  'Ako vidite ovu notifikaciju, sistem radi!'
);
```

### 2. Proverite Logove
- **Flutter aplikacija:** Logove će pisati sa prefixom `[PushService]`
- **Supabase Edge Function:** Logove vidite u `Functions` → `send-push` → `Logs`

### 3. Proverite Registrovane Tokene
```sql
SELECT user_id, platform, token, COUNT(*) as token_count
FROM user_push_tokens
GROUP BY user_id, platform, token;
```

---

## 📊 Tok Notifikacija

```
1. Korisnik se prijavi
   ↓
2. registerToken() se poziva → Token se šalje u Firebase i sprema u DB
   ↓
3. Notifikacija se kreira u DB (npr. iz novog reda u orders)
   ↓
4. Trigger invoke_send_push() se pokreće
   ↓
5. send-push Edge Function je pozvan
   ↓
6. send-push pronalazi sve tokene korisnika iz DB
   ↓
7. FCM HTTP v1 API se poziva za svaki token
   ↓
8. FCM šalje notifikaciju na uređaj
   ↓
9. Ako je app u background-u:
   - Firebase prikazuje notifikaciju
   - _firebaseMessagingBackgroundHandler se pokreće
   - Aplikacija prikazuje lokalnu notifikaciju sa kanalom

10. Ako je app u foreground-u:
    - setForegroundHandler callback se pokreće
    - Aplikacija prikazuje lokalnu notifikaciju
```

---

## ✅ Checklist za Verifikaciju

- [ ] Korisnik se uspešno prijavi
- [ ] `registerToken()` log pokazuje "Got valid token, uploading to database"
- [ ] Redak postoji u `user_push_tokens` tabeli sa PO JEDNIM tokenom
- [ ] Kreiraj test notifikaciju iz SQL-a
- [ ] send-push Edge Function logovi pokazuju "Slanje notifikacije"
- [ ] Aplikacija prikazuje push notifikaciju
- [ ] Tap na notifikaciju vodi na odgovarajući ekran

---

## 🔌 Ako Dalje Ne Radi

### Problem: Nema tokena u `user_push_tokens`
```
Razlozi:
1. Notifikacijske dozvole nisu odobrene
2. Firebase nije pravilno inicijalizovan
3. Google Play Services nije instaliran na uređaju
4. `registerToken()` nije pozvan (proverite logove)
```

### Problem: Token je u bazi ali nema notifikacije
```
Razlozi:
1. send-push funkcija nije pozvana (proverite triggers)
2. FCM_SERVICE_ACCOUNT_JSON nije pravilno konfiguriran
3. edge_config ne pokazuje na ispravan URL
4. Token je istekao (može se desiti nakon ~30 dana)
```

### Problem: Notifikacija je poslata ali se ne prikazuje
```
Razlozi:
1. Kanali nisu kreirani (ispravljeno u kodu)
2. Dozvole nisu odobrene (ispravljeno u kodu)
3. Aplikacija je ugašena/unistalled
4. Notifikacijski kanali su mutovani na uređaju
```

---

## 📝 Fajlovi Koji Su Promenjeni

1. ✅ `lib/services/communication/push_service.dart` – Sve tri kritične ispravke
2. ✅ `supabase/functions/send-push/index.ts` – Dodano logovanje
3. ✅ `supabase/migrations/20260326_test_push_notifications.sql` – Test skriptura

---

## 🚀 Sledeći Koraci

1. **Deployiraj ispravke:**
   ```bash
   flutter clean
   flutter pub get
   flutter run  # ili build za production
   ```

2. **Deployiraj Edge Function:**
   ```bash
   supabase functions deploy send-push
   ```

3. **Testiraj sa test notifikacijom** koristeći SQL skriptu

4. **Proverite logove** u Edge Function sekciji

5. **Ako i dalje ne radi, prikupi logove** i analiziraj gde se proces prekida
