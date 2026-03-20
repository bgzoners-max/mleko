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

## Reference

- [Supabase — Database Functions, security](https://supabase.com/docs/guides/database/functions)
