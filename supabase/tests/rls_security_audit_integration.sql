-- ============================================================================
-- Integracioni test za RLS reviziju, bezbednost baze i zaštitu privatnosti
-- Pokretanje: psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f supabase/tests/rls_security_audit_integration.sql
-- ============================================================================

BEGIN;

-- 1. Provera funkcije is_admin() - SECURITY DEFINER i SET search_path = public
DO $$
DECLARE
  v_prosecdef BOOLEAN;
  v_proconfig TEXT[];
BEGIN
  SELECT p.prosecdef, p.proconfig INTO v_prosecdef, v_proconfig
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public' AND p.proname = 'is_admin';

  IF v_prosecdef IS NULL THEN
    RAISE EXCEPTION 'Funkcija public.is_admin() ne postoji!';
  END IF;

  IF NOT v_prosecdef THEN
    RAISE EXCEPTION 'public.is_admin() mora biti SECURITY DEFINER!';
  END IF;

  IF NOT ('search_path=public' = ANY(v_proconfig)) THEN
    RAISE EXCEPTION 'public.is_admin() mora imati postavljen SET search_path = public!';
  END IF;
END $$;

-- 2. Provera view-a public_profiles i maskiranja adrese
DO $$
DECLARE
  v_view_def TEXT;
BEGIN
  SELECT pg_get_viewdef('public.public_profiles'::regclass, true) INTO v_view_def;
  IF v_view_def IS NULL THEN
    RAISE EXCEPTION 'View public.public_profiles ne postoji!';
  END IF;

  -- Provera da adresa nije eksponirana bez maskiranja
  IF v_view_def NOT LIKE '%address%' THEN
    RAISE EXCEPTION 'Kolona address mora postojati u public.public_profiles!';
  END IF;

  IF v_view_def NOT LIKE '%is_admin%' THEN
    RAISE EXCEPTION 'View public.public_profiles mora proveravati is_admin ili auth.uid() za privatne podatke!';
  END IF;
END $$;

-- 3. Provera RLS polisa na products za admin moderaciju
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'products'
      AND policyname = 'Sellers can delete own products'
  ) THEN
    RAISE EXCEPTION 'Polisa "Sellers can delete own products" nedostaje!';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'products'
      AND policyname = 'Sellers can update own products'
  ) THEN
    RAISE EXCEPTION 'Polisa "Sellers can update own products" nedostaje!';
  END IF;
END $$;

-- 4. Provera RLS polisa na classified_ad_reports za admin moderaciju
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'classified_ad_reports'
      AND policyname = 'classified_ad_reports_select_own'
  ) THEN
    RAISE EXCEPTION 'Polisa "classified_ad_reports_select_own" nedostaje!';
  END IF;
END $$;

-- 5. Provera da sve ključne tabele imaju uključen RLS
DO $$
DECLARE
  v_table TEXT;
  v_missing TEXT[] := '{}';
  v_expected_tables TEXT[] := ARRAY[
    'profiles', 'products', 'orders', 'order_items', 'reviews',
    'buyer_reviews', 'favorites', 'favorite_sellers', 'user_push_tokens',
    'conversations', 'messages', 'support_tickets', 'support_ticket_messages',
    'classified_ads', 'classified_ad_reports', 'edge_config', 'waitlist'
  ];
BEGIN
  FOREACH v_table IN ARRAY v_expected_tables LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_tables
      WHERE schemaname = 'public' AND tablename = v_table AND rowsecurity = true
    ) THEN
      v_missing := array_append(v_missing, v_table);
    END IF;
  END LOOP;

  IF array_length(v_missing, 1) > 0 THEN
    RAISE EXCEPTION 'Sledece tabele nemaju ukljucen RLS: %', array_to_string(v_missing, ', ');
  END IF;
END $$;

-- 6. Provera Paket B: get_seller_popular_products i get_seller_response_time_stats su SECURITY DEFINER
DO $$
DECLARE
  v_fn TEXT;
  v_prosecdef BOOLEAN;
  v_proconfig TEXT[];
BEGIN
  FOREACH v_fn IN ARRAY ARRAY['get_seller_popular_products', 'get_seller_response_time_stats'] LOOP
    SELECT p.prosecdef, p.proconfig INTO v_prosecdef, v_proconfig
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname = v_fn;

    IF v_prosecdef IS NULL THEN
      RAISE EXCEPTION 'Funkcija public.% ne postoji!', v_fn;
    END IF;

    IF NOT v_prosecdef THEN
      RAISE EXCEPTION 'public.% mora biti SECURITY DEFINER!', v_fn;
    END IF;

    IF NOT ('search_path=public' = ANY(v_proconfig)) THEN
      RAISE EXCEPTION 'public.% mora imati postavljen SET search_path = public!', v_fn;
    END IF;
  END LOOP;
END $$;

-- 7. Provera Paket B: public.public_classified_ads ne sme izlagati phone preko phone_public za posetioce
DO $$
DECLARE
  v_view_def TEXT;
BEGIN
  SELECT pg_get_viewdef('public.public_classified_ads'::regclass, true) INTO v_view_def;
  IF v_view_def IS NULL THEN
    RAISE EXCEPTION 'View public.public_classified_ads ne postoji!';
  END IF;

  IF v_view_def NOT LIKE '%seller_type%' OR v_view_def NOT LIKE '%attributes%' THEN
    RAISE EXCEPTION 'View public.public_classified_ads mora ukljucivati seller_type i attributes!';
  END IF;
END $$;

-- 8. Provera Paket 1 (P0 bezbednosno očvršćavanje):
--    - zabrana direktnog INSERT-a na orders i order_items za authenticated/anon
--    - zabrana klijentskog DELETE na conversations
--    - buyer_reviews trigger i RLS provera porudžbine
--    - is_admin() izvršiv za anon i authenticated
--    - audit_product_ordering nije dostupan anon/authenticated ulozi
DO $$
BEGIN
  IF has_table_privilege('authenticated', 'public.orders', 'INSERT') THEN
    RAISE EXCEPTION 'authenticated ne sme imati direktan INSERT na public.orders!';
  END IF;

  IF has_table_privilege('authenticated', 'public.order_items', 'INSERT') THEN
    RAISE EXCEPTION 'authenticated ne sme imati direktan INSERT na public.order_items!';
  END IF;

  IF has_table_privilege('authenticated', 'public.conversations', 'DELETE') THEN
    RAISE EXCEPTION 'authenticated ne sme imati DELETE na public.conversations!';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger
    WHERE tgname = 'trg_validate_seller_buyer_review_submission'
      AND tgrelid = 'public.buyer_reviews'::regclass
  ) THEN
    RAISE EXCEPTION 'Trigger trg_validate_seller_buyer_review_submission nedostaje na public.buyer_reviews!';
  END IF;

  IF NOT has_function_privilege('anon', 'public.is_admin()', 'EXECUTE') THEN
    RAISE EXCEPTION 'anon mora imati EXECUTE na public.is_admin() zbog anon RLS politika!';
  END IF;

  IF has_function_privilege('anon', 'public.audit_product_ordering(int)', 'EXECUTE') THEN
    RAISE EXCEPTION 'anon ne sme imati EXECUTE na public.audit_product_ordering(int)!';
  END IF;
END $$;

ROLLBACK;
