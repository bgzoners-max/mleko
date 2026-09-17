# Android release potpisivanje (keystore + App Links)

Ovaj dokument pokriva dve povezane teme:

1. **Potpisivanje release builda** pravim keystore-om (umesto debug ključa).
2. **Digital Asset Links** (`web/.well-known/assetlinks.json`) — bez poklapanja otiska
   certifikata, `https://domacimarket.rs/...` linkovi **ne otvaraju aplikaciju**
   (Android App Links tiho padaju na browser).

## Zašto je ovo obavezno

- Google Play **odbija** AAB potpisan debug ključem.
- `debug.keystore` je vezan za konkretnu mašinu (i Android Studio instalaciju), pa se
  otisak razlikuje od računara do računara — build sa druge mašine ruši App Links.
- Android verifikuje App Links poređenjem potpisnog certifikata instaliranog APK/AAB-a
  sa `sha256_cert_fingerprints` u `assetlinks.json`.

## 1. Kreiranje keystore-a (jednom, čuvaj zauvek)

```powershell
keytool -genkeypair -v `
  -keystore android/app/upload-keystore.jks `
  -keyalg RSA -keysize 2048 -validity 10000 `
  -alias upload -storetype JKS
```

- Lozinke i fajl čuvaj u password manager-u / sigurnoj lokaciji, **nikada u repou**
  (`android/key.properties`, `*.jks` i `*.keystore` su u `.gitignore`).
- Ako izgubiš keystore, uz uključen Play App Signing možeš da zatražiš reset upload
  ključa; bez Play App Signing aplikaciju više ne možeš nadograditi.

## 2. `android/key.properties`

```powershell
Copy-Item android/key.properties.example android/key.properties
```

```properties
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=upload-keystore.jks
```

`android/app/build.gradle.kts` čita ovaj fajl i:

- ako **postoji** → release se potpisuje tim keystore-om;
- ako **ne postoji** → release se i dalje potpisuje debug ključem uz glasno upozorenje
  (da `flutter run --release` radi lokalno), osim ako je zadato
  `-PrequireReleaseSigning=true`, kada build **pada**.

## 3. Sinhronizacija `assetlinks.json`

```bash
npm run assetlinks:sync
# ili direktno:
dart run tool/sync_assetlinks.dart
```

Skripta čita `android/key.properties`, preko `keytool`-a izvlači SHA-256 i upisuje
`web/.well-known/assetlinks.json` (paket se automatski čita iz `applicationId`).

### Play App Signing (podrazumevano za nove aplikacije)

Ako je uključen Play App Signing, **instalirana** aplikacija je potpisana Google-ovim
*app signing* ključem, a ne tvojim upload ključem. Otisak app signing ključa prepiši u
assetlinks:

```bash
dart run tool/sync_assetlinks.dart --extra "AA:BB:CC:..."
```

Otisak se nalazi u Play Console → **Release → Setup → App integrity → App signing key
certificate → SHA-256 certificate fingerprint**.

## 4. Build i provera potpisa

```bash
flutter build appbundle --release

keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
```

Dobijeni `SHA256` **mora** biti identičan otisku u `web/.well-known/assetlinks.json`
(uporedi i sa `dart run tool/sync_assetlinks.dart --print-only` ako samo želiš proveru).

## 5. Verifikacija App Links na uređaju

```bash
adb shell pm verify-app-links --re-verify com.mleko.mleko
adb shell pm get-app-links com.mleko.mleko
```

Status treba da bude `verified` za host `domacimarket.rs`. Ako nije, proveri da je
`assetlinks.json` dostupan na `https://domacimarket.rs/.well-known/assetlinks.json`
(deploy ide kroz `npm run vercel:deploy`, koji validira i kopira `.well-known`).

## 6. CI

- `dart run tool/check_no_committed_secrets.dart` — pada ako je `key.properties` ili
  keystore greškom commitovan (pokreće se u `.github/workflows/ci.yml`).
- Za release build u CI-ju: `flutter build appbundle --release -PrequireReleaseSigning=true`
  uz keystore i `key.properties` obezbeđene kroz GitHub Secrets.

## 7. Česti problemi

| Simptom | Uzrok / rešenje |
| :--- | :--- |
| Play odbija AAB: „not signed with a release key" | `android/key.properties` ne postoji ili je neispravan |
| App Links se otvaraju u browseru | Otisak u `assetlinks.json` ≠ potpisni certifikat; pokreni `npm run assetlinks:sync` |
| Radi na mojoj mašini, ne radi na drugoj | Build je potpisan debug ključem te mašine — konfiguriši pravi keystore |
| Radi lokalno, ne radi sa Play-a | Play App Signing — dodaj `--extra` otisak iz Play Console |
