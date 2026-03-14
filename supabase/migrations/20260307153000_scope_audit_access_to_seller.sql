-- Tighten authenticated access for internal audit artifacts.
-- Expose seller-scoped RPCs instead of global views/functions.

REVOKE EXECUTE ON FUNCTION public.audit_product_ordering(int) FROM authenticated;
REVOKE SELECT ON public.ordering_audit_summary FROM authenticated;
REVOKE SELECT ON public.product_listing_autoflags FROM authenticated;

CREATE OR REPLACE FUNCTION public.get_my_product_listing_autoflags()
RETURNS TABLE (
  product_id uuid,
  seller_id uuid,
  name text,
  category text,
  normalized_name text,
  normalized_category text,
  same_category_duplicates integer,
  cross_category_duplicates bigint,
  missing_image boolean,
  missing_origin boolean,
  missing_shelf_life boolean,
  missing_pickup boolean,
  issues text[],
  has_issues boolean
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    f.product_id,
    f.seller_id,
    f.name,
    f.category,
    f.normalized_name,
    f.normalized_category,
    f.same_category_duplicates,
    f.cross_category_duplicates,
    f.missing_image,
    f.missing_origin,
    f.missing_shelf_life,
    f.missing_pickup,
    f.issues,
    f.has_issues
  FROM public.product_listing_autoflags f
  WHERE f.seller_id = auth.uid()
  ORDER BY
    f.has_issues DESC,
    cardinality(f.issues) DESC,
    f.name;
$$;

CREATE OR REPLACE FUNCTION public.get_my_product_listing_autoflag_summary()
RETURNS TABLE (
  total_products integer,
  clean_products integer,
  problem_products integer,
  problem_rate_percent numeric
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  WITH mine AS (
    SELECT *
    FROM public.product_listing_autoflags
    WHERE seller_id = auth.uid()
  ),
  stats AS (
    SELECT
      COUNT(*)::int AS total_products,
      COUNT(*) FILTER (WHERE has_issues = false)::int AS clean_products,
      COUNT(*) FILTER (WHERE has_issues = true)::int AS problem_products
    FROM mine
  )
  SELECT
    total_products,
    clean_products,
    problem_products,
    CASE
      WHEN total_products = 0 THEN 0::numeric
      ELSE ROUND((problem_products::numeric / total_products::numeric) * 100, 2)
    END AS problem_rate_percent
  FROM stats;
$$;

GRANT EXECUTE ON FUNCTION public.get_my_product_listing_autoflags() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_product_listing_autoflag_summary() TO authenticated;
