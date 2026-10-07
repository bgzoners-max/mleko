-- ============================================================================
-- Migracija: Normalizacija dijakritika u pretrazi proizvoda i trigram podrška
-- Datum: 2026-10-07
-- 
-- 1. Kreira/osigurava ekstenzije unaccent i pg_trgm.
-- 2. Kreira GIN trigram indeks nad unaccent(lower(name)) za brzu sličnost i ILIKE.
-- 3. Kreira helper normalize_search_text za srpske znakove (uključujući đ/Đ -> dj/Dj).
-- 4. Ažurira search_vector trigger i podatke sa normalizovanim tekstom.
-- 5. Ažurira search_products_fts sa FTS + trigram/unaccent pokrivanjem.
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- 1. Immutable unaccent wrapper potreban za PostgreSQL indeksne izraze
CREATE OR REPLACE FUNCTION public.immutable_unaccent(t text)
RETURNS text
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
AS $$
  SELECT public.unaccent(coalesce(t, ''));
$$;

-- 2. Helper funkcija za srpsku normalizaciju (unaccent ne pokriva đ/Đ u difoltnim pravilima)
CREATE OR REPLACE FUNCTION public.normalize_search_text(t text)
RETURNS text
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
AS $$
  SELECT translate(
    public.immutable_unaccent(t),
    'đĐ',
    'djDj'
  );
$$;

-- 3. Trigram GIN indeks nad nazivom proizvoda sa uklonjenim akcentima
CREATE INDEX IF NOT EXISTS idx_products_name_trgm_unaccent
  ON public.products USING gin (public.immutable_unaccent(lower(name)) gin_trgm_ops);

-- 3. Ažuriranje trigger funkcije za search_vector
CREATE OR REPLACE FUNCTION public.products_search_vector_update()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public, extensions
AS $$
BEGIN
  NEW.search_vector := to_tsvector('simple',
    public.normalize_search_text(NEW.name) || ' ' ||
    public.immutable_unaccent(NEW.name) || ' ' ||
    public.normalize_search_text(NEW.description) || ' ' ||
    public.immutable_unaccent(NEW.description)
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_products_search_vector ON public.products;
CREATE TRIGGER trg_products_search_vector
  BEFORE INSERT OR UPDATE OF name, description ON public.products
  FOR EACH ROW EXECUTE FUNCTION public.products_search_vector_update();

-- 4. Backfill postojećih proizvoda
UPDATE public.products
SET search_vector = to_tsvector('simple',
  public.normalize_search_text(name) || ' ' ||
  public.immutable_unaccent(name) || ' ' ||
  public.normalize_search_text(description) || ' ' ||
  public.immutable_unaccent(description)
);

-- 5. RPC pretrage proizvoda sa podrškom za dijakritike i toleranciju tipfelera (pg_trgm + unaccent)
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
SET search_path = public, extensions
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
    COALESCE(r.avg_rating, 0)::numeric   AS avg_rating,
    COALESCE(r.review_count, 0)::bigint  AS review_count,
    COALESCE(o.order_count, 0)::bigint   AS order_count,
    COALESCE(prof.is_verified, false)    AS seller_is_verified
  FROM public.products p
  LEFT JOIN public.product_review_summary r ON r.product_id = p.id
  LEFT JOIN public.product_order_summary o ON o.product_id = p.id
  LEFT JOIN public.public_profiles prof ON prof.id = p.seller_id
  WHERE
    (
      p.search_vector @@ websearch_to_tsquery('simple', public.normalize_search_text(p_query))
      OR p.search_vector @@ websearch_to_tsquery('simple', public.immutable_unaccent(p_query))
      OR public.immutable_unaccent(lower(p.name)) ILIKE ('%' || public.immutable_unaccent(lower(p_query)) || '%')
      OR word_similarity(public.immutable_unaccent(lower(p_query)), public.immutable_unaccent(lower(p.name))) >= 0.35
      OR similarity(public.immutable_unaccent(lower(p.name)), public.immutable_unaccent(lower(p_query))) >= 0.3
    ) AND
    (p_category          IS NULL OR p.category     = p_category)             AND
    (p_region            IS NULL OR p.location     = p_region)               AND
    (p_available_now     IS NULL OR p.available_now = p_available_now)       AND
    (p_exclude_seller_id IS NULL OR p.seller_id   <> p_exclude_seller_id)
  ORDER BY
    ts_rank(p.search_vector, websearch_to_tsquery('simple', public.normalize_search_text(p_query))) DESC,
    word_similarity(public.immutable_unaccent(lower(p_query)), public.immutable_unaccent(lower(p.name))) DESC,
    similarity(public.immutable_unaccent(lower(p.name)), public.immutable_unaccent(lower(p_query))) DESC,
    p.created_at DESC
  LIMIT  p_limit
  OFFSET p_offset;
$$;

GRANT EXECUTE ON FUNCTION public.search_products_fts TO anon, authenticated;
