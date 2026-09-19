# Supabase baza — izvor istine i deploy

## Izvor istine

- **Šema, funkcije, triggeri, RLS** moraju živeti u repou: `supabase/migrations/*.sql`.
- **Ne dodavati** enum vrednosti, kolone ili politike samo u Supabase Dashboard-u bez odgovarajuće migracije — produkcija i `supabase db reset` će divergovati od repoa.

## Deploy migracija na projekat (produkciju)

```bash
# jednokratno: supabase link --project-ref <ref>
npx supabase db push
```

Ili preko CI / pipeline-a koji primenjuje iste migracije. Posle izmene u Flutteru koja očekuje novu šemu, **migracija mora biti primenjena** pre ili u istom release-u kao aplikacija.

## Lokalna provera

```bash
npx supabase db start   # ili puni stack po potrebi
npx supabase db reset --local --yes
```

Zatim SQL provere u `supabase/tests/` (npr. `order_status_flow_integration.sql`).

## `notifications.type`

U migracijama se koriste stringovi (kolona je u osnovi `TEXT`; na nekim hostovanim projektima kolona je tipa enum `notification_type` — vidi `20260322140100_notification_type_enum_review_values.sql`).

| Vrednost | Izvor (ukratko) |
|----------|-----------------|
| `new_order` | Nova porudžbina |
| `order_status` | Stariji trigger tekst (legacy u ranijim migracijama) |
| `order_status_changed` | Trenutni `notify_order_status_change` (status porudžbine) |
| `new_message` | Nova poruka |
| `new_review` | Nova recenzija prodavca |
| `new_buyer_review` | Recenzija kupca od strane prodavca |

Aplikacija tretira **`order_status`** i **`order_status_changed`** kao porudžbinu — vidi `lib/core/notification_types.dart`.

## Porudžbine — statusi

Definisani su u migracijama (`orders_status_check`) i u `lib/utils/order_status_flow_rules.dart` / `lib/models/order_model.dart`. Izmene moraju ići kroz migraciju + ažuriranje pravila u aplikaciji.

> **Parity guard:** `test/order_status_sql_parity_test.dart` automatski čita najnoviju migraciju koja definiše `enforce_order_status_transition()` i upoređuje dozvoljene tranzicije sa Dart pravilima. Ako se SQL i Dart raziđu, test (i CI) pada — nije dovoljno izmeniti samo jednu stranu.

### RLS na `orders`

- Jedna **UPDATE** politika za učesnike + `(SELECT auth.uid())` u izrazima: migracija **`20260322180000_orders_rls_consolidate_auth_select.sql`** (zamenjuje odvojene prodavčeve/kupčeve politike i `20260322140200_*`).
- Starija podela: `Sellers can update order status` + `Buyers can update own orders` — zamenjeno konsolidacijom radi performansi (Advisor).

Detalji o Advisor temama (RLS, indeksi, `support_tickets` na hostu): **[docs/sql/supabase_performance_rls_and_indexes.md](sql/supabase_performance_rls_and_indexes.md)**.
