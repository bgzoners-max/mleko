-- ============================================================================
-- Sigurnost: RLS i zaštita integriteta nad tabelama agregata
-- Datum: 2026-09-17
--
-- Tabele public.product_review_summary i public.product_order_summary
-- sadrže agregate koje održavaju isključivo interni SECURITY DEFINER trigeri.
--
-- Ova migracija:
-- 1. Uključuje Row Level Security (RLS) na obe tabele.
-- 2. Oduzima (REVOKE) INSERT, UPDATE, DELETE, TRUNCATE od rola anon i authenticated.
-- 3. Kreira FOR SELECT RLS politike kako bi javni upiti (i security_invoker view
--    products_with_ratings) imali neometano pravo čitanja podataka.
-- ============================================================================

ALTER TABLE public.product_review_summary ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_order_summary ENABLE ROW LEVEL SECURITY;

REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.product_review_summary FROM anon, authenticated;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.product_order_summary FROM anon, authenticated;

DROP POLICY IF EXISTS "summary_read" ON public.product_review_summary;
CREATE POLICY "summary_read" ON public.product_review_summary
  FOR SELECT
  TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS "summary_read" ON public.product_order_summary;
CREATE POLICY "summary_read" ON public.product_order_summary
  FOR SELECT
  TO anon, authenticated
  USING (true);
