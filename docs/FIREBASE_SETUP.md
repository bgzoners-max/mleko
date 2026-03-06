# Firebase – korak po korak za push notifikacije

## Korak 1: Kreiraj Firebase projekat

1. Otvori [Firebase Console](https://console.firebase.google.com)
2. Klikni **„Dodaj projekat“** / **„Add project“**
3. Unesi ime (npr. „Mleko“) i klikni **Dalje**
4. Isključi Google Analytics ako ne treba (opciono)
5. Klikni **„Kreiraj projekat“**

---

## Korak 2: Dodaj Android aplikaciju

1. Na početnoj stranici projekta klikni ikonu **Android**
2. Unesi **Android package name:** `com.mleko.mleko` (mora tačno da odgovara `applicationId` u `build.gradle.kts`)
3. App nickname (opciono): „Mleko“
4. Klikni **„Registruj aplikaciju“**
5. Preuzmi **`google-services.json`**
6. Kopiraj fajl u folder `android/app/` (pored `build.gradle.kts`)
7. Klikni **„Dalje“** → **„Dalje“** → **„Nastavi na konzolu“**

---

## Korak 3: Service Account (za FCM HTTP v1 API)

Legacy Server key je ugašen od jula 2024. Koristi se **Service Account**:

1. U Firebase Console klikni **zupčanik** → **Postavke projekta**
2. Otvori tab **„Service accounts“**
3. Klikni **„Generate new private key“** → **„Generate key“**
4. Preuzme se JSON fajl – **čuvaj ga na sigurnom mestu**
5. Ovaj JSON treba da staviš u Supabase secret `FCM_SERVICE_ACCOUNT_JSON`

---

## Korak 4: FlutterFire (generiše firebase_options.dart)

1. U terminalu:
```bash
dart pub global activate flutterfire_cli
```
2. U root folderu projekta:
```bash
flutterfire configure
```
3. Izaberi Firebase projekat (ako ima više)
4. Izaberi platforme: Android (i iOS ako radiš i na iOS)
5. Nastane fajl `lib/firebase_options.dart`

---

## Korak 5: Android – Google Services plugin

### 5a. `android/settings.gradle.kts`

Dodaj plugin u `plugins` blok:

```kotlin
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false  // DODAJ
}
```

### 5b. `android/app/build.gradle.kts`

Dodaj plugin na vrh:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // DODAJ
}
```

---

## Korak 6: Inicijalizacija Firebase u Flutter

U `lib/main.dart` već postoji:

```dart
try {
  await Firebase.initializeApp();
  await PushService.initialize();
} catch (_) { }
```

Za produkciju zameni sa:

```dart
import 'firebase_options.dart';

// ...

await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
await PushService.initialize();
```

(ukloni `try/catch` ako želiš da vidiš greške)

**Napomena:** `Firebase.initializeApp()` bez opcija može raditi u debug modu. Ako dobijеš grešku, dodaj `firebase_options.dart` kao gore.

---

## Korak 7: Supabase – Service Account JSON

Supabase očekuje `NAME=VALUE`. Za JSON koristi **base64**:

```powershell
# Windows (PowerShell)
$json = [System.IO.File]::ReadAllText("D:\mleko\mleko-686eb-firebase-adminsdk-fbsvc-a320b8c869.json")
$b64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($json))
supabase secrets set "FCM_SERVICE_ACCOUNT_JSON=$b64"
```

```bash
# Linux/Mac
supabase secrets set "FCM_SERVICE_ACCOUNT_JSON=$(base64 -w0 path/to/service-account.json)"
```

Edge Function automatski dekoduje base64.

---

## Korak 8: Test

1. Pokreni app: `flutter run`
2. Prijavi se (token se upisuje u `user_push_tokens`)
3. Napravi porudžbinu ili pošalji poruku
4. Proveri da li stiže push notifikacija

---

## Rezime fajlova

| Fajl | Šta radi |
|------|----------|
| `google-services.json` | U `android/app/` – konfiguracija za Android |
| `lib/firebase_options.dart` | Generiše `flutterfire configure` |
| `FCM_SERVER_KEY` | Supabase secret – za slanje push-a |

---

## Česte greške

- **„Default FirebaseApp is not initialized“** – nisi pokrenuo `Firebase.initializeApp()` ili nemaš `firebase_options.dart`
- **„google-services.json is missing“** – fajl mora biti u `android/app/`
- **Package name mismatch** – `com.mleko.mleko` mora biti isti u Firebase i u `build.gradle.kts`
