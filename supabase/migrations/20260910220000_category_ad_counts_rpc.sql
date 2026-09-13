-- ============================================================================
-- Migracija: Indeks i RPC funkcija za brojače aktivnih oglasa po kategorijama
-- Omogućava instant aggregaciju broja aktivnih oglasa u <2ms
-- ============================================================================

-- 1. Kompozitni indeks za ubrzavanje grupisanja po kategoriji za aktivne oglase
CREATE INDEX IF NOT EXISTS idx_classified_ads_status_category
ON public.classified_ads (status, category_id)
WHERE status = 'active';

-- 2. RPC funkcija dostupna klijentima (authenticated i anon) za dobavljanje brojača
CREATE OR REPLACE FUNCTION public.get_category_ad_counts()
RETURNS TABLE(category_id text, ad_count bigint)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    category_id,
    COUNT(*)::bigint AS ad_count
  FROM public.classified_ads
  WHERE status = 'active'
  GROUP BY category_id;
$$;

-- Dozvoli poziv i za anon i za authenticated uloge
GRANT EXECUTE ON FUNCTION public.get_category_ad_counts() TO anon, authenticated;
