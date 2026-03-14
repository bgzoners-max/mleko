-- Compact KPI report for ordering audit.
-- Usage:
--   SELECT * FROM public.ordering_audit_summary;

CREATE OR REPLACE VIEW public.ordering_audit_summary AS
WITH audit AS (
  SELECT *
  FROM public.audit_product_ordering(5000)
),
stats AS (
  SELECT
    COUNT(*)::int AS total_products,
    COUNT(*) FILTER (WHERE issues IS NULL OR cardinality(issues) = 0)::int AS clean_products,
    COUNT(*) FILTER (WHERE issues IS NOT NULL AND cardinality(issues) > 0)::int AS problem_products
  FROM audit
)
SELECT
  NOW() AS generated_at,
  total_products,
  clean_products,
  problem_products,
  CASE
    WHEN total_products = 0 THEN 0::numeric
    ELSE ROUND((problem_products::numeric / total_products::numeric) * 100, 2)
  END AS problem_rate_percent
FROM stats;

GRANT SELECT ON public.ordering_audit_summary TO anon;
GRANT SELECT ON public.ordering_audit_summary TO authenticated;
