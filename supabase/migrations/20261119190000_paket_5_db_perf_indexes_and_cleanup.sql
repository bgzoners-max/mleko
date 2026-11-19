-- Paket 5: Postgres performanse, indeksi, RLS InitPlan, rate-limit atomičnost i push_delivery_logs retencija
-- 1. RLS InitPlan optimizacija ((SELECT auth.uid()) / (SELECT public.is_admin())) i uklanjanje duplirane politike
-- 2. Dodavanje nedostajućih FK/kompozitnih indeksa: buyer_reviews(order_id), classified_ads(user_id, status)
-- 3. Uklanjanje 5 redundantnih indeksa pokrivenih kompozitnim/unique indeksima
-- 4. Atomični UNIQUE(identifier, endpoint) upsert u check_and_record_auth_rate_limit + validacija emaila na waitlist
-- 5. Automatska pg_cron retencija za push_delivery_logs (cleanup_push_delivery_logs)
-- 6. Ograničen prozor (180 dana / 500 poruka) u get_seller_response_time_stats

-- ============================================================================
-- 1. RLS InitPlan optimizacija i čišćenje duplirane politike
-- ============================================================================
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING ((SELECT auth.uid()) = id)
  WITH CHECK ((SELECT auth.uid()) = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile"
  ON public.profiles
  FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT auth.uid()) = id);

-- classified_ad_reports_select_own već uključuje OR (SELECT public.is_admin())
DROP POLICY IF EXISTS "classified_ad_reports_select_admin" ON public.classified_ad_reports;

DROP POLICY IF EXISTS "classified_ad_reports_update_admin" ON public.classified_ad_reports;
CREATE POLICY "classified_ad_reports_update_admin"
  ON public.classified_ad_reports
  FOR UPDATE
  TO authenticated
  USING ((SELECT public.is_admin()))
  WITH CHECK ((SELECT public.is_admin()));

DROP POLICY IF EXISTS "classified_ad_reports_delete_admin" ON public.classified_ad_reports;
CREATE POLICY "classified_ad_reports_delete_admin"
  ON public.classified_ad_reports
  FOR DELETE
  TO authenticated
  USING ((SELECT public.is_admin()));

-- ============================================================================
-- 2. Nedostajući FK i kompozitni indeksi
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_buyer_reviews_order_id
  ON public.buyer_reviews (order_id);

CREATE INDEX IF NOT EXISTS idx_classified_ads_user_status
  ON public.classified_ads (user_id, status);

-- ============================================================================
-- 3. Uklanjanje 5 redundantnih indeksa (pokriveni kompozitnim/unique indeksima)
-- ============================================================================
-- Pokriven sa idx_messages_conversation_created (conversation_id, created_at DESC, id DESC)
DROP INDEX IF EXISTS public.idx_messages_conversation;

-- Pokriveni sa idx_conversations_buyer_updated i idx_conversations_seller_updated
DROP INDEX IF EXISTS public.idx_conversations_buyer;
DROP INDEX IF EXISTS public.idx_conversations_seller;

-- Pokriven sa idx_user_push_tokens_user_id_created i idx_push_tokens_user_installation_unique
DROP INDEX IF EXISTS public.idx_push_tokens_user;

-- Pokriven sa user_push_tokens_token_key (UNIQUE) i idx_user_push_tokens_token_user_id
DROP INDEX IF EXISTS public.idx_user_push_tokens_token;

-- ============================================================================
-- 4. Atomični rate-limit (UNIQUE constraint) i validacija emaila na waitlist
-- ============================================================================
DELETE FROM public.auth_rate_limits a
USING public.auth_rate_limits b
WHERE a.identifier = b.identifier
  AND a.endpoint = b.endpoint
  AND (
    a.window_start < b.window_start
    OR (a.window_start = b.window_start AND a.id < b.id)
  );

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'auth_rate_limits_identifier_endpoint_key'
  ) THEN
    ALTER TABLE public.auth_rate_limits
      ADD CONSTRAINT auth_rate_limits_identifier_endpoint_key
      UNIQUE (identifier, endpoint);
  END IF;
END $$;

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
  v_window INTERVAL := (GREATEST(p_window_seconds, 1) || ' seconds')::interval;
  v_count INT;
BEGIN
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

    IF v_raw_ip IS NULL
       OR NOT (
            v_raw_ip ~ '^[0-9]{1,3}(\.[0-9]{1,3}){3}$'
         OR v_raw_ip ~ '^[0-9a-fA-F:]*:[0-9a-fA-F:]*$'
       )
    THEN
      v_identifier := 'ip:unknown_client';
    ELSE
      v_identifier := 'ip:' || v_raw_ip;
    END IF;
  END IF;

  IF (random() < 0.05) THEN
    PERFORM public.cleanup_expired_auth_rate_limits(INTERVAL '1 hour');
  END IF;

  INSERT INTO public.auth_rate_limits (identifier, endpoint, request_count, window_start)
  VALUES (v_identifier, p_endpoint, 1, v_now)
  ON CONFLICT (identifier, endpoint)
  DO UPDATE SET
    request_count = CASE
      WHEN public.auth_rate_limits.window_start <= v_now - v_window THEN 1
      ELSE public.auth_rate_limits.request_count + 1
    END,
    window_start = CASE
      WHEN public.auth_rate_limits.window_start <= v_now - v_window THEN v_now
      ELSE public.auth_rate_limits.window_start
    END
  RETURNING request_count INTO v_count;

  RETURN v_count <= p_max_requests;
END;
$$;

DROP POLICY IF EXISTS "Anyone can join waitlist" ON public.waitlist;
CREATE POLICY "Anyone can join waitlist"
  ON public.waitlist
  FOR INSERT
  TO public
  WITH CHECK (
    length(btrim(email)) BETWEEN 5 AND 254
    AND btrim(email) ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'
  );

-- ============================================================================
-- 5. Automatska retencija za push_delivery_logs (pg_cron)
-- ============================================================================
CREATE OR REPLACE FUNCTION public.cleanup_push_delivery_logs(
  p_success_retention INTERVAL DEFAULT INTERVAL '30 days',
  p_error_retention INTERVAL DEFAULT INTERVAL '90 days'
)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_deleted INT := 0;
BEGIN
  WITH to_delete AS (
    SELECT id
    FROM public.push_delivery_logs
    WHERE (
      status IN ('success', 'no_tokens')
      AND created_at < NOW() - p_success_retention
    )
    OR (
      status NOT IN ('success', 'no_tokens')
      AND created_at < NOW() - p_error_retention
    )
    ORDER BY created_at ASC
    LIMIT 10000
  ),
  deleted AS (
    DELETE FROM public.push_delivery_logs l
    USING to_delete d
    WHERE l.id = d.id
    RETURNING 1
  )
  SELECT COUNT(*) INTO v_deleted FROM deleted;

  RETURN v_deleted;
END;
$$;

REVOKE ALL ON FUNCTION public.cleanup_push_delivery_logs(INTERVAL, INTERVAL) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cleanup_push_delivery_logs(INTERVAL, INTERVAL) TO service_role;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'daily_push_delivery_logs_cleanup') THEN
      PERFORM cron.unschedule('daily_push_delivery_logs_cleanup');
    END IF;

    PERFORM cron.schedule(
      'daily_push_delivery_logs_cleanup',
      '15 3 * * *',
      'SELECT public.cleanup_push_delivery_logs(INTERVAL ''30 days'', INTERVAL ''90 days'')'
    );
  END IF;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Skipping pg_cron schedule for daily_push_delivery_logs_cleanup: %', SQLERRM;
END $$;

-- ============================================================================
-- 6. Ograničen prozor u get_seller_response_time_stats (poslednjih 180 dana / 500 poruka)
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_seller_response_time_stats(p_seller_id UUID)
RETURNS TABLE (
  sample_count INTEGER,
  avg_response_minutes NUMERIC,
  median_response_minutes NUMERIC,
  last_response_minutes NUMERIC
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH buyer_messages AS (
    SELECT
      m.id,
      m.conversation_id,
      m.created_at
    FROM public.messages m
    JOIN public.conversations c ON c.id = m.conversation_id
    WHERE c.seller_id = p_seller_id
      AND m.sender_id = c.buyer_id
      AND m.created_at >= NOW() - INTERVAL '180 days'
    ORDER BY m.created_at DESC
    LIMIT 500
  ),
  first_replies AS (
    SELECT
      bm.id AS buyer_message_id,
      bm.created_at AS buyer_created_at,
      (
        SELECT m2.created_at
        FROM public.messages m2
        WHERE m2.conversation_id = bm.conversation_id
          AND m2.created_at > bm.created_at
          AND m2.sender_id = p_seller_id
        ORDER BY m2.created_at ASC
        LIMIT 1
      ) AS seller_reply_at
    FROM buyer_messages bm
  ),
  durations AS (
    SELECT
      EXTRACT(EPOCH FROM (seller_reply_at - buyer_created_at)) / 60.0 AS minutes,
      seller_reply_at
    FROM first_replies
    WHERE seller_reply_at IS NOT NULL
  )
  SELECT
    COUNT(*)::INTEGER AS sample_count,
    ROUND(AVG(minutes)::NUMERIC, 1) AS avg_response_minutes,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY minutes)::NUMERIC, 1) AS median_response_minutes,
    ROUND((SELECT minutes::NUMERIC FROM durations ORDER BY seller_reply_at DESC LIMIT 1), 1) AS last_response_minutes
  FROM durations;
$$;

REVOKE ALL ON FUNCTION public.get_seller_response_time_stats(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_seller_response_time_stats(UUID) TO anon, authenticated, service_role;
