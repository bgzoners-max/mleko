# Supabase: performansa RLS, indeksi, Edge

Kratak vodič povezan sa **Database Advisor** upozorenjima (RLS `auth.*()`, više UPDATE politika, nekorišćeni indeksi).

## 1. RLS: `auth.uid()` → `(SELECT auth.uid())`

Izraz u politici treba da bude u obliku skalarnog podupita da se **ne re-evaluira po redu** nepotrebno:

```sql
-- Umesto:
USING (auth.uid() = user_id)

-- Koristi:
USING ((SELECT auth.uid()) = user_id)
```

Migracija **`20260322180000_orders_rls_consolidate_auth_select.sql`** primenjuje ovo na `public.orders` i konsoliduje UPDATE politike.

### `public.support_tickets`

Tabela **nije** u ovom repou; ako postoji samo na hostu, u SQL Editoru:

1. Otvori postojeće politike (Authentication → Policies ili `pg_policies`).
2. Za svaku politiku zameni `auth.uid()`, `auth.jwt()...` sa `(SELECT auth.uid())` itd.
3. Ili generiši `DROP POLICY` / `CREATE POLICY` kopijom logike sa podupitima.

Primer šablona (prilagodi kolone i uloge):

```sql
-- PRIMER — zameni imena kolona i proveri WITH CHECK
DROP POLICY IF EXISTS "some_policy_name" ON public.support_tickets;
CREATE POLICY "some_policy_name" ON public.support_tickets
  FOR ALL TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);
```

## 2. Više permissive UPDATE politika na istoj tabeli

Advisor predlaže **jednu** politiku gde god je ista uloga (`authenticated`) i ista operacija. Za `orders` to rešava migracija `20260322180000_*` (jedna politika „Participants can update their orders“).

## 3. Nekorišćeni indeksi (information)

Pre `DROP INDEX` u produkciji:

- Sačekaj reprezentativan period saobraćaja ili proveri `idx_scan` u `pg_stat_user_indexes`.
- Potvrdi da nema planova koji će kasnije koristiti indeks (npr. retki izveštaji).

Upit za pregled (veličina + broj skenova):

```sql
SELECT
  s.schemaname,
  s.relname AS table_name,
  s.indexrelname AS index_name,
  s.idx_scan,
  pg_size_pretty(pg_relation_size(s.indexrelid::regclass)) AS index_size
FROM pg_stat_user_indexes s
WHERE s.schemaname = 'public'
ORDER BY s.idx_scan ASC, pg_relation_size(s.indexrelid::regclass) DESC;
```

Indeksi sa `idx_scan = 0` nakon dužeg perioda — kandidati za ručni pregled (ne automatski DROP u migraciji bez analize).

## 4. Edge Functions (`swift-processor`, `swift-responder`, `send-push`)

- Logovi: Supabase Dashboard → Edge Functions → funkcija → **Logs**, ili CLI / API `get_logs` za projekat.
- Zdravlje: opciono mala funkcija koja radi `SELECT 1` preko poolera — deploy posebno ako zatreba monitoring.

## Reference

- [Supabase RLS performance](https://supabase.com/docs/guides/database/postgres/row-level-security#call-functions-with-select)
- Lokalno: `npx supabase db reset` posle dodavanja migracije da proveriš da aplikacija i testovi prolaze.
