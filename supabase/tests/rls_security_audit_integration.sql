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
    'classified_ads', 'classified_ad_reports', 'edge_config'
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

ROLLBACK;
