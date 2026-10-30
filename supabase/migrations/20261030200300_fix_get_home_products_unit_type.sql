-- ============================================================================
-- Migracija: 20261030200300_fix_get_home_products_unit_type.sql
-- Naziv: Dodavanje unit_type, order_step, delivery_mode i seller_is_verified u get_home_products RPC
-- ============================================================================
-- U migraciji 20260912110000_maintain_product_aggregates.sql funkcija
-- public.get_home_products je rekreirana bez kolona unit_type, order_step,
-- delivery_mode i seller_is_verified, zbog čega je ProductModel.fromJson na
-- početnom ekranu padao na podrazumevanu jedinicu 'kg' (pa je pisalo
-- "din./kg" i "min 100 kg" čak i za proizvode čiji je unit_type = 'kom' ili 'L').

DROP FUNCTION IF EXISTS public.get_home_products(int, text, text);

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
    (p.created_at >= NOW() - INTERVAL '14 days') DESC,
    COALESCE(r.avg_rating, 0) DESC,
    COALESCE(o.order_count, 0) DESC,
    p.created_at DESC
  LIMIT GREATEST(1, LEAST(p_limit, 100));
$$;

GRANT EXECUTE ON FUNCTION public.get_home_products(INTEGER, TEXT, TEXT) TO anon, authenticated;

-- Ispravka jedinice mere za teglu kompota od breskve (Jasmina Đorđević je za ostalih 5 tegli/kesica stavila 'kom', a ovde je ostalo podrazumevano 'kg')
UPDATE public.products
SET unit_type = 'kom'
WHERE id = '610abed6-c883-4577-ba6a-82980895d1cb'
  AND unit_type = 'kg';
