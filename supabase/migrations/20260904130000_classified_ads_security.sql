-- ============================================================================
-- Migracija 20260904130000: Sigurnosne izmene za classified_ads
--  1. Gardija da views_count ne može da se postavi/izmeni sa klijenta
--  2. Validacija osnovnih pravila oglasa (cena, broj slika, naslov)
--  3. Rate-limit + autorizacija za increment_classified_ad_views RPC
-- ============================================================================

-- 1) views_count: uvek 0 na INSERT, na UPDATE zadrži postojeću vrednost
CREATE OR REPLACE FUNCTION public.classified_ad_guard_views()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    NEW.views_count := 0;
  ELSIF TG_OP = 'UPDATE' THEN
    NEW.views_count := OLD.views_count;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_classified_ad_guard_views ON public.classified_ads;
CREATE TRIGGER trg_classified_ad_guard_views
  BEFORE INSERT OR UPDATE ON public.classified_ads
  FOR EACH ROW EXECUTE FUNCTION public.classified_ad_guard_views();

-- 2) Validacija osnovnih pravila oglasa (server-side)
CREATE OR REPLACE FUNCTION public.classified_ad_validate()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.price_type IN ('free', 'call') THEN
    NEW.price := 0;
  END IF;
  IF coalesce(array_length(NEW.images, 1), 0) > 8 THEN
    RAISE EXCEPTION 'Maksimalan broj slika je 8.';
  END IF;
  IF length(trim(NEW.title)) < 3 THEN
    RAISE EXCEPTION 'Naslov oglasa mora imati bar 3 karaktera.';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_classified_ad_validate ON public.classified_ads;
CREATE TRIGGER trg_classified_ad_validate
  BEFORE INSERT OR UPDATE ON public.classified_ads
  FOR EACH ROW EXECUTE FUNCTION public.classified_ad_validate();

-- 3) Kolona za jednostavan rate-limit pregleda (bez dodatne tabele)
ALTER TABLE public.classified_ads
  ADD COLUMN IF NOT EXISTS last_view_at timestamptz;

-- Bezbedniji increment_classified_ad_views:
--  - zahteva prijavljenog korisnika (auth.uid() != null)
--  - radi samo na aktivnim oglasima
--  - ne dozvoljava više od jednog pregleda u 60 sekundi po oglasu
CREATE OR REPLACE FUNCTION public.increment_classified_ad_views(ad_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user  uuid := auth.uid();
  v_status text;
  v_last  timestamptz;
BEGIN
  IF v_user IS NULL THEN
    RAISE EXCEPTION 'Niste prijavljeni.';
  END IF;

  SELECT status, last_view_at
    INTO v_status, v_last
  FROM public.classified_ads
  WHERE id = ad_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN;
  END IF;

  IF v_status <> 'active' THEN
    RETURN;
  END IF;

  -- Osnovni rate-limit: max 1 pregled / 60 s po oglasu
  IF v_last IS NOT NULL AND v_last > now() - interval '60 seconds' THEN
    RETURN;
  END IF;

  UPDATE public.classified_ads
  SET views_count = views_count + 1, last_view_at = now()
  WHERE id = ad_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.increment_classified_ad_views(uuid)
  FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.increment_classified_ad_views(uuid)
  TO authenticated;
