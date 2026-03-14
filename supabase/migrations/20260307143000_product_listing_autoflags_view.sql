-- Backend autoflag view for duplicate listing names and missing quality data.

CREATE OR REPLACE FUNCTION public.normalize_listing_key(input_value text)
RETURNS text
LANGUAGE sql
IMMUTABLE
STRICT
AS $$
  SELECT trim(
    regexp_replace(
      replace(
        translate(lower(input_value), 'čćšž', 'ccsz'),
        'đ',
        'dj'
      ),
      '[^a-z0-9]+',
      ' ',
      'g'
    )
  );
$$;

DROP VIEW IF EXISTS public.product_listing_autoflags;

CREATE VIEW public.product_listing_autoflags AS
WITH base AS (
  SELECT
    p.id AS product_id,
    p.seller_id,
    p.name,
    p.category,
    p.origin,
    p.shelf_life_days,
    p.image_urls,
    p.pickup_options,
    public.normalize_listing_key(p.name) AS normalized_name,
    public.normalize_listing_key(p.category) AS normalized_category
  FROM public.products p
),
same_category AS (
  SELECT
    seller_id,
    normalized_name,
    normalized_category,
    COUNT(*) AS cnt
  FROM base
  GROUP BY seller_id, normalized_name, normalized_category
),
cross_category AS (
  SELECT
    seller_id,
    normalized_name,
    COUNT(DISTINCT normalized_category) AS distinct_category_count
  FROM base
  GROUP BY seller_id, normalized_name
)
SELECT
  b.product_id,
  b.seller_id,
  b.name,
  b.category,
  b.normalized_name,
  b.normalized_category,
  GREATEST(sc.cnt - 1, 0) AS same_category_duplicates,
  GREATEST(cc.distinct_category_count - 1, 0) AS cross_category_duplicates,
  (COALESCE(array_length(b.image_urls, 1), 0) = 0) AS missing_image,
  (NULLIF(trim(COALESCE(b.origin, '')), '') IS NULL) AS missing_origin,
  (COALESCE(b.shelf_life_days, 0) <= 0) AS missing_shelf_life,
  (COALESCE(array_length(b.pickup_options, 1), 0) = 0) AS missing_pickup,
  array_remove(
    ARRAY[
      CASE WHEN GREATEST(sc.cnt - 1, 0) > 0 THEN 'duplicate_same_category' END,
      CASE WHEN GREATEST(cc.distinct_category_count - 1, 0) > 0 THEN 'duplicate_cross_category' END,
      CASE WHEN COALESCE(array_length(b.image_urls, 1), 0) = 0 THEN 'missing_image' END,
      CASE WHEN NULLIF(trim(COALESCE(b.origin, '')), '') IS NULL THEN 'missing_origin' END,
      CASE WHEN COALESCE(b.shelf_life_days, 0) <= 0 THEN 'missing_shelf_life' END,
      CASE WHEN COALESCE(array_length(b.pickup_options, 1), 0) = 0 THEN 'missing_pickup' END
    ],
    NULL
  ) AS issues,
  (
    GREATEST(sc.cnt - 1, 0) > 0 OR
    GREATEST(cc.distinct_category_count - 1, 0) > 0 OR
    COALESCE(array_length(b.image_urls, 1), 0) = 0 OR
    NULLIF(trim(COALESCE(b.origin, '')), '') IS NULL OR
    COALESCE(b.shelf_life_days, 0) <= 0 OR
    COALESCE(array_length(b.pickup_options, 1), 0) = 0
  ) AS has_issues
FROM base b
JOIN same_category sc
  ON sc.seller_id = b.seller_id
 AND sc.normalized_name = b.normalized_name
 AND sc.normalized_category = b.normalized_category
JOIN cross_category cc
  ON cc.seller_id = b.seller_id
 AND cc.normalized_name = b.normalized_name;

GRANT SELECT ON public.product_listing_autoflags TO anon, authenticated;
