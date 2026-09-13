-- ============================================================================
-- Migracija: Zaštita Auth Sistema od Enumeracije Naloga i Rate Limiting
-- Datum: 2026-09-10
-- Opis:
--   1. Tabela auth_rate_limits za praćenje broja zahteva po IP adresi.
--   2. check_and_record_auth_rate_limit pomoćna funkcija.
--   3. Očvršćavanje funkcija check_email_exists i check_phone_exists
--      sa format-validacijom i limitom od maksimalno 10 zahteva u 5 minuta.
-- ============================================================================

-- 1. Tabela za praćenje auth rate limita
CREATE TABLE IF NOT EXISTS public.auth_rate_limits (
  id BIGSERIAL PRIMARY KEY,
  identifier TEXT NOT NULL,
  endpoint TEXT NOT NULL,
  request_count INT NOT NULL DEFAULT 1,
  window_start TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);

CREATE INDEX IF NOT EXISTS idx_auth_rate_limits_lookup
  ON public.auth_rate_limits (identifier, endpoint, window_start);

ALTER TABLE public.auth_rate_limits ENABLE ROW LEVEL SECURITY;

-- Dozvoli pristup samo service_role; anon i authenticated nemaju direktan pristup tabeli
DROP POLICY IF EXISTS "Service role manages auth rate limits" ON public.auth_rate_limits;
CREATE POLICY "Service role manages auth rate limits"
  ON public.auth_rate_limits
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- 2. Pomoćna funkcija za proveru i evidentiranje rate limita
CREATE OR REPLACE FUNCTION public.check_and_record_auth_rate_limit(
  p_endpoint TEXT,
  p_max_requests INT DEFAULT 10,
  p_window_seconds INT DEFAULT 300
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_headers JSONB;
  v_ip TEXT;
  v_now TIMESTAMPTZ := clock_timestamp();
  v_window_start TIMESTAMPTZ;
  v_count INT;
BEGIN
  BEGIN
    v_headers := current_setting('request.headers', true)::jsonb;
  EXCEPTION WHEN OTHERS THEN
    v_headers := '{}'::jsonb;
  END;

  -- Izdvajanje klijentske IP adrese iz standardnih proksija (Cloudflare, Supabase pooler)
  v_ip := coalesce(
    nullif(trim(v_headers->>'cf-connecting-ip'), ''),
    nullif(trim(split_part(v_headers->>'x-forwarded-for', ',', 1)), ''),
    nullif(trim(v_headers->>'x-real-ip'), ''),
    'unknown_client'
  );

  -- Periodično čišćenje starih unosa (5% šanse po pozivu da se obrišu unosi stariji od 1 sata)
  IF (random() < 0.05) THEN
    DELETE FROM public.auth_rate_limits
    WHERE window_start < v_now - INTERVAL '1 hour';
  END IF;

  -- Provera postojećeg aktivnog prozora
  SELECT window_start, request_count
  INTO v_window_start, v_count
  FROM public.auth_rate_limits
  WHERE identifier = v_ip
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
    WHERE identifier = v_ip
      AND endpoint = p_endpoint
      AND window_start = v_window_start;
  ELSE
    INSERT INTO public.auth_rate_limits (identifier, endpoint, request_count, window_start)
    VALUES (v_ip, p_endpoint, 1, v_now);
  END IF;

  RETURN true;
END;
$$;

REVOKE ALL ON FUNCTION public.check_and_record_auth_rate_limit(TEXT, INT, INT) FROM PUBLIC;

-- 3. Očvršćena funkcija check_email_exists
CREATE OR REPLACE FUNCTION public.check_email_exists(p_email TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_trimmed TEXT;
  v_allowed BOOLEAN;
BEGIN
  IF p_email IS NULL THEN
    RETURN false;
  END IF;

  v_trimmed := lower(trim(p_email));

  -- Osnovna provera formata emaila bez upita u bazu ako je format nevalidan
  IF length(v_trimmed) < 5 OR v_trimmed NOT LIKE '%@%.%' THEN
    RETURN false;
  END IF;

  -- Provera rate limita: maks 10 provera u 5 minuta (300s)
  v_allowed := public.check_and_record_auth_rate_limit('check_email_exists', 10, 300);
  IF NOT v_allowed THEN
    RAISE EXCEPTION 'Prekoračen dozvoljeni broj provera. Molimo sačekajte nekoliko minuta.'
      USING ERRCODE = 'P0001';
  END IF;

  -- Provera postojanja u profilima (ili auth.users)
  RETURN EXISTS (
    SELECT 1 FROM public.profiles WHERE lower(email) = v_trimmed
  );
END;
$$;

REVOKE ALL ON FUNCTION public.check_email_exists(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.check_email_exists(TEXT) TO anon, authenticated;

-- 4. Očvršćena funkcija check_phone_exists
CREATE OR REPLACE FUNCTION public.check_phone_exists(p_phone TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_trimmed TEXT;
  v_allowed BOOLEAN;
BEGIN
  IF p_phone IS NULL THEN
    RETURN false;
  END IF;

  v_trimmed := trim(p_phone);

  -- Broj telefona mora imati barem 6 karaktera
  IF length(v_trimmed) < 6 THEN
    RETURN false;
  END IF;

  -- Provera rate limita: maks 10 provera u 5 minuta (300s)
  v_allowed := public.check_and_record_auth_rate_limit('check_phone_exists', 10, 300);
  IF NOT v_allowed THEN
    RAISE EXCEPTION 'Prekoračen dozvoljeni broj provera. Molimo sačekajte nekoliko minuta.'
      USING ERRCODE = 'P0001';
  END IF;

  RETURN EXISTS (
    SELECT 1 FROM public.profiles WHERE phone = v_trimmed
  );
END;
$$;

REVOKE ALL ON FUNCTION public.check_phone_exists(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.check_phone_exists(TEXT) TO anon, authenticated;
