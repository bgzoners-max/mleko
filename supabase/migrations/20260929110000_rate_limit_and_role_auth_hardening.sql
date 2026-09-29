-- ============================================================================
-- Migracija: 20260929110000_rate_limit_and_role_auth_hardening.sql
-- Očvršćavanje rate-limitinga i provere administratorske uloge
--
-- 1. RATE LIMIT IDENTIFIKATOR (SEC-RL-01):
--    - Prethodno se pozivalac identifikovao ISKLJUČIVO po IP adresi iz header-a
--      (cf-connecting-ip / x-forwarded-for / x-real-ip) koje klijent može da
--      falsifikuje, čime je limit (npr. 8 telefona / 5 min) mogao biti zaobiđen
--      rotacijom header vrednosti.
--    - Sada: prijavljeni korisnici se identifikuju po auth.uid() (nefalsifikabilno),
--      a anonimni po IP adresi uz STROGU validaciju IPv4/IPv6 formata.
--
-- 2. PROVERA ADMINISTRATORSKE ULOGE (SEC-RL-02):
--    - Prethodno se "auth.uid() IS NULL" tretiralo kao admin/servisni kontekst,
--      što poistovećuje 'service_role' (legitimno) sa 'anon' (bez JWT-a — takođe NULL uid).
--    - Sada se koristi auth.role() eksplicitno: 'service_role' ili sistemski
--      kontekst (NULL) = pouzdan, 'authenticated' = provera is_admin(), a
--      'anon' i sve ostale uloge = NIKADA admin.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. OČVRŠĆEN RATE LIMIT: uid za prijavljene, validirana IP za anonimne
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.check_and_record_auth_rate_limit(
  p_endpoint TEXT,
  p_max_requests INT DEFAULT 10,
  p_window_seconds INT DEFAULT 300
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_headers JSONB;
  v_uid UUID := auth.uid();
  v_raw_ip TEXT;
  v_identifier TEXT;
  v_now TIMESTAMPTZ := clock_timestamp();
  v_window_start TIMESTAMPTZ;
  v_count INT;
BEGIN
  -- Identifikator pozivaoca:
  --  - Prijavljeni korisnik -> 'uid:<uuid>' (UUID se ne može falsifikovati)
  --  - Anonimni -> 'ip:<adresa>', ali samo ako je IP u validnom IPv4/IPv6
  --    formatu; proizvoljni stringovi se odbacuju (sprečava trivijalnu rotaciju).
  IF v_uid IS NOT NULL THEN
    v_identifier := 'uid:' || v_uid::text;
  ELSE
    BEGIN
      v_headers := current_setting('request.headers', true)::jsonb;
    EXCEPTION WHEN OTHERS THEN
      v_headers := '{}'::jsonb;
    END;

    v_raw_ip := coalesce(
      nullif(trim(v_headers->>'cf-connecting-ip'), ''),
      nullif(trim(split_part(v_headers->>'x-forwarded-for', ',', 1)), ''),
      nullif(trim(v_headers->>'x-real-ip'), '')
    );

    -- Stroga validacija: prihvati samo IPv4 ili IPv6 literal.
    IF v_raw_ip IS NULL
       OR NOT (
            v_raw_ip ~ '^[0-9]{1,3}(\.[0-9]{1,3}){3}$'      -- IPv4
         OR v_raw_ip ~ '^[0-9a-fA-F:]*:[0-9a-fA-F:]*$'       -- IPv6 (mora sadržati ':')
       )
    THEN
      v_identifier := 'ip:unknown_client';
    ELSE
      v_identifier := 'ip:' || v_raw_ip;
    END IF;
  END IF;

  -- 1. Determinističko inline čišćenje za pozivajući identifikator (kompozitni indeks)
  DELETE FROM public.auth_rate_limits
  WHERE identifier = v_identifier
    AND endpoint = p_endpoint
    AND window_start < v_now - (p_window_seconds || ' seconds')::interval;

  -- 2. Brzo globalno čišćenje starijih zapisa (10% verovatnoće po pozivu)
  IF (random() < 0.10) THEN
    PERFORM public.cleanup_expired_auth_rate_limits(INTERVAL '1 hour');
  END IF;

  -- 3. Provera postojećeg aktivnog prozora
  SELECT window_start, request_count
  INTO v_window_start, v_count
  FROM public.auth_rate_limits
  WHERE identifier = v_identifier
    AND endpoint = p_endpoint
    AND window_start > v_now - (p_window_seconds || ' seconds')::interval
  ORDER BY window_start DESC
  LIMIT 1
  FOR UPDATE;

  IF FOUND THEN
    IF v_count >= p_max_requests THEN
      RETURN false; -- Prekoračen limit
    END IF;

    UPDATE public.auth_rate_limits
    SET request_count = request_count + 1
    WHERE identifier = v_identifier
      AND endpoint = p_endpoint
      AND window_start = v_window_start;
  ELSE
    INSERT INTO public.auth_rate_limits (identifier, endpoint, request_count, window_start)
    VALUES (v_identifier, p_endpoint, 1, v_now);
  END IF;

  RETURN true;
END;
$$;


-- ----------------------------------------------------------------------------
-- 2. POMOĆNA FUNKCIJA: da li je pozivalac admin ili service_role/sistemski?
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_admin_or_service_role()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role TEXT := auth.role();
BEGIN
  -- service_role (edge funkcije / pg_net trigger-i) ili sistemski kontekst
  -- BEZ request-a (psql, owner trigger, seed) smatraju se pouzdanim.
  IF v_role IS NULL OR v_role = 'service_role' THEN
    RETURN true;
  END IF;

  -- Autentifikovani korisnik: proveri is_admin flag na sopstvenom profilu.
  IF v_role = 'authenticated' THEN
    RETURN public.is_admin();
  END IF;

  -- 'anon' i bilo koja druga uloga NISU admini.
  RETURN false;
END;
$$;

REVOKE ALL ON FUNCTION public.is_admin_or_service_role() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_admin_or_service_role() TO authenticated, service_role;

-- ----------------------------------------------------------------------------
-- 3. OČVRŠĆAVANJE TRIGGER-A: eksplicitna provera role umesto "auth.uid() IS NULL"
--    Napomena: trigeri se i dalje vezuju za ista imena funkcija, pa nije
--    potrebno ponovo ih kreirati (CREATE OR REPLACE automatski menja telo).
-- ----------------------------------------------------------------------------

-- 3.1 PROFILES: zaštita is_admin / is_verified / id / created_at
CREATE OR REPLACE FUNCTION public.protect_profile_sensitive_columns()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_is_caller_admin BOOLEAN := public.is_admin_or_service_role();
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Običan korisnik ne sme sam sebi postaviti is_admin niti is_verified pri registraciji
    IF NOT v_is_caller_admin THEN
      NEW.is_admin := false;
      NEW.is_verified := false;
    ELSE
      NEW.is_admin := COALESCE(NEW.is_admin, false);
      NEW.is_verified := COALESCE(NEW.is_verified, false);
    END IF;
    NEW.created_at := COALESCE(NEW.created_at, now());
    NEW.updated_at := COALESCE(NEW.updated_at, now());
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' THEN
    -- ID i created_at su strogo nepromenjivi
    NEW.id := OLD.id;
    NEW.created_at := OLD.created_at;
    NEW.updated_at := now();

    -- Zaštita kolone is_admin: samo administrator sme menjati admin status
    IF NEW.is_admin IS DISTINCT FROM OLD.is_admin THEN
      IF NOT v_is_caller_admin THEN
        RAISE EXCEPTION USING
          ERRCODE = '42501',
          MESSAGE = 'Nemate administratorska ovlašćenja za promenu admin statusa.';
      END IF;
    END IF;

    -- Zaštita kolone is_verified: samo administrator sme verifikovati prodavca
    IF NEW.is_verified IS DISTINCT FROM OLD.is_verified THEN
      IF NOT v_is_caller_admin THEN
        RAISE EXCEPTION USING
          ERRCODE = '42501',
          MESSAGE = 'Nemate administratorska ovlašćenja za promenu statusa verifikacije.';
      END IF;
    END IF;

    RETURN NEW;
  END IF;

  RETURN NEW;
END;
$$;

-- 3.2 CLASSIFIED_ADS: zaštita bedževa, analitike i user_id
CREATE OR REPLACE FUNCTION public.protect_classified_ad_administrative_columns()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_is_caller_admin BOOLEAN := public.is_admin_or_service_role();
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Novi oglas koji postavlja običan korisnik ne može imati promo bedževe niti lažiranu analitiku
    IF NOT v_is_caller_admin THEN
      NEW.is_featured := false;
      NEW.featured_until := NULL;
      NEW.is_urgent := false;
      NEW.reports_count := 0;
      NEW.call_clicks_count := 0;
      NEW.views_count := 0;
    END IF;
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' THEN
    -- Spreči otimanje oglasa (user_id se nikada ne menja)
    NEW.user_id := OLD.user_id;

    -- Samo administrator može menjati istaknutost ili resetovati prijave
    IF NOT v_is_caller_admin THEN
      NEW.is_featured := OLD.is_featured;
      NEW.featured_until := OLD.featured_until;
      NEW.is_urgent := OLD.is_urgent;
      NEW.reports_count := OLD.reports_count;
      NEW.call_clicks_count := OLD.call_clicks_count;
      NEW.views_count := OLD.views_count;
    END IF;
    RETURN NEW;
  END IF;

  RETURN NEW;
END;
$$;

