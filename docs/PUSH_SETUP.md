# Push notifikacije – podešavanje

**Detaljno uputstvo:** vidi [FIREBASE_SETUP.md](FIREBASE_SETUP.md)

## 1. Firebase projekat (rezime)

1. Kreiraj projekat na [Firebase Console](https://console.firebase.google.com)
2. Dodaj Android aplikaciju (package: `com.mleko.mleko`)
3. Preuzmi `google-services.json` u `android/app/`
4. Za iOS: dodaj iOS app, preuzmi `GoogleService-Info.plist` u `ios/Runner/`

## 2. FlutterFire

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Ovo generiše `lib/firebase_options.dart` sa konfiguracijom.

## 3. Android

U `android/app/build.gradle.kts` dodaj na vrh (ako nema):

```kotlin
plugins {
    id("com.google.gms.google-services")
}
```

U `android/build.gradle.kts`:

```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```

## 4. Edge Function i trigger (već implementirano)

- **Edge Function** `send-push` – prima obaveštenje, šalje FCM
- **Trigger** – na INSERT u `notifications` poziva Edge Function
- **Konfiguracija** – tabela `edge_config`:
  - `functions_base_url` – za lokal: `http://host.docker.internal:54321`, za produkciju: `https://YOUR_REF.supabase.co`
  - `anon_key` – anon key za autorizaciju poziva

### FCM Service Account (v1 API)

Legacy Server key je ugašen. Koristi Service Account:
Firebase Console → Project Settings → Service accounts → Generate new private key.
Preuzeti JSON stavi u secret `FCM_SERVICE_ACCOUNT_JSON`.

### Produkcija

1. Pokreni migracije: `supabase db push`
2. Postavi secret (base64 – vidi FIREBASE_SETUP.md):
3. Ažuriraj config:
```sql
UPDATE public.edge_config SET value = 'https://YOUR_PROJECT_REF.supabase.co' WHERE key = 'functions_base_url';
UPDATE public.edge_config SET value = 'YOUR_ANON_KEY' WHERE key = 'anon_key';
```
