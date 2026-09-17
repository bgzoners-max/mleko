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

## Supabase baza (migracije i produkcija)

- Izvor istine za šemu, trigere, RLS i funkcije je **`supabase/migrations/`** — izmene u Dashboard-u bez migracije dovode do drifta.
- Deploy na projekat: `npx supabase db push` (nakon `supabase link`).
- Detalji i tabela `notifications.type`: **[docs/SUPABASE_DATABASE.md](docs/SUPABASE_DATABASE.md)**.

Nemoj koristiti legacy root import putanje tipa:

```dart
import '../services/products_service.dart';
// Umesto toga: import iz domena (npr. orders/order_services.dart) ili package:mleko/services/services.dart
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

Checker skenira `lib/` i `test/` (i `integration_test/` ako taj folder postoji).

**CI na GitHubu pade na `import guard`, a lokalno prolazi?**  
Verovatno grana nema poslednji `master` — uradi `git fetch` i `git merge origin/master` (ili rebase), pa push. Na `master` je ispravka legacy importa u commitu `6390255` i novijim.

## Pre-PR checklist

- [ ] `dart run tool/check_service_imports.dart` prolazi
- [ ] `flutter analyze` prolazi bez gresaka
- [ ] Relevantni testovi prolaze (`flutter test`)
- [ ] Nema novih legacy import-a iz `lib/services/*.dart` root nivoa

## Supabase (URL i anon ključ)

- U kodu postoji podrazumevana konfiguracija u `lib/supabase_config.dart`.
- Za override (npr. sopstveni projekat ili CI/CD):
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
