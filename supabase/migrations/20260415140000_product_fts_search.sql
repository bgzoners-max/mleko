-- Full-text pretraga proizvoda
-- Unapređenje od ILIKE (samo name, bez indeksa) na FTS (name + description, GIN index, rangiranje)
-- Uključuje unaccent za srpske dijakritičke znakove (cajevi = Čajevi, kajmak = Kajmak)

-- 1. Ekstenzija za dijakritike
CREATE EXTENSION IF NOT EXISTS unaccent;

-- 2. search_vector kolona
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS search_vector tsvector;

-- 3. Trigger funkcija
CREATE OR REPLACE FUNCTION products_search_vector_update()
RETURNS trigger AS $$
BEGIN
  NEW.search_vector := to_tsvector('simple',
    unaccent(coalesce(NEW.name, '')) || ' ' ||
    unaccent(coalesce(NEW.description, ''))
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Trigger na INSERT i UPDATE name/description
DROP TRIGGER IF EXISTS trg_products_search_vector ON public.products;
CREATE TRIGGER trg_products_search_vector
  BEFORE INSERT OR UPDATE OF name, description ON public.products
  FOR EACH ROW EXECUTE FUNCTION products_search_vector_update();

-- 5. Backfill svih postojećih redova
UPDATE public.products
SET search_vector = to_tsvector('simple',
  unaccent(coalesce(name, '')) || ' ' ||
  unaccent(coalesce(description, ''))
);

-- 6. GIN index za brzu pretragu (zamenjuje seq scan koji koristi ILIKE)
CREATE INDEX IF NOT EXISTS products_search_vector_gin
  ON public.products USING gin(search_vector);

-- 7. RPC za FTS pretragu sa rangiranjem relevantnosti
--    Koristi websearch_to_tsquery sintaksu: "domaći sir" = domaći AND sir
--    Vraća isti shape kao products_with_ratings, sortiran po relevantnosti
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
