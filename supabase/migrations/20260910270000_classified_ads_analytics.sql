-- Migracija za analitiku i performanse oglasa prodavaca
-- Datum: 2026-09-10

-- 1. Dodavanje kolona za interakcije u tabelu classified_ads
ALTER TABLE public.classified_ads
ADD COLUMN IF NOT EXISTS call_clicks_count INT NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS shares_count INT NOT NULL DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_classified_ads_call_clicks
ON public.classified_ads(call_clicks_count)
WHERE call_clicks_count > 0;

-- 2. Funkcija za atomsko inkrementiranje interakcija (poziv, deljenje)
CREATE OR REPLACE FUNCTION public.increment_classified_ad_interaction(
  ad_id UUID,
  p_type TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user UUID := auth.uid();
  v_owner UUID;
  v_status TEXT;
BEGIN
  -- 1. Pronađi vlasnika i status oglasa
  SELECT user_id, status
    INTO v_owner, v_status
  FROM public.classified_ads
  WHERE id = ad_id;

  IF NOT FOUND THEN
    RETURN;
  END IF;

  -- 2. Samo aktivni oglasi beleže interakcije
  IF v_status <> 'active' THEN
    RETURN;
  END IF;

  -- 3. Vlasnik oglasa ne povećava sopstvene brojače
  IF v_user IS NOT NULL AND v_user = v_owner THEN
    RETURN;
  END IF;

  -- 4. Inkrementiraj odgovarajući brojač
  IF p_type = 'call' THEN
    UPDATE public.classified_ads
    SET call_clicks_count = call_clicks_count + 1
    WHERE id = ad_id;
  ELSIF p_type = 'share' THEN
    UPDATE public.classified_ads
    SET shares_count = shares_count + 1
    WHERE id = ad_id;
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.increment_classified_ad_interaction(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.increment_classified_ad_interaction(UUID, TEXT) TO anon, authenticated, service_role;

-- 3. RPC funkcija za agregiranu analitiku prodavca
CREATE OR REPLACE FUNCTION public.get_seller_classifieds_stats(p_seller_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user UUID := auth.uid();
  v_result JSONB;
BEGIN
  -- Zaštita: samo prodavac može dobiti svoju statistiku (ili service_role)
  IF v_user IS NULL OR v_user <> p_seller_id THEN
    RAISE EXCEPTION 'Nedozvoljen pristup analitici.';
  END IF;

  WITH stats AS (
    SELECT
      count(*)::INT AS total_ads,
      count(*) FILTER (WHERE status = 'active')::INT AS active_ads,
      count(*) FILTER (WHERE status = 'sold')::INT AS sold_ads,
      COALESCE(sum(views_count), 0)::INT AS total_views,
      COALESCE(sum(call_clicks_count), 0)::INT AS total_call_clicks,
      COALESCE(sum(shares_count), 0)::INT AS total_shares,
      count(*) FILTER (WHERE is_featured = true AND (featured_until IS NULL OR featured_until > now()))::INT AS featured_count
    FROM public.classified_ads
    WHERE user_id = p_seller_id
  ),
  top_ad AS (
    SELECT
      id,
      title,
      views_count,
      call_clicks_count,
      price,
      currency,
      CASE WHEN array_length(images, 1) > 0 THEN images[1] ELSE NULL END AS image
    FROM public.classified_ads
    WHERE user_id = p_seller_id
    ORDER BY views_count DESC, created_at DESC
    LIMIT 1
  )
  SELECT jsonb_build_object(
    'total_ads', s.total_ads,
    'active_ads', s.active_ads,
    'sold_ads', s.sold_ads,
    'total_views', s.total_views,
    'total_call_clicks', s.total_call_clicks,
    'total_shares', s.total_shares,
    'featured_count', s.featured_count,
    'top_ad', CASE
      WHEN t.id IS NOT NULL THEN jsonb_build_object(
        'id', t.id,
        'title', t.title,
        'views_count', t.views_count,
        'call_clicks_count', t.call_clicks_count,
        'price', t.price,
        'currency', t.currency,
        'image', t.image
      )
      ELSE NULL
    END
  ) INTO v_result
  FROM stats s
  LEFT JOIN top_ad t ON true;

  RETURN COALESCE(v_result, '{}'::JSONB);
END;
$$;

REVOKE ALL ON FUNCTION public.get_seller_classifieds_stats(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_seller_classifieds_stats(UUID) TO authenticated, service_role;
