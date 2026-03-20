# Contributing

Hvala na doprinosu projektu `mleko`.

## Brzi start

```bash
flutter pub get
flutter analyze
flutter test
```

## Service Layer konvencije

Service kod je grupisan po domenima u `lib/services/`:

- `auth/`
- `catalog/`
- `communication/`
- `core/`
- `media/`
- `orders/`
- `social/`

Koristi domen barrel import-e kad god je moguce, npr:

```dart
import '../services/catalog/catalog_services.dart';
```

Dozvoljen je i umbrella barrel:

```dart
import '../services/services.dart';
```

Nemoj koristiti legacy root import putanje tipa:

```dart
import '../services/products_service.dart';
import '../services/orders_service.dart';
```

## Import guard (obavezno)

Pokreni checker pre push-a:

```bash
dart run tool/check_service_imports.dart
```

Opciono — heuristika za nove Supabase migracije (`SECURITY DEFINER` + `p_*_id`):

```bash
dart run tool/scan_security_definer_migrations.dart
```

(vidi [docs/SECURITY_DEFINER_RPC.md](docs/SECURITY_DEFINER_RPC.md))

Ako checker prijavi gresku, prepravi import-e na domain barrel ili `services.dart`.

## Pre-PR checklist

- [ ] `dart run tool/check_service_imports.dart` prolazi
- [ ] `flutter analyze` prolazi bez gresaka
- [ ] Relevantni testovi prolaze (`flutter test`)
- [ ] Nema novih legacy import-a iz `lib/services/*.dart` root nivoa

## Supabase (URL i anon ključ)

- U kodu postoji fallback u `lib/supabase_config.dart`.
- Za build bez hardkodovanih vrednosti koristi `.env.example` kao šablon i:
  - `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`

## Migracije (solo, drift, bez Docker-a)

Kratko uputstvo: [docs/MIGRATIONS_SOLO.md](docs/MIGRATIONS_SOLO.md).

## Supabase RPC (SECURITY DEFINER)

Novi ili izmenjeni RPC-ovi: vidi [docs/SECURITY_DEFINER_RPC.md](docs/SECURITY_DEFINER_RPC.md) — `DEFINER` zaobilazi RLS; parametri moraju da se poklope sa `auth.uid()` gde podaci nisu javni.

## Napomena

CI (`.github/workflows/ci.yml`) vec proverava:

- service import policy
- static analysis
- test suite
