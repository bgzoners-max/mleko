-- Ispravka: get_home_products RPC - broji iz order_items, ne iz orders
-- Problem: RPC je brojao iz orders.product_id direktno sa statusima ('accepted', 'delivered')
-- Ali: proizvodi su u order_items tabeli, i narudžbine imaju statusе ('sent', 'arhivirano', 'delivered')
-- Rezultat: sve prodaje su stale 0

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
    -- Broji iz order_items jer proizvodi mogu biti u multi-item narudžbinama
    SELECT oi.product_id, COUNT(DISTINCT oi.order_id)::bigint AS cnt
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.id
    WHERE o.status IN ('accepted', 'delivered', 'sent', 'arhivirano')
    GROUP BY oi.product_id
  )
  SELECT
    p.id, p.seller_id, p.category, p.name, p.price_per_kg, p.min_order_kg,
    p.available_kg, p.description, p.image_urls, p.pickup_options, p.location,
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
