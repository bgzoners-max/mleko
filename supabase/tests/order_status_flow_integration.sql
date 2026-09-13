-- Integration checks for order status flow at DB level.
-- Run with: npx supabase db reset && psql "$SUPABASE_DB_URL" -f supabase/tests/order_status_flow_integration.sql

BEGIN;

-- This script validates schema/function/trigger availability and core flow invariants.

DO $$
BEGIN
  IF to_regclass('public.order_status_audit_logs') IS NULL THEN
    RAISE EXCEPTION 'order_status_audit_logs table missing';
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_trigger
    WHERE tgname = 'trg_enforce_order_status_transition'
  ) THEN
    RAISE EXCEPTION 'trg_enforce_order_status_transition missing';
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_trigger
    WHERE tgname = 'trg_log_order_status_change_audit'
  ) THEN
    RAISE EXCEPTION 'trg_log_order_status_change_audit missing';
  END IF;
END $$;

DO $$
BEGIN
  IF to_regprocedure('public.buyer_confirm_order_received(uuid)') IS NULL THEN
    RAISE EXCEPTION 'buyer_confirm_order_received(uuid) missing';
  END IF;
END $$;

-- to_regprocedure() can be unreliable for TRIGGER functions on some PG versions; use pg_proc.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname = 'notify_order_status_change'
  ) THEN
    RAISE EXCEPTION 'notify_order_status_change() missing';
  END IF;
END $$;

-- Manual archive state must still be part of status check.
DO $$
DECLARE
  has_archived_in_check boolean;
BEGIN
  SELECT pg_get_constraintdef(oid) ILIKE '%archived%'
  INTO has_archived_in_check
  FROM pg_constraint
  WHERE conname = 'orders_status_check'
  LIMIT 1;

  IF COALESCE(has_archived_in_check, false) = false THEN
    RAISE EXCEPTION 'orders_status_check does not include archived';
  END IF;
END $$;

-- Product aggregates (Nivo 2 – održavane sume umesto N+1 u products_with_ratings)
DO $$
BEGIN
  IF to_regclass('public.product_order_summary') IS NULL THEN
    RAISE EXCEPTION 'product_order_summary table missing';
  END IF;

  IF to_regclass('public.product_review_summary') IS NULL THEN
    RAISE EXCEPTION 'product_review_summary table missing';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger
    WHERE tgname = 'trg_maintain_product_order_summary'
  ) THEN
    RAISE EXCEPTION 'trg_maintain_product_order_summary missing';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger
    WHERE tgname = 'trg_maintain_product_review_summary'
  ) THEN
    RAISE EXCEPTION 'trg_maintain_product_review_summary missing';
  END IF;

  IF to_regclass('public.products_with_ratings') IS NULL THEN
    RAISE EXCEPTION 'products_with_ratings view missing';
  END IF;

  IF to_regprocedure('public.get_home_products(integer,text,text)') IS NULL THEN
    RAISE EXCEPTION 'get_home_products(integer,text,text) missing';
  END IF;
END $$;

-- Uveri se da view vise ne poziva stare N+1 funkcije po redu
DO $$
DECLARE
  view_def text;
BEGIN
  SELECT pg_get_viewdef('public.products_with_ratings'::regclass, false)
  INTO view_def;

  IF view_def LIKE '%get_product_order_count(%' THEN
    RAISE EXCEPTION 'products_with_ratings still uses per-row get_product_order_count()';
  END IF;

  IF view_def LIKE '%is_seller_verified(%' THEN
    RAISE EXCEPTION 'products_with_ratings still uses per-row is_seller_verified()';
  END IF;
END $$;

ROLLBACK;
