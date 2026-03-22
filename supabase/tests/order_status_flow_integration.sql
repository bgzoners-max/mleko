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
  SELECT pg_get_constraintdef(oid) ILIKE '%arhivirano%'
  INTO has_archived_in_check
  FROM pg_constraint
  WHERE conname = 'orders_status_check'
  LIMIT 1;

  IF COALESCE(has_archived_in_check, false) = false THEN
    RAISE EXCEPTION 'orders_status_check does not include arhivirano';
  END IF;
END $$;

ROLLBACK;
