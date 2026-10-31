-- ============================================================================
-- Migracija: 20261031194500_prioritize_products_with_images_on_home.sql
-- Naziv: Prednost oglasima sa fotografijom u get_home_products RPC
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_home_products(
  p_limit int DEFAULT 50,
  p_region text DEFAULT NULL,
  p_category text DEFAULT NULL
)
RETURNS TABLE (
  id uuid,
  seller_id uuid,
  category text,
  name text,
  price_per_kg numeric,
  min_order_kg numeric,
  order_step numeric,
  available_kg numeric,
  unit_type text,
  description text,
  image_urls text[],
  pickup_options text[],
  location text,
  is_domestic boolean,
  available_now boolean,
  delivery_mode text,
  created_at timestamptz,
  seller_is_verified boolean,
  order_count bigint,
  avg_rating numeric,
  review_count bigint
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    p.id,
    p.seller_id,
    p.category,
    p.name,
    p.price_per_kg,
    p.min_order_kg,
    p.order_step,
    p.available_kg,
    p.unit_type,
    p.description,
    p.image_urls,
    p.pickup_options,
    p.location,
    p.is_domestic,
    p.available_now,
    p.delivery_mode,
    p.created_at,
    COALESCE(prof.is_verified, false)   AS seller_is_verified,
    COALESCE(o.order_count, 0)::bigint  AS order_count,
    COALESCE(r.avg_rating, 0)::numeric  AS avg_rating,
    COALESCE(r.review_count, 0)::bigint AS review_count
  FROM public.products p
  LEFT JOIN public.product_order_summary o ON o.product_id = p.id
  LEFT JOIN public.product_review_summary r ON r.product_id = p.id
  LEFT JOIN public.profiles prof ON prof.id = p.seller_id
  WHERE (p_region IS NULL OR p_region = '' OR p.location = p_region)
    AND (p_category IS NULL OR p_category = '' OR p.category = p_category)
  ORDER BY
    (COALESCE(array_length(p.image_urls, 1), 0) > 0) DESC,
    (p.created_at >= NOW() - INTERVAL '14 days') DESC,
    COALESCE(r.avg_rating, 0) DESC,
    COALESCE(o.order_count, 0) DESC,
    p.created_at DESC
  LIMIT GREATEST(1, LEAST(p_limit, 100));
$$;

GRANT EXECUTE ON FUNCTION public.get_home_products(INTEGER, TEXT, TEXT) TO anon, authenticated;
