# Service Grouping Plan

## Goal
Reduce service sprawl by grouping services by domain while keeping current runtime behavior unchanged.

## Current State
There are 24 files under `lib/services/`.

## Grouping Introduced
- `lib/services/auth/auth_services.dart`
- `lib/services/catalog/catalog_services.dart`
- `lib/services/communication/communication_services.dart`
- `lib/services/content/content_services.dart`
- `lib/services/core/core_services.dart`
- `lib/services/media/media_services.dart`
- `lib/services/orders/order_services.dart`
- `lib/services/social/social_services.dart`
- `lib/services/services.dart` (root barrel)

## Domain Map
- Auth: auth, users
- Catalog: products, product cache, search history, supabase queries
- Communication: chat, notifications, push, seller inbox
- Content: recipes
- Core: logger, connectivity, error handling
- Media: storage
- Orders: orders, queue, sync, background sync, analytics
- Social: favorites, favorite sellers, reviews

## Migration Strategy
1. Keep existing service files in place (done).
2. Start importing domain barrels from new/modified files (done).
3. Migrate old direct imports incrementally (done).
4. Move implementation files to domain folders in phase 2 (done).
5. Remove root-level compatibility stubs after imports are fully migrated (done).

## Suggested Rules
- UI layers import only domain barrels when possible.
- New service files must be placed in a domain group.
- Cross-domain calls should go through well-defined service APIs.

## Current Status
- Grouped imports are in use across providers/screens.
- Physical service files are grouped by domain.
- Root `lib/services/` keeps only domain folders plus `services.dart` umbrella barrel.
