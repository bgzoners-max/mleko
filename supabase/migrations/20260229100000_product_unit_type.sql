-- Jedinica za proizvod: kg (default) ili L (litri/ml) za tečne, zimnicu, tegle
ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS unit_type text NOT NULL DEFAULT 'kg'
  CHECK (unit_type IN ('kg', 'L'));

COMMENT ON COLUMN public.products.unit_type IS 'kg = kilogrami, L = litri (min/available u L, cena po litru)';

-- Ažuriraj view da uključi unit_type
DROP VIEW IF EXISTS public.products_with_ratings;

CREATE VIEW public.products_with_ratings AS
SELECT
  p.id,
  p.seller_id,
  p.category,
  p.name,
  p.price_per_kg,
  p.min_order_kg,
  p.available_kg,
  p.unit_type,
  p.description,
  p.image_urls,
  p.pickup_options,
  p.location,
  p.is_domestic,
  p.available_now,
  p.created_at,
  COALESCE(r.avg_rating, 0)::numeric AS avg_rating,
  COALESCE(r.review_count, 0)::bigint AS review_count,
  COALESCE(s.order_count, 0)::bigint AS order_count
FROM public.products p
LEFT JOIN (
  SELECT product_id, AVG(rating)::numeric AS avg_rating, COUNT(*)::bigint AS review_count
  FROM public.reviews
  WHERE product_id IS NOT NULL
  GROUP BY product_id
) r ON p.id = r.product_id
LEFT JOIN (
  SELECT product_id, COUNT(*)::bigint AS order_count
  FROM public.orders
  WHERE status IN ('accepted', 'delivered')
  GROUP BY product_id
) s ON p.id = s.product_id;

GRANT SELECT ON public.products_with_ratings TO anon;
GRANT SELECT ON public.products_with_ratings TO authenticated;

-- RPC get_home_products – dodaj unit_type u povrat (mora DROP jer se menja tip povratka)
DROP FUNCTION IF EXISTS public.get_home_products(int, text, text);

CREATE FUNCTION public.get_home_products(
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
  available_kg numeric,
  unit_type text,
  description text,
  image_urls text[],
  pickup_options text[],
  location text,
  is_domestic boolean,
  available_now boolean,
  created_at timestamptz,
  order_count bigint
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  WITH sales AS (
    SELECT product_id, COUNT(*)::bigint AS cnt
    FROM orders
    WHERE status IN ('accepted', 'delivered')
    GROUP BY product_id
  )
  SELECT
    p.id, p.seller_id, p.category, p.name, p.price_per_kg, p.min_order_kg,
    p.available_kg, p.unit_type, p.description, p.image_urls, p.pickup_options, p.location,
    p.is_domestic, p.available_now, p.created_at,
    COALESCE(s.cnt, 0)::bigint AS order_count
  FROM products p
  LEFT JOIN sales s ON s.product_id = p.id
  WHERE (p_region IS NULL OR p_region = '' OR p.location = p_region)
    AND (p_category IS NULL OR p_category = '' OR p.category = p_category)
  ORDER BY
    (p.created_at >= NOW() - INTERVAL '14 days') DESC,
    COALESCE(s.cnt, 0) DESC,
    p.created_at DESC
  LIMIT GREATEST(1, LEAST(p_limit, 100));
$$;
