# Push notifikacije – podešavanje

**Detaljno uputstvo:** vidi [FIREBASE_SETUP.md](FIREBASE_SETUP.md)
**API ugovor Edge funkcije** (zahtev/odgovor, autorizacija, primeri):
[supabase/functions/send-push/README.md](../supabase/functions/send-push/README.md)
**Operativni incidenti** (ne stižu push-ovi, redeploy, token reset):
[INCIDENT_RUNBOOK.md](INCIDENT_RUNBOOK.md)

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

## 3b. iOS entitlements (`aps-environment`)

APNs okruženje zavisi od konfiguracije build-a, pa zato postoje **dva** entitlements fajla umesto jednog hardkodovanog:

| Konfiguracija | Fajl | `aps-environment` | Koristi se za |
| :--- | :--- | :--- | :--- |
| `Debug`, `Profile` | `ios/Runner/Runner.entitlements` | `development` | lokalni razvoj i `flutter run --profile` na uređaju |
| `Release` | `ios/Runner/RunnerRelease.entitlements` | `production` | `flutter build ipa`, TestFlight, App Store i Ad Hoc |

`CODE_SIGN_ENTITLEMENTS` je u `ios/Runner.xcodeproj/project.pbxproj` postavljen **po konfiguraciji** (`Release` → `Runner/RunnerRelease.entitlements;`), tako da se vrednost ne oslanja na naknadnu konverziju koju Xcode radi samo pri App Store exportu.

U `ios/Runner/Info.plist` mora stajati `UIBackgroundModes` sa `remote-notification` (već je podešeno) da bi iOS primao pozadinske push poruke.

> **Napomena:** `aps-environment = production` u `Release` konfiguraciji zahteva distribution/Ad Hoc provisioning profil. Za merenje performansi na sopstvenom uređaju koristi `flutter run --profile` (razvojno okruženje), jer `flutter run --release` sada traži produkcijski profil.

## 4. Edge Function i trigger (već implementirano)

- **Edge Function** `send-push` – prima obaveštenje, autorizuje se preko `service_role` ključa i šalje FCM v1
- **Trigger** – na INSERT u `notifications` poziva Edge Function preko `invoke_send_push()`
- **Konfiguracija tajni i URL-a**:
  - `service_role_key` – čuva se u **Supabase Vault-u** (koristi se za internu autorizaciju poziva funkcije)
  - `functions_base_url` – čuva se u Supabase Vault-u (ili kao fallback u `edge_config` tabeli)

### FCM Service Account (v1 API)

Legacy Server key je ugašen. Koristi se Firebase Service Account:
1. Firebase Console → Project Settings → Service accounts → Generate new private key.
2. Preuzeti JSON enkoduj u base64 i postavi u Supabase secret:

```powershell
$json = [System.IO.File]::ReadAllText("service-account.json")
$b64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($json))
supabase secrets set "FCM_SERVICE_ACCOUNT_JSON=$b64"
```

### Produkcija

1. Pokreni migracije: `supabase db push`
2. Postavi `service_role_key` u **Supabase Vault** (Dashboard → Project Settings → Vault ili preko SQL Editora):

```sql
-- Obavezno: kreiraj secret sa service_role ključem
SELECT vault.create_secret('YOUR_SUPABASE_SERVICE_ROLE_KEY', 'service_role_key');

-- Opciono: kreiraj secret za base URL ili ažuriraj edge_config
SELECT vault.create_secret('https://YOUR_PROJECT_REF.supabase.co', 'functions_base_url');
-- ILI:
UPDATE public.edge_config SET value = 'https://YOUR_PROJECT_REF.supabase.co' WHERE key = 'functions_base_url';
```

> [!WARNING]
> **Nikada ne upisujte tajne (`anon_key` ili `service_role_key`) u tabelu `edge_config`.**
> Migracija `20260911093000` je očistila plaintext ključeve iz `edge_config` i prebacila čitanje na `vault.decrypted_secrets`. Poziv `send-push` funkcije zahteva isključivo `service_role` autorizaciju.

## 5. Health check

Za brzu produkcionu proveru koristi:

```sql
SELECT * FROM public.push_health_summary();
SELECT * FROM public.push_user_health('USER_UUID'::uuid);
SELECT * FROM public.push_health_dashboard;
SELECT * FROM public.push_health_user_issues;
```

Ako summary vrati `health = 'stalled'`, proveri `pg_net` i poslednje redove u `net._http_response`.
