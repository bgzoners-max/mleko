# SECURITY DEFINER RPC-ovi (P3)

`SECURITY DEFINER` funkcije se izvršavaju sa pravima vlasnika funkcije i **zaobilaze RLS**. Svaki parametar koji određuje „čiji“ su podaci (npr. `p_user_id`, `p_seller_id`, `p_buyer_id`) mora biti usklađen sa **`auth.uid()`** (JWT pozivaoca), osim ako je namerno javan endpoint (npr. javni katalog).

## Šta je urađeno (migracija `20260321160000_security_definer_rpc_auth_guards`)

| Funkcija | Razlog |
|----------|--------|
| `get_conversations_for_user` | `p_user_id = auth.uid()` — samo sopstveni razgovori |
| `get_seller_stats_dashboard` | `p_seller_id = auth.uid()` — samo sopstvena statistika |
| `get_seller_inbox` | `p_seller_id = auth.uid()` — samo sopstveni inbox |
| `get_reviewable_order` | `p_buyer_id = auth.uid()` — samo sopstveni red za recenziju |

## Namerno javni / agregatni DEFINER RPC-ovi

- **`get_home_products`**, **`get_product_sales_counts`**, **`get_product_ratings`** — agregati/javni katalog; nisu vezani za jednog korisnika.
- **`get_seller_stats`**, **`get_seller_loyalty_stats`** — javni profil prodavca (`GRANT` uključuje `anon` gde je tako podešeno).

## Ostalo u kodu

- **`create_order_with_items`**, **`add_seller_reply`**, **`buyer_confirm_order_received`** — već proveravaju ulogu preko `auth.uid()` u telu funkcije (vidi odgovarajuće migracije).
- **`get_my_product_listing_autoflags`*** — već filtrira `WHERE seller_id = auth.uid()`.
- **Trigger funkcije** (`notify_*`, `log_order_status_change_audit`, …) — izvršavaju se u kontekstu događaja; zaštita je u poslovnim pravilima i FK/RLS gde ima smisla.

## Pravila za nove RPC-ove

1. Izbegavaj `SECURITY DEFINER` ako može **`SECURITY INVOKER`** + RLS.
2. Ako mora `DEFINER`: eksplicitno `SET search_path = public` i provera **`auth.uid()`** za sve „scope“ parametre.
3. Ne izlaži admin/audit funkcije `anon` (vidi `REVOKE` u migracijama oko `audit_product_ordering`).

Posle nove migracije (posle `20260321160000` u imenu fajla) pokreni:

`dart run tool/scan_security_definer_migrations.dart`

Skripta preskače istorijske migracije i upozorava ako u novom fajlu ima `p_*_id` bez `auth.uid()` (osim javnih funkcija iz allowliste u skripti).

## Appendix: inventar (stanje repoa)

Grupisano po ulozi. Poslednja definicija funkcije pobedi u lancu migracija.

### Trigger / interni (nije direktan RPC sa klijenta)

| Funkcija | Napomena |
|----------|----------|
| `notify_new_order` | Posle INSERT na `orders` |
| `notify_order_status_change` | Posle UPDATE statusa; više migracija menja telo |
| `notify_new_message` | Poruke |
| `invoke_send_push` | Posle INSERT na `notifications` |
| `log_order_status_change_audit` | Audit zapis statusa |
| `enforce_order_status_transition` | BEFORE UPDATE (validacija) |
| `touch_message_reaction_updated_at` | BEFORE UPDATE na reakcijama |

### Cron / samo zakazani zadaci

`handle_order_retention`, `archive_and_expire_orders` — poziv iz `pg_cron` (vidi migracije sa `cron.schedule`), ne treba `GRANT` klijentima.

### DEFINER RPC — javni ili agregat

| Funkcija | Pristup |
|----------|---------|
| `get_home_products` | Katalog |
| `get_product_sales_counts` | Agregat prodaje |
| `get_product_ratings` | Agregat ocena |
| `get_seller_stats` | Javni profil prodavca |
| `get_seller_loyalty_stats` | Javni agregat lojalnosti |

### DEFINER RPC — provera u telu (`auth.uid()` / uloga)

| Funkcija | Napomena |
|----------|----------|
| `create_order_with_items` | `p_buyer_id` mora biti `auth.uid()` |
| `add_seller_reply` | Prodavac mora biti učesnik |
| `buyer_confirm_order_received` | Samo kupac porudžbine |
| `get_my_product_listing_autoflags` | `WHERE seller_id = auth.uid()` |
| `get_my_product_listing_autoflag_summary` | Isto |

### DEFINER RPC — zaštićeno param ↔ JWT (migracija `20260321160000`)

`get_conversations_for_user`, `get_seller_stats_dashboard`, `get_seller_inbox`, `get_reviewable_order` — vidi tabelu na vrhu dokumenta.

### Nisu `SECURITY DEFINER` (podrazumevano INVOKER + RLS)

Korisnički parametri ovde se oslanjaju na **RLS** i politike:

- `get_products_from_favorite_sellers`, `get_favorite_sellers_with_profiles`
- `get_seller_response_time_stats` — agregat vremena odgovora; ako rezultat deluje prazan sa tuđeg profila, uzrok može biti RLS nad `messages` (očekivano za privatnost).

## Reference

- [Supabase — Database Functions, security](https://supabase.com/docs/guides/database/functions)
