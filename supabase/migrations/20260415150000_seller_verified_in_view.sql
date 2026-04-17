-- Dodaj seller_is_verified u products_with_ratings view
-- Kupci mogu videti verified badge na product card-u bez dodatnog API poziva

DROP VIEW IF EXISTS public.products_with_ratings CASCADE;

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
  p.delivery_mode,
  p.created_at,
  COALESCE(r.avg_rating, 0)::numeric   AS avg_rating,
  COALESCE(r.review_count, 0)::bigint  AS review_count,
  COALESCE(s.order_count, 0)::bigint   AS order_count,
  COALESCE(pr.is_verified, false)      AS seller_is_verified
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
) s ON p.id = s.product_id
LEFT JOIN public.profiles pr ON p.seller_id = pr.id;

GRANT SELECT ON public.products_with_ratings TO anon;
GRANT SELECT ON public.products_with_ratings TO authenticated;

-- Ponovo kreiraj search_products_fts jer CASCADE ga je obrisao
CREATE OR REPLACE FUNCTION search_products_fts(
  p_query             text,
  p_category          text    DEFAULT NULL,
  p_region            text    DEFAULT NULL,
  p_available_now     boolean DEFAULT NULL,
  p_exclude_seller_id uuid    DEFAULT NULL,
  p_limit             int     DEFAULT 20,
  p_offset            int     DEFAULT 0
)
RETURNS SETOF public.products_with_ratings
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT pwr.*
  FROM public.products_with_ratings pwr
  JOIN public.products p ON p.id = pwr.id
  WHERE
    (p_category         IS NULL OR pwr.category    = p_category)       AND
    (p_region           IS NULL OR pwr.location    = p_region)         AND
    (p_available_now    IS NULL OR pwr.available_now = p_available_now) AND
    (p_exclude_seller_id IS NULL OR pwr.seller_id  <> p_exclude_seller_id) AND
    p.search_vector @@ websearch_to_tsquery('simple', unaccent(p_query))
  ORDER BY
    ts_rank(p.search_vector, websearch_to_tsquery('simple', unaccent(p_query))) DESC,
    pwr.created_at DESC
  LIMIT  p_limit
  OFFSET p_offset;
$$;

GRANT EXECUTE ON FUNCTION search_products_fts TO anon, authenticated;

-- RPC za admin: toggle is_verified za prodavca
CREATE OR REPLACE FUNCTION admin_set_seller_verified(
  p_seller_id uuid,
  p_verified  boolean
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_admin = true
  ) THEN
    RAISE EXCEPTION 'Pristup odbijen: nije admin';
  END IF;

  UPDATE public.profiles
  SET is_verified = p_verified
  WHERE id = p_seller_id;
END;
$$;

GRANT EXECUTE ON FUNCTION admin_set_seller_verified TO authenticated;
