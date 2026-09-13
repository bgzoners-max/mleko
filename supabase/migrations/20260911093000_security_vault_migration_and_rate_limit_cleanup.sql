-- ============================================================================
-- Migracija: Prelazak na Supabase Vault i Automatsko Čišćenje Auth Rate Limita
-- Datum: 2026-09-11
-- Opis:
--   1. Uklanjanje plaintext tajni iz public.edge_config tabele i striktni RLS.
--   2. Ažuriranje invoke_send_push i check_push_configuration funkcija tako
--      da tajne čitaju isključivo iz vault.decrypted_secrets (bez plaintext fallback-a).
--   3. Indeksiranje i automatsko čišćenje tabele public.auth_rate_limits:
--      - Indeks na window_start
--      - Determinističko inline čišćenje u check_and_record_auth_rate_limit
--      - Namenska funkcija cleanup_expired_auth_rate_limits
--      - pg_cron posao (ako je ekstenzija instalirana)
-- ============================================================================

-- ============================================================================
-- 1. Zaštita public.edge_config i uklanjanje plaintext tajni
-- ============================================================================

-- Ukloni plaintext tajne iz edge_config (sve tajne treba da budu u Vault-u)
DELETE FROM public.edge_config WHERE key IN ('anon_key', 'service_role_key');

-- Osiguraj da je RLS strogo omogućen i forsiran
ALTER TABLE public.edge_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.edge_config FORCE ROW LEVEL SECURITY;

REVOKE ALL ON public.edge_config FROM PUBLIC, anon, authenticated;
GRANT ALL ON public.edge_config TO service_role;

DROP POLICY IF EXISTS "service_role_only_edge_config" ON public.edge_config;
CREATE POLICY "service_role_only_edge_config"
  ON public.edge_config
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- ============================================================================
-- 2. Ažuriranje invoke_send_push: isključivo Vault za service_role_key
-- ============================================================================

CREATE OR REPLACE FUNCTION public.invoke_send_push()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  base_url TEXT;
  service_key TEXT;
  fn_url TEXT;
BEGIN
  -- 1. Čitanje 'service_role_key' isključivo iz Supabase Vault-a
  BEGIN
    SELECT decrypted_secret INTO service_key 
    FROM vault.decrypted_secrets 
    WHERE name = 'service_role_key' 
    LIMIT 1;
  EXCEPTION WHEN OTHERS THEN
    service_key := NULL;
  END;

  -- 2. Čitanje 'functions_base_url' iz Supabase Vault-a ili non-secret edge_config fallback
  BEGIN
    SELECT decrypted_secret INTO base_url 
    FROM vault.decrypted_secrets 
    WHERE name = 'functions_base_url' 
    LIMIT 1;
  EXCEPTION WHEN OTHERS THEN
    base_url := NULL;
  END;

  -- Non-sensitive fallback samo za URL servera ako nije unet u Vault
  IF base_url IS NULL OR base_url = '' THEN
    SELECT value INTO base_url FROM public.edge_config WHERE key = 'functions_base_url' LIMIT 1;
  END IF;

  -- Ako Vault nema service_role_key, ne možemo autorizovati Edge funkciju (nema plaintext fallback-a)
  IF service_key IS NULL OR service_key = '' THEN
    RAISE WARNING 'invoke_send_push: service_role_key nije pronađen u Vault-u. Push obaveštenje nije poslato.';
    RETURN NEW;
  END IF;

  IF base_url IS NULL OR base_url = '' THEN
    RETURN NEW;
  END IF;

  fn_url := base_url || '/functions/v1/send-push';

  PERFORM net.http_post(
    url := fn_url,
    body := jsonb_build_object(
      'user_id', NEW.user_id,
      'title', COALESCE(NEW.title, ''),
      'body', COALESCE(NEW.body, ''),
      'type', COALESCE(NEW.type::text, ''),
      'order_id', CASE WHEN NEW.order_id IS NOT NULL THEN NEW.order_id::text ELSE '' END,
      'ticket_id', CASE WHEN NEW.ticket_id IS NOT NULL THEN NEW.ticket_id::text ELSE '' END,
      'conversation_id', CASE WHEN NEW.conversation_id IS NOT NULL THEN NEW.conversation_id::text ELSE '' END
    ),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || service_key
    ),
    timeout_milliseconds := 5000
  );

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Ne blokiramo insert u notifications tabelu ako push servis nije dostupan
  RAISE WARNING 'invoke_send_push greška: %', SQLERRM;
  RETURN NEW;
END;
$$;

-- ============================================================================
-- 3. Ažuriranje check_push_configuration funkcije: čitanje iz Vault-a
-- ============================================================================

CREATE OR REPLACE FUNCTION public.check_push_configuration()
RETURNS TABLE (
  checked_at TIMESTAMPTZ,
  edge_config_ok BOOLEAN,
  functions_base_url TEXT,
  anon_key_present BOOLEAN,
  total_tokens BIGINT,
  users_with_tokens BIGINT,
  tokens_created_24h BIGINT,
  notifications_24h BIGINT,
  deliveries_24h BIGINT,
  successful_deliveries_24h BIGINT,
  failed_deliveries_24h BIGINT,
  delivery_success_rate NUMERIC,
  last_notification_at TIMESTAMPTZ,
  last_delivery_at TIMESTAMPTZ,
  overall_status TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_base_url TEXT;
  v_service_key TEXT;
  v_anon_key TEXT;
BEGIN
  -- Čitanje iz Supabase Vault-a
  BEGIN
    SELECT decrypted_secret INTO v_base_url FROM vault.decrypted_secrets WHERE name = 'functions_base_url' LIMIT 1;
  EXCEPTION WHEN OTHERS THEN v_base_url := NULL;
  END;

  BEGIN
    SELECT decrypted_secret INTO v_service_key FROM vault.decrypted_secrets WHERE name = 'service_role_key' LIMIT 1;
  EXCEPTION WHEN OTHERS THEN v_service_key := NULL;
  END;

  BEGIN
    SELECT decrypted_secret INTO v_anon_key FROM vault.decrypted_secrets WHERE name = 'anon_key' LIMIT 1;
  EXCEPTION WHEN OTHERS THEN v_anon_key := NULL;
  END;

  -- Non-sensitive fallback samo za functions_base_url
  IF v_base_url IS NULL OR v_base_url = '' THEN
    SELECT value INTO v_base_url FROM public.edge_config WHERE key = 'functions_base_url' LIMIT 1;
  END IF;

  RETURN QUERY
  WITH token_stats AS (
    SELECT
      COUNT(*) AS total_tokens,
      COUNT(DISTINCT user_id) AS users_with_tokens,
      COUNT(*) FILTER (WHERE user_push_tokens.created_at > NOW() - INTERVAL '24 hours') AS tokens_created_24h
    FROM public.user_push_tokens
  ),
  notification_stats AS (
    SELECT
      COUNT(*) FILTER (WHERE notifications.created_at > NOW() - INTERVAL '24 hours') AS notifications_24h,
      MAX(notifications.created_at) AS last_notification_at
    FROM public.notifications
  ),
  delivery_stats AS (
    SELECT
      COUNT(*) FILTER (WHERE push_delivery_logs.created_at > NOW() - INTERVAL '24 hours') AS deliveries_24h,
      COUNT(*) FILTER (
        WHERE push_delivery_logs.created_at > NOW() - INTERVAL '24 hours'
          AND status = 'success'
      ) AS successful_deliveries_24h,
      COUNT(*) FILTER (
        WHERE push_delivery_logs.created_at > NOW() - INTERVAL '24 hours'
          AND status IN ('error', 'partial', 'no_tokens', 'invalid_request')
      ) AS failed_deliveries_24h,
      MAX(push_delivery_logs.created_at) AS last_delivery_at
    FROM public.push_delivery_logs
  ),
  summary AS (
    SELECT
      NOW() AS checked_at,
      (v_base_url IS NOT NULL AND v_base_url <> ''
        AND ((v_service_key IS NOT NULL AND v_service_key <> '') OR (v_anon_key IS NOT NULL AND v_anon_key <> ''))) AS edge_config_ok,
      v_base_url AS functions_base_url,
      ((v_service_key IS NOT NULL AND v_service_key <> '') OR (v_anon_key IS NOT NULL AND v_anon_key <> '')) AS anon_key_present,
      token_stats.total_tokens,
      token_stats.users_with_tokens,
      token_stats.tokens_created_24h,
      notification_stats.notifications_24h,
      delivery_stats.deliveries_24h,
      delivery_stats.successful_deliveries_24h,
      delivery_stats.failed_deliveries_24h,
      ROUND(
        CASE
          WHEN delivery_stats.deliveries_24h = 0 THEN 0
          ELSE (delivery_stats.successful_deliveries_24h::NUMERIC / delivery_stats.deliveries_24h::NUMERIC) * 100
        END,
        2
      ) AS delivery_success_rate,
      notification_stats.last_notification_at,
      delivery_stats.last_delivery_at
    FROM token_stats, notification_stats, delivery_stats
  )
  SELECT
    summary.checked_at,
    summary.edge_config_ok,
    summary.functions_base_url,
    summary.anon_key_present,
    summary.total_tokens,
    summary.users_with_tokens,
    summary.tokens_created_24h,
    summary.notifications_24h,
    summary.deliveries_24h,
    summary.successful_deliveries_24h,
    summary.failed_deliveries_24h,
    summary.delivery_success_rate,
    summary.last_notification_at,
    summary.last_delivery_at,
    CASE
      WHEN NOT summary.edge_config_ok THEN 'misconfigured'
      WHEN summary.total_tokens = 0 THEN 'no_tokens'
      WHEN summary.deliveries_24h > 0 AND summary.delivery_success_rate < 50 THEN 'degraded'
      ELSE 'healthy'
    END AS overall_status
  FROM summary;
END;
$$;

-- ============================================================================
-- 4. auth_rate_limits: Indeksiranje, čišćenje i pg_cron
-- ============================================================================

-- 4.1. Namenski indeks na window_start za brzo čišćenje
CREATE INDEX IF NOT EXISTS idx_auth_rate_limits_window_start
  ON public.auth_rate_limits (window_start);

-- 4.2. Namenska funkcija za periodično čišćenje starih rate limit zapisa
CREATE OR REPLACE FUNCTION public.cleanup_expired_auth_rate_limits(
  p_retention_interval INTERVAL DEFAULT INTERVAL '1 hour'
)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_deleted INT := 0;
BEGIN
  DELETE FROM public.auth_rate_limits
  WHERE id IN (
    SELECT id
    FROM public.auth_rate_limits
    WHERE window_start < clock_timestamp() - p_retention_interval
    LIMIT 5000
  );
  GET DIAGNOSTICS v_deleted = ROW_COUNT;
  RETURN v_deleted;
END;
$$;

REVOKE ALL ON FUNCTION public.cleanup_expired_auth_rate_limits(INTERVAL) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.cleanup_expired_auth_rate_limits(INTERVAL) TO service_role;

-- 4.3. Optimizovan check_and_record_auth_rate_limit sa inline čišćenjem za aktivni IP
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

  -- 1. Determinističko inline čišćenje za pozivajuću IP adresu (koristi kompozitni indeks)
  DELETE FROM public.auth_rate_limits
  WHERE identifier = v_ip
    AND endpoint = p_endpoint
    AND window_start < v_now - (p_window_seconds || ' seconds')::interval;

  -- 2. Brzo globalno čišćenje starijih zapisa (10% verovatnoće po pozivu, koristi window_start indeks)
  IF (random() < 0.10) THEN
    PERFORM public.cleanup_expired_auth_rate_limits(INTERVAL '1 hour');
  END IF;

  -- 3. Provera postojećeg aktivnog prozora
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

-- 4.4. Zakazivanje pg_cron posla (ako je pg_cron ekstenzija omogućena)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'hourly_auth_rate_limits_cleanup') THEN
      PERFORM cron.unschedule('hourly_auth_rate_limits_cleanup');
    END IF;

    PERFORM cron.schedule(
      'hourly_auth_rate_limits_cleanup',
      '15 * * * *', -- svakih sat vremena na 15 minuta
      'SELECT public.cleanup_expired_auth_rate_limits(INTERVAL ''1 hour'')'
    );
  END IF;
END $$;
