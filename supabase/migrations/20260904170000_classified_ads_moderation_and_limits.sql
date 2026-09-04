-- ============================================================================
-- Migracija 20260904170000: Moderacija, rate-limit i normalizacija gradova za classified_ads
--  1. Osiguranje funkcije is_admin()
--  2. Proširenje statusa oglasa (podrška za 'rejected' i 'flagged')
--  3. Normalizacija naziva grada (trim + initcap)
--  4. Anti-spam rate-limit na INSERT (max 20 oglasa/24h, min razmak 10s za ne-admine)
--  5. Dozvola administratorima (is_admin) za moderaciju (UPDATE/DELETE) oglasa
--  6. RPC funkcija admin_moderate_classified_ad
-- ============================================================================

-- 1) Osiguraj funkciju is_admin()
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND is_admin = true
  );
END;
$$;
REVOKE ALL ON FUNCTION public.is_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated, service_role;

-- 2) Proširenje statusa oglasa
DO $$
BEGIN
  ALTER TABLE public.classified_ads DROP CONSTRAINT IF EXISTS classified_ads_status_check;
  ALTER TABLE public.classified_ads ADD CONSTRAINT classified_ads_status_check
    CHECK (status IN ('active', 'sold', 'archived', 'rejected', 'flagged'));
EXCEPTION WHEN OTHERS THEN
  NULL;
END;
$$;

-- 3) Normalizacija postojećih gradova u bazi
UPDATE public.classified_ads
SET city = trim(initcap(city))
WHERE city IS NOT NULL;

-- 4) Ažurirana funkcija validacije sa rate-limitom i normalizacijom grada
CREATE OR REPLACE FUNCTION public.classified_ad_validate()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Normalizacija naziva grada
  IF NEW.city IS NOT NULL THEN
    NEW.city := trim(initcap(NEW.city));
    IF length(NEW.city) < 2 THEN
      RAISE EXCEPTION 'Naziv grada ili mesta mora imati bar 2 karaktera.';
    END IF;
  END IF;

  -- Besplatni ili poziv oglasi imaju cenu 0
  IF NEW.price_type IN ('free', 'call') THEN
    NEW.price := 0;
  END IF;

  -- Maksimalan broj slika je 8
  IF coalesce(array_length(NEW.images, 1), 0) > 8 THEN
    RAISE EXCEPTION 'Maksimalan broj slika je 8.';
  END IF;

  -- Minimalna dužina naslova
  IF length(trim(NEW.title)) < 3 THEN
    RAISE EXCEPTION 'Naslov oglasa mora imati bar 3 karaktera.';
  END IF;

  -- Rate-limit za kreiranje novih oglasa (samo na INSERT i samo ako korisnik nije admin)
  IF TG_OP = 'INSERT' AND NOT public.is_admin() THEN
    -- A) Minimalni razmak između dva oglasa: 10 sekundi (sprečava dvostruki submit i botove)
    IF EXISTS (
      SELECT 1 FROM public.classified_ads
      WHERE user_id = NEW.user_id
        AND created_at > now() - INTERVAL '10 seconds'
    ) THEN
      RAISE EXCEPTION 'Sačekajte nekoliko sekundi pre objave sledećeg oglasa.';
    END IF;

    -- B) Dnevni limit: maksimalno 20 oglasa u 24 časa po korisniku
    IF (
      SELECT count(*)
      FROM public.classified_ads
      WHERE user_id = NEW.user_id
        AND created_at > now() - INTERVAL '24 hours'
    ) >= 20 THEN
      RAISE EXCEPTION 'Dostigli ste dnevni limit za postavljanje oglasa (maksimalno 20 oglasa za 24h).';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_classified_ad_validate ON public.classified_ads;
CREATE TRIGGER trg_classified_ad_validate
  BEFORE INSERT OR UPDATE ON public.classified_ads
  FOR EACH ROW EXECUTE FUNCTION public.classified_ad_validate();

-- 5) RLS: Dozvoli i administratorima izmenu i brisanje oglasa radi moderacije
DROP POLICY IF EXISTS "classified_ads_update_owner" ON public.classified_ads;
CREATE POLICY "classified_ads_update_owner"
    ON public.classified_ads FOR UPDATE
    USING (auth.uid() = user_id OR public.is_admin())
    WITH CHECK (auth.uid() = user_id OR public.is_admin());

DROP POLICY IF EXISTS "classified_ads_delete_owner" ON public.classified_ads;
CREATE POLICY "classified_ads_delete_owner"
    ON public.classified_ads FOR DELETE
    USING (auth.uid() = user_id OR public.is_admin());

-- 6) RPC za administraciju/moderaciju oglasa
CREATE OR REPLACE FUNCTION public.admin_moderate_classified_ad(
    p_ad_id UUID,
    p_new_status TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Pristup odbijen: samo administrator može moderisati oglase.';
  END IF;

  IF p_new_status NOT IN ('active', 'archived', 'rejected') THEN
    RAISE EXCEPTION 'Nevažeći status moderacije: %', p_new_status;
  END IF;

  UPDATE public.classified_ads
  SET status = p_new_status,
      updated_at = now()
  WHERE id = p_ad_id;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_moderate_classified_ad FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_moderate_classified_ad TO authenticated, service_role;
