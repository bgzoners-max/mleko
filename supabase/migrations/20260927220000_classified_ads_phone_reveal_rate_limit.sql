-- ============================================================================
-- Migracija: Zaštita brojeva telefona od botova i automatskih scrapera
-- Datum: 2026-09-27
-- Opis:
--   1. Očvršćavanje RPC funkcije public.get_classified_ad_phone sa rate limitingom.
--   2. Posetioci i neregistrovani botovi su ograničeni na maksimalno 8 pregleda
--      telefona u 5 minuta (korišćenjem tabele auth_rate_limits i klijentske IP adrese).
--   3. Vlasnik oglasa i admini uvek imaju neometan pristup bez ograničenja.
-- ============================================================================

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
  v_allowed BOOLEAN;
BEGIN
  SELECT phone, phone_public, user_id, status
  INTO v_phone, v_phone_public, v_user_id, v_status
  FROM public.classified_ads
  WHERE id = p_ad_id;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  -- 1. Vlasnik oglasa i admin uvek vide telefon (čak i ako je oglas prodat ili arhiviran)
  IF auth.uid() = v_user_id OR public.is_admin() THEN
    RETURN v_phone;
  END IF;

  -- 2. Zaštita od botova: proveravamo rate limit za eksterne posetioce (max 8 zahteva u 5 minuta)
  v_allowed := public.check_and_record_auth_rate_limit('classified_ad_phone', 8, 300);
  IF NOT v_allowed THEN
    RAISE EXCEPTION 'Dostigli ste limit za pregled brojeva telefona. Pokušajte ponovo kasnije.'
      USING ERRCODE = 'P0001';
  END IF;

  -- 3. Posetioci vide telefon samo ako je oglas aktivan i vlasnik je dozvolio javni prikaz
  IF v_status = 'active' AND v_phone_public THEN
    RETURN v_phone;
  END IF;

  RETURN NULL;
END;
$$;

-- Dozvoli pozivanje funkcije anonimnim i prijavljenim korisnicima
REVOKE ALL ON FUNCTION public.get_classified_ad_phone(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_classified_ad_phone(UUID) TO anon, authenticated;
