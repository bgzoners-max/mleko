-- ============================================================================
-- Migracija 20260910150000: Sigurnosno učvršćivanje (Security Hardening)
--
-- S1: Restrikcija INSERT prava na notifications tabeli isključivo na service_role.
--     Korisnici ne mogu direktno unositi notifikacije niti okidati push.
--     Sistemski trigeri (notify_*) su SECURITY DEFINER i nastavljaju nesmetano da rade.
--
-- S2: Zaštita edge_config tabele preko RLS-a.
--     invoke_send_push sada preuzima service_role_key iz Vault-a ili edge_config-a
--     i šalje autorizovani zahtev ka send-push Edge funkciji.
--     Ažurirana push_health_summary dijagnostika.
--
-- S4: Zaštita i deduplikacija brojača pregleda oglasa (classified_ad_views).
--     Sprečava botove i zlonamerno pumpanje brojača pomoću 1-satnog per-viewer
--     prozora baziranog na user_id, installation_id ili IP hešu.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. S1: Uklanjanje opasne INSERT politike za authenticated korisnike
-- ----------------------------------------------------------------------------

DROP POLICY IF EXISTS "System can create notifications" ON public.notifications;
DROP POLICY IF EXISTS "Service role can create notifications" ON public.notifications;

-- Samo service_role (ili funkcije sa SECURITY DEFINER pravima) može direktno da ubacuje
CREATE POLICY "Service role can create notifications"
  ON public.notifications FOR INSERT
  TO service_role
  WITH CHECK (true);

-- Potvrđujemo da postojeća SELECT politika omogućava korisniku uvid samo u sopstvene notifikacije
DROP POLICY IF EXISTS "Users see own notifications" ON public.notifications;
CREATE POLICY "Users see own notifications"
  ON public.notifications FOR SELECT
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

-- ----------------------------------------------------------------------------
-- 2. S2: Zaštita edge_config tabele i prelazak na service_role_key
-- ----------------------------------------------------------------------------

-- Omogući RLS na tabeli sa osetljivim konfiguracijama (ako nije bio omogućen)
ALTER TABLE public.edge_config ENABLE ROW LEVEL SECURITY;

-- Oduzmi sva prava sa javnih i korisničkih uloga
REVOKE ALL ON public.edge_config FROM PUBLIC, anon, authenticated;
GRANT ALL ON public.edge_config TO service_role;

-- Unos placeholder ključa za lokalni dev (ako već ne postoji)
INSERT INTO public.edge_config (key, value)
VALUES 
  ('service_role_key', '')
ON CONFLICT (key) DO NOTHING;

-- Ažurirana invoke_send_push funkcija koja koristi service_role_key
CREATE OR REPLACE FUNCTION public.invoke_send_push()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  base_url TEXT;
  service_key TEXT;
  fn_url TEXT;
BEGIN
  -- 1. Pokušaj čitanja 'service_role_key' iz Supabase Vault-a
  BEGIN
    SELECT decrypted_secret INTO service_key 
    FROM vault.decrypted_secrets 
    WHERE name = 'service_role_key' 
    LIMIT 1;
  EXCEPTION WHEN OTHERS THEN
    service_key := NULL;
  END;

  -- 2. Pokušaj čitanja 'functions_base_url' iz Supabase Vault-a
  BEGIN
    SELECT decrypted_secret INTO base_url 
    FROM vault.decrypted_secrets 
    WHERE name = 'functions_base_url' 
    LIMIT 1;
  EXCEPTION WHEN OTHERS THEN
    base_url := NULL;
  END;

  -- Fallback na public.edge_config tabelu ako Vault nije konfigurisan
  IF base_url IS NULL OR base_url = '' THEN
    SELECT value INTO base_url FROM public.edge_config WHERE key = 'functions_base_url' LIMIT 1;
  END IF;

  IF service_key IS NULL OR service_key = '' THEN
    SELECT value INTO service_key FROM public.edge_config WHERE key = 'service_role_key' LIMIT 1;
  END IF;

  -- Ako ni Vault ni edge_config nemaju service_role_key, ne možemo autorizovati Edge funkciju
  IF service_key IS NULL OR service_key = '' THEN
    RAISE WARNING 'invoke_send_push: service_role_key nije pronađen u Vault-u ni u edge_config-u. Push obaveštenje nije poslato.';
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
      'Authorization', 'Bearer ' || service_key,
      'apikey', service_key
    ),
    timeout_milliseconds := 5000
  );

  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'invoke_send_push: %', SQLERRM;
    RETURN NEW;
END;
$$;

-- Ažuriraj push_health_summary dijagnostiku da prepoznaje i service_role_key
CREATE OR REPLACE FUNCTION public.push_health_summary()
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
  success_rate_pct NUMERIC,
  last_notification_at TIMESTAMPTZ,
  last_delivery_at TIMESTAMPTZ,
  delivery_backlog_minutes NUMERIC,
  health TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_base_url TEXT;
  v_service_key TEXT;
  v_anon_key TEXT;
BEGIN
  -- Pokušaj čitanja iz Vault-a
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

  -- Fallback na public.edge_config
  IF v_base_url IS NULL OR v_base_url = '' THEN
    SELECT value INTO v_base_url FROM public.edge_config WHERE key = 'functions_base_url' LIMIT 1;
  END IF;

  IF v_service_key IS NULL OR v_service_key = '' THEN
    SELECT value INTO v_service_key FROM public.edge_config WHERE key = 'service_role_key' LIMIT 1;
  END IF;

  IF v_anon_key IS NULL OR v_anon_key = '' THEN
    SELECT value INTO v_anon_key FROM public.edge_config WHERE key = 'anon_key' LIMIT 1;
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
      ) AS success_rate_pct,
      notification_stats.last_notification_at,
      delivery_stats.last_delivery_at,
      ROUND(
        CASE
          WHEN notification_stats.last_notification_at IS NULL THEN 0
          WHEN delivery_stats.last_delivery_at IS NULL THEN EXTRACT(EPOCH FROM (NOW() - notification_stats.last_notification_at)) / 60.0
          WHEN delivery_stats.last_delivery_at < notification_stats.last_notification_at THEN EXTRACT(EPOCH FROM (notification_stats.last_notification_at - delivery_stats.last_delivery_at)) / 60.0
          ELSE 0
        END,
        2
      ) AS delivery_backlog_minutes
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
    summary.success_rate_pct,
    summary.last_notification_at,
    summary.last_delivery_at,
    summary.delivery_backlog_minutes,
    CASE
      WHEN NOT summary.edge_config_ok THEN 'misconfigured'
      WHEN summary.last_notification_at IS NOT NULL
        AND (summary.last_delivery_at IS NULL OR summary.last_delivery_at < summary.last_notification_at - INTERVAL '5 minutes') THEN 'stalled'
      WHEN summary.deliveries_24h > 0 AND summary.success_rate_pct < 80 THEN 'degraded'
      ELSE 'ok'
    END AS health
  FROM summary;
END;
$function$;


-- ----------------------------------------------------------------------------
-- 3. S4: Tabela pregleda i deduplikacija (rate limiting) za classified ads
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.classified_ad_views (
  ad_id UUID NOT NULL REFERENCES public.classified_ads(id) ON DELETE CASCADE,
  viewer_hash TEXT NOT NULL,
  last_viewed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (ad_id, viewer_hash)
);

ALTER TABLE public.classified_ad_views ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.classified_ad_views FROM PUBLIC, anon, authenticated;
GRANT ALL ON public.classified_ad_views TO service_role;

CREATE INDEX IF NOT EXISTS idx_classified_ad_views_last_viewed
  ON public.classified_ad_views (last_viewed_at);

-- OBAVEZNO obriši postojeću verziju sa 1 argumentom pre kreiranja overload-a
-- kako PostgREST ne bi prijavljivao grešku nejasnog izbora kandidata (overload ambiguity)
DROP FUNCTION IF EXISTS public.increment_classified_ad_views(UUID);

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

  -- 4. Odredi identifikator posetioca (viewer_hash)
  IF v_user IS NOT NULL THEN
    v_viewer_hash := 'usr:' || v_user::text;
  ELSIF p_viewer_id IS NOT NULL AND length(trim(p_viewer_id)) > 0 THEN
    v_viewer_hash := 'dev:' || md5(trim(p_viewer_id));
  ELSE
    BEGIN
      v_headers := current_setting('request.headers', true)::jsonb;
      v_ip := COALESCE(
        v_headers->>'cf-connecting-ip',
        v_headers->>'x-real-ip',
        split_part(v_headers->>'x-forwarded-for', ',', 1),
        'unknown'
      );
    EXCEPTION WHEN OTHERS THEN
      v_ip := 'unknown';
    END;
    v_viewer_hash := 'ip:' || md5(v_ip);
  END IF;

  -- 5. Deduplikacija: Ako je posetilac već pogledao oglas u proteklih 1 sat, ignoriši
  IF EXISTS (
    SELECT 1 FROM public.classified_ad_views
    WHERE classified_ad_views.ad_id = increment_classified_ad_views.ad_id
      AND classified_ad_views.viewer_hash = v_viewer_hash
      AND classified_ad_views.last_viewed_at > now() - INTERVAL '1 hour'
  ) THEN
    RETURN;
  END IF;

  -- 6. Zabeleži / osveži vreme pregleda u tabeli deduplikacije
  INSERT INTO public.classified_ad_views (ad_id, viewer_hash, last_viewed_at)
  VALUES (increment_classified_ad_views.ad_id, v_viewer_hash, now())
  ON CONFLICT (ad_id, viewer_hash)
  DO UPDATE SET last_viewed_at = now();

  -- 7. Inkrementiraj stvarni brojač pregleda na oglasu
  UPDATE public.classified_ads
  SET views_count = views_count + 1,
      last_view_at = now()
  WHERE id = increment_classified_ad_views.ad_id;
END;
$$;

REVOKE ALL ON FUNCTION public.increment_classified_ad_views(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.increment_classified_ad_views(UUID, TEXT) TO anon, authenticated, service_role;
