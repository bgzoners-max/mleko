-- ============================================================================
-- Migracija 20260904160000: Sigurnost – products_with_ratings security_invoker
--
-- Rešava Supabase linter finding: "Security Definer View" za products_with_ratings.
--
-- 1. Kreira get_product_order_count() kao SECURITY DEFINER STABLE funkciju sa
--    fiksnim search_path-om kako bi se broj prihvaćenih/isporučenih porudžbina
--    mogao javno agregirati bez izlaganja privatnih redova tabele orders.
-- 2. Kreira is_seller_verified() kao SECURITY DEFINER STABLE funkciju kako bi
--    i neautorizovani (anon) posetioci videli verified bedž na kartici proizvoda.
-- 3. Postavlja WITH (security_invoker = on) na public.products_with_ratings
--    tako da se view izvršava sa pravima korisnika koji postavlja upit.
-- 4. Održava search_products_fts funkciju koja vraća SETOF products_with_ratings.
-- ============================================================================

-- 1. Helper funkcija za agregaciju broja porudžbina
CREATE OR REPLACE FUNCTION public.get_product_order_count(p_product_id uuid)
RETURNS bigint
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COUNT(*)::bigint
  FROM public.orders
  WHERE product_id = p_product_id
    AND status IN ('accepted', 'delivered');
$$;

GRANT EXECUTE ON FUNCTION public.get_product_order_count(uuid) TO anon, authenticated;

-- 2. Helper funkcija za status verifikacije prodavca (bezbedno za anon korisnike)
CREATE OR REPLACE FUNCTION public.is_seller_verified(p_seller_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(is_verified, false)
  FROM public.profiles
  WHERE id = p_seller_id;
$$;

GRANT EXECUTE ON FUNCTION public.is_seller_verified(uuid) TO anon, authenticated;

-- 3. Ažuriranje view-a sa security_invoker = on
CREATE OR REPLACE VIEW public.products_with_ratings
WITH (security_invoker = on)
AS
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
  public.get_product_order_count(p.id) AS order_count,
  public.is_seller_verified(p.seller_id) AS seller_is_verified
FROM public.products p
LEFT JOIN (
  SELECT product_id, AVG(rating)::numeric AS avg_rating, COUNT(*)::bigint AS review_count
  FROM public.reviews
  WHERE product_id IS NOT NULL
  GROUP BY product_id
) r ON p.id = r.product_id;

GRANT SELECT ON public.products_with_ratings TO anon, authenticated;

-- 4. Obezbedi da search_products_fts ostaje sinhronizovan
CREATE OR REPLACE FUNCTION public.search_products_fts(
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
    (p_category          IS NULL OR pwr.category     = p_category)        AND
    (p_region            IS NULL OR pwr.location     = p_region)          AND
    (p_available_now     IS NULL OR pwr.available_now = p_available_now)  AND
    (p_exclude_seller_id IS NULL OR pwr.seller_id   <> p_exclude_seller_id) AND
    p.search_vector @@ websearch_to_tsquery('simple', unaccent(p_query))
  ORDER BY
    ts_rank(p.search_vector, websearch_to_tsquery('simple', unaccent(p_query))) DESC,
    pwr.created_at DESC
  LIMIT  p_limit
  OFFSET p_offset;
$$;

GRANT EXECUTE ON FUNCTION public.search_products_fts TO anon, authenticated;
