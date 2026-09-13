-- ============================================================================
-- Migration: 20260910170000_classified_ad_views_bot_detection.sql
-- Description:
--   1. Filter bot visits from classified ad view counter (User-Agent detection).
--   2. Extend deduplication window from 1h to 24h.
--   3. Combine IP + User-Agent in anonymous viewer hash for more accurate NAT tracking.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.increment_classified_ad_views(
  ad_id UUID,
  p_viewer_id TEXT DEFAULT NULL
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
  v_headers JSONB;
  v_ua TEXT;
  v_ip TEXT;
  v_viewer_hash TEXT;
BEGIN
  -- 1. Pronađi vlasnika i status oglasa
  SELECT user_id, status
    INTO v_owner, v_status
  FROM public.classified_ads
  WHERE id = ad_id;

  IF NOT FOUND THEN
    RETURN;
  END IF;

  -- 2. Samo aktivni oglasi dobijaju preglede
  IF v_status <> 'active' THEN
    RETURN;
  END IF;

  -- 3. Vlasnik oglasa ne povećava sopstveni brojač pregleda
  IF v_user IS NOT NULL AND v_user = v_owner THEN
    RETURN;
  END IF;

  -- 4. Detekcija User-Agent-a i blokada botova/crawlere/scrapers/social previewera
  BEGIN
    v_headers := current_setting('request.headers', true)::jsonb;
    v_ua := lower(COALESCE(v_headers->>'user-agent', ''));
  EXCEPTION WHEN OTHERS THEN
    v_headers := '{}'::jsonb;
    v_ua := '';
  END;

  -- Filtriraj poznate botove, crawlera, scrapere i link preview servise
  IF v_ua ~* '(bot|crawl|spider|slurp|curl|wget|python|scrapy|aiohttp|httpx|headless|chrome-lighthouse|lighthouse|preview|scraper|facebookexternalhit|whatsapp|telegrambot|discordbot|slackbot|archive\.org|semrush|ahrefs|bingbot|googlebot|yandex|bytespider)' THEN
    RETURN;
  END IF;

  -- Provera viewer_id parametra na bot obrasce
  IF p_viewer_id IS NOT NULL AND p_viewer_id ~* '^(bot|spider|crawler)' THEN
    RETURN;
  END IF;

  -- 5. Odredi identifikator posetioca (viewer_hash)
  IF v_user IS NOT NULL THEN
    v_viewer_hash := 'usr:' || v_user::text;
  ELSIF p_viewer_id IS NOT NULL AND length(trim(p_viewer_id)) > 0 THEN
    v_viewer_hash := 'dev:' || md5(trim(p_viewer_id));
  ELSE
    v_ip := COALESCE(
      v_headers->>'cf-connecting-ip',
      v_headers->>'x-real-ip',
      split_part(v_headers->>'x-forwarded-for', ',', 1),
      'unknown'
    );
    -- Kombinujemo IP i User-Agent kako posetioci sa istog NAT/IP ali različitih uređaja ne bi delili limit
    v_viewer_hash := 'ip_ua:' || md5(v_ip || ':' || v_ua);
  END IF;

  -- 6. Deduplikacija: Ako je posetilac već pogledao oglas u proteklih 24 sata, ignoriši
  IF EXISTS (
    SELECT 1 FROM public.classified_ad_views
    WHERE classified_ad_views.ad_id = increment_classified_ad_views.ad_id
      AND classified_ad_views.viewer_hash = v_viewer_hash
      AND classified_ad_views.last_viewed_at > now() - INTERVAL '24 hours'
  ) THEN
    RETURN;
  END IF;

  -- 7. Zabeleži / osveži vreme pregleda u tabeli deduplikacije
  INSERT INTO public.classified_ad_views (ad_id, viewer_hash, last_viewed_at)
  VALUES (increment_classified_ad_views.ad_id, v_viewer_hash, now())
  ON CONFLICT (ad_id, viewer_hash)
  DO UPDATE SET last_viewed_at = now();

  -- 8. Inkrementiraj stvarni brojač pregleda na oglasu
  UPDATE public.classified_ads
  SET views_count = views_count + 1,
      last_view_at = now()
  WHERE id = increment_classified_ad_views.ad_id;
END;
$$;

REVOKE ALL ON FUNCTION public.increment_classified_ad_views(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.increment_classified_ad_views(UUID, TEXT) TO anon, authenticated, service_role;
