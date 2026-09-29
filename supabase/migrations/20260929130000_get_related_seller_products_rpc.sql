-- ============================================================================
-- Migracija 20260929130000: get_related_seller_products RPC
--
-- Efikasan server-side dohvat drugih proizvoda istog gazdinstva za stranu proizvoda.
-- 1. Eliminise over-fetching: vraca proizvode direktno iz view-a products_with_ratings
-- 2. Eliminise klijentsko filtriranje: u bazi iskljucuje trenutni proizvod
-- 3. Podrzava limit za minimalan payload na mobilnim mrezama (PWA)
-- 4. Dodaje parcijalni kompozitni indeks za brzu pretragu dostupnih proizvoda
-- ============================================================================

-- 1. Parcijalni kompozitni indeks za brzu pretragu dostupnih proizvoda gazdinstva
CREATE INDEX IF NOT EXISTS idx_products_seller_available_created
  ON public.products (seller_id, created_at DESC)
  WHERE available_now = true AND available_kg > 0;

-- 2. RPC funkcija get_related_seller_products
CREATE OR REPLACE FUNCTION public.get_related_seller_products(
  p_seller_id uuid,
  p_exclude_product_id uuid,
  p_limit int DEFAULT 6
)
RETURNS SETOF public.products_with_ratings
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT pwr.*
  FROM public.products_with_ratings pwr
  WHERE pwr.seller_id = p_seller_id
    AND pwr.id <> p_exclude_product_id
    AND pwr.available_now = true
    AND pwr.available_kg > 0
  ORDER BY pwr.created_at DESC
  LIMIT GREATEST(1, LEAST(p_limit, 20));
$$;

-- 3. Dozvola za anonimne i autentifikovane korisnike (javni katalog)
GRANT EXECUTE ON FUNCTION public.get_related_seller_products(uuid, uuid, int) TO anon, authenticated;
