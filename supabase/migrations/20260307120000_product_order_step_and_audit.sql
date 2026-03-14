-- Realistic ordering: explicit order step + stricter unit contract.

ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS order_step numeric;

UPDATE public.products
SET order_step = CASE
  WHEN unit_type = 'g' THEN 0.05
  WHEN unit_type = 'kom' THEN 10
  WHEN unit_type = 'L' AND min_order_kg > 0 AND min_order_kg < 1 THEN min_order_kg
  ELSE 1
END
WHERE order_step IS NULL OR order_step <= 0;

ALTER TABLE public.products
  ALTER COLUMN order_step SET DEFAULT 1,
  ALTER COLUMN order_step SET NOT NULL;

ALTER TABLE public.products
  DROP CONSTRAINT IF EXISTS products_order_step_positive;

ALTER TABLE public.products
  ADD CONSTRAINT products_order_step_positive CHECK (order_step > 0);

-- Flutter app already supports g and kom for products.
ALTER TABLE public.products
  DROP CONSTRAINT IF EXISTS products_unit_type_check;

ALTER TABLE public.products
  ADD CONSTRAINT products_unit_type_check
  CHECK (unit_type IN ('kg', 'L', 'g', 'kom'));

COMMENT ON COLUMN public.products.order_step IS 'Korak porudzbine u istoj jedinici kao min_order_kg (kg/L).';

DROP VIEW IF EXISTS public.products_with_ratings;

CREATE VIEW public.products_with_ratings AS
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
  order_step numeric,
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
    p.order_step, p.available_kg, p.unit_type, p.description, p.image_urls,
    p.pickup_options, p.location, p.is_domestic, p.available_now, p.created_at,
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

CREATE OR REPLACE FUNCTION public.audit_product_ordering(p_limit int DEFAULT 500)
RETURNS TABLE (
  product_id uuid,
  name text,
  category text,
  unit_type text,
  min_quantity numeric,
  order_step numeric,
  suggested_unit text,
  suggested_min numeric,
  suggested_step numeric,
  sample_options text,
  issues text[]
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  WITH base AS (
    SELECT
      p.id,
      p.name,
      p.category,
      p.unit_type,
      p.min_order_kg,
      p.order_step,
      lower(coalesce(p.category, '') || ' ' || coalesce(p.name, '') || ' ' || coalesce(p.description, '')) AS haystack
    FROM public.products p
    ORDER BY p.created_at DESC
    LIMIT GREATEST(1, LEAST(p_limit, 5000))
  ),
  suggested AS (
    SELECT
      b.*,
      CASE
        WHEN b.haystack LIKE '%med%' OR b.haystack LIKE '%honey%' THEN 'kg'
        WHEN b.haystack LIKE '%jaje%' OR b.haystack LIKE '%jaja%' OR b.haystack LIKE '%egg%' THEN 'kom'
        WHEN b.haystack LIKE '%mleko%' OR b.haystack LIKE '%mlijeko%' OR b.haystack LIKE '%milk%' THEN 'L'
        WHEN b.haystack LIKE '%sir%' OR b.haystack LIKE '%kajmak%' OR b.haystack LIKE '%suhomesnat%'
          OR b.haystack LIKE '%kulen%' OR b.haystack LIKE '%slanina%' THEN 'kg'
        WHEN b.haystack LIKE '%meso%' OR b.haystack LIKE '%junet%' OR b.haystack LIKE '%svinj%'
          OR b.haystack LIKE '%telet%' OR b.haystack LIKE '%pilet%' OR b.haystack LIKE '%jagnjet%' THEN 'kg'
        WHEN b.haystack LIKE '%povrc%' OR b.haystack LIKE '%povrć%' OR b.haystack LIKE '%voce%'
          OR b.haystack LIKE '%voće%' OR b.haystack LIKE '%fruit%' OR b.haystack LIKE '%vegetable%' THEN 'kg'
        WHEN b.haystack LIKE '%sok%' OR b.haystack LIKE '%sirup%' OR b.haystack LIKE '%zimnic%'
          OR b.haystack LIKE '%dzem%' OR b.haystack LIKE '%džem%' OR b.haystack LIKE '%tegla%' THEN 'L'
        ELSE b.unit_type
      END AS suggested_unit,
      CASE
        WHEN b.haystack LIKE '%med%' OR b.haystack LIKE '%honey%' THEN 0.5::numeric
        WHEN b.haystack LIKE '%jaje%' OR b.haystack LIKE '%jaja%' OR b.haystack LIKE '%egg%' THEN 10::numeric
        WHEN b.haystack LIKE '%mleko%' OR b.haystack LIKE '%mlijeko%' OR b.haystack LIKE '%milk%' THEN 1::numeric
        WHEN b.haystack LIKE '%sir%' OR b.haystack LIKE '%kajmak%' OR b.haystack LIKE '%suhomesnat%'
          OR b.haystack LIKE '%kulen%' OR b.haystack LIKE '%slanina%' THEN 0.5::numeric
        WHEN b.haystack LIKE '%meso%' OR b.haystack LIKE '%junet%' OR b.haystack LIKE '%svinj%'
          OR b.haystack LIKE '%telet%' OR b.haystack LIKE '%pilet%' OR b.haystack LIKE '%jagnjet%' THEN 1::numeric
        WHEN b.haystack LIKE '%povrc%' OR b.haystack LIKE '%povrć%' OR b.haystack LIKE '%voce%'
          OR b.haystack LIKE '%voće%' OR b.haystack LIKE '%fruit%' OR b.haystack LIKE '%vegetable%' THEN 1::numeric
        WHEN b.haystack LIKE '%sok%' OR b.haystack LIKE '%sirup%' OR b.haystack LIKE '%zimnic%'
          OR b.haystack LIKE '%dzem%' OR b.haystack LIKE '%džem%' OR b.haystack LIKE '%tegla%' THEN 0.72::numeric
        ELSE CASE
          WHEN b.unit_type = 'g' THEN 0.05::numeric
          WHEN b.unit_type = 'kom' THEN 10::numeric
          ELSE 1::numeric
        END
      END AS suggested_min,
      CASE
        WHEN b.haystack LIKE '%med%' OR b.haystack LIKE '%honey%' THEN 0.5::numeric
        WHEN b.haystack LIKE '%jaje%' OR b.haystack LIKE '%jaja%' OR b.haystack LIKE '%egg%' THEN 10::numeric
        WHEN b.haystack LIKE '%mleko%' OR b.haystack LIKE '%mlijeko%' OR b.haystack LIKE '%milk%' THEN 0.5::numeric
        WHEN b.haystack LIKE '%sir%' OR b.haystack LIKE '%kajmak%' OR b.haystack LIKE '%suhomesnat%'
          OR b.haystack LIKE '%kulen%' OR b.haystack LIKE '%slanina%' THEN 0.25::numeric
        WHEN b.haystack LIKE '%meso%' OR b.haystack LIKE '%junet%' OR b.haystack LIKE '%svinj%'
          OR b.haystack LIKE '%telet%' OR b.haystack LIKE '%pilet%' OR b.haystack LIKE '%jagnjet%' THEN 0.5::numeric
        WHEN b.haystack LIKE '%povrc%' OR b.haystack LIKE '%povrć%' OR b.haystack LIKE '%voce%'
          OR b.haystack LIKE '%voće%' OR b.haystack LIKE '%fruit%' OR b.haystack LIKE '%vegetable%' THEN 0.5::numeric
        WHEN b.haystack LIKE '%sok%' OR b.haystack LIKE '%sirup%' OR b.haystack LIKE '%zimnic%'
          OR b.haystack LIKE '%dzem%' OR b.haystack LIKE '%džem%' OR b.haystack LIKE '%tegla%' THEN 0.37::numeric
        ELSE CASE
          WHEN b.unit_type = 'g' THEN 0.05::numeric
          WHEN b.unit_type = 'kom' THEN 10::numeric
          ELSE 1::numeric
        END
      END AS suggested_step
    FROM base b
  )
  SELECT
    s.id AS product_id,
    s.name,
    s.category,
    s.unit_type,
    s.min_order_kg AS min_quantity,
    s.order_step,
    s.suggested_unit,
    s.suggested_min,
    s.suggested_step,
    (
      SELECT string_agg(trim(trailing '.0' FROM ((s.min_order_kg + (i * s.order_step))::numeric(12,3))::text), ', ')
      FROM generate_series(0, 4) AS i
    ) AS sample_options,
    array_remove(ARRAY[
      CASE WHEN s.min_order_kg IS NULL OR s.min_order_kg <= 0 THEN 'min_quantity<=0' END,
      CASE WHEN s.order_step IS NULL OR s.order_step <= 0 THEN 'order_step<=0' END,
      CASE WHEN s.order_step > s.min_order_kg THEN 'order_step>min_quantity' END,
      CASE WHEN (s.haystack LIKE '%med%' OR s.haystack LIKE '%honey%') AND s.unit_type <> 'kg' THEN 'honey_not_kg' END,
      CASE WHEN s.unit_type <> s.suggested_unit THEN 'unit_differs_from_suggestion' END
    ], NULL) AS issues
  FROM suggested s;
$$;

GRANT EXECUTE ON FUNCTION public.audit_product_ordering(int) TO anon;
GRANT EXECUTE ON FUNCTION public.audit_product_ordering(int) TO authenticated;
