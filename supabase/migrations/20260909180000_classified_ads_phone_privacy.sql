-- ============================================================================
-- Migracija 20260909180000: Privatnost telefona na malim oglasima (phone_public)
--
-- 1. Oduzimanje SELECT prava nad kolonom phone tabele classified_ads za
--    anon i authenticated uloge (sprečava curenje preko GET /rest/v1/classified_ads?select=phone).
-- 2. SECURITY DEFINER funkcija get_classified_ad_phone za bezbedno čitanje telefona
--    samo kada je phone_public = true (ili je pregledač vlasnik/admin).
-- 3. Privacy VIEW public_classified_ads (analogno public_profiles) sa
--    automatskim maskiranjem telefona na nivou reda i kolone.
-- ============================================================================

-- 1. Oduzmi direktno SELECT pravo nad kolonom phone sa osnovne tabele
REVOKE SELECT (phone) ON public.classified_ads FROM anon, authenticated;

-- Osiguraj da ulogovani korisnici mogu upisati svoj telefon pri unosu i izmeni
GRANT INSERT (phone), UPDATE (phone) ON public.classified_ads TO authenticated;

-- 2. RPC funkcija za kontrolisano čitanje broja telefona
CREATE OR REPLACE FUNCTION public.get_classified_ad_phone(p_ad_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_phone TEXT;
  v_phone_public BOOLEAN;
  v_user_id UUID;
  v_status TEXT;
BEGIN
  SELECT phone, phone_public, user_id, status
  INTO v_phone, v_phone_public, v_user_id, v_status
  FROM public.classified_ads
  WHERE id = p_ad_id;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  -- Vlasnik oglasa i admin uvek vide telefon (čak i ako je oglas prodat ili arhiviran)
  IF auth.uid() = v_user_id OR public.is_admin() THEN
    RETURN v_phone;
  END IF;

  -- Posetioci vide telefon samo ako je oglas aktivan i vlasnik je dozvolio javni prikaz
  IF v_status = 'active' AND v_phone_public THEN
    RETURN v_phone;
  END IF;

  RETURN NULL;
END;
$$;

-- Dozvoli pozivanje funkcije anonimnim i prijavljenim korisnicima
REVOKE ALL ON FUNCTION public.get_classified_ad_phone(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_classified_ad_phone(UUID) TO anon, authenticated;

-- 3. Privacy VIEW sa maskiranom kolonom telefona (analogno public_profiles)
CREATE OR REPLACE VIEW public.public_classified_ads AS
SELECT
  ca.id,
  ca.user_id,
  ca.title,
  ca.description,
  ca.price,
  ca.currency,
  ca.price_type,
  ca.category_id,
  ca.condition,
  ca.images,
  ca.city,
  CASE 
    WHEN (
      (ca.status = 'active' AND ca.phone_public) 
      OR auth.uid() = ca.user_id 
      OR public.is_admin()
    ) 
    THEN ca.phone 
    ELSE NULL 
  END AS phone,
  ca.phone_public,
  ca.status,
  ca.views_count,
  ca.created_at,
  ca.updated_at
FROM public.classified_ads ca
WHERE ca.status = 'active' OR auth.uid() = ca.user_id OR public.is_admin();

GRANT SELECT ON public.public_classified_ads TO anon, authenticated;
