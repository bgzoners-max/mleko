-- Push health checks for quick production diagnostics

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
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $function$
WITH config AS (
  SELECT
    MAX(CASE WHEN key = 'functions_base_url' THEN value END) AS functions_base_url,
    MAX(CASE WHEN key = 'anon_key' THEN value END) AS anon_key
  FROM public.edge_config
),
token_stats AS (
  SELECT
    COUNT(*) AS total_tokens,
    COUNT(DISTINCT user_id) AS users_with_tokens,
    COUNT(*) FILTER (WHERE created_at > NOW() - INTERVAL '24 hours') AS tokens_created_24h
  FROM public.user_push_tokens
),
notification_stats AS (
  SELECT
    COUNT(*) FILTER (WHERE created_at > NOW() - INTERVAL '24 hours') AS notifications_24h,
    MAX(created_at) AS last_notification_at
  FROM public.notifications
),
delivery_stats AS (
  SELECT
    COUNT(*) FILTER (WHERE created_at > NOW() - INTERVAL '24 hours') AS deliveries_24h,
    COUNT(*) FILTER (
      WHERE created_at > NOW() - INTERVAL '24 hours'
        AND status = 'success'
    ) AS successful_deliveries_24h,
    COUNT(*) FILTER (
      WHERE created_at > NOW() - INTERVAL '24 hours'
        AND status IN ('error', 'partial', 'no_tokens', 'invalid_request')
    ) AS failed_deliveries_24h,
    MAX(created_at) AS last_delivery_at
  FROM public.push_delivery_logs
),
summary AS (
  SELECT
    NOW() AS checked_at,
    (config.functions_base_url IS NOT NULL AND config.functions_base_url <> ''
      AND config.anon_key IS NOT NULL AND config.anon_key <> '') AS edge_config_ok,
    config.functions_base_url,
    (config.anon_key IS NOT NULL AND config.anon_key <> '') AS anon_key_present,
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
  FROM config, token_stats, notification_stats, delivery_stats
)
SELECT
  checked_at,
  edge_config_ok,
  functions_base_url,
  anon_key_present,
  total_tokens,
  users_with_tokens,
  tokens_created_24h,
  notifications_24h,
  deliveries_24h,
  successful_deliveries_24h,
  failed_deliveries_24h,
  success_rate_pct,
  last_notification_at,
  last_delivery_at,
  delivery_backlog_minutes,
  CASE
    WHEN NOT edge_config_ok THEN 'misconfigured'
    WHEN last_notification_at IS NOT NULL
      AND (last_delivery_at IS NULL OR last_delivery_at < last_notification_at - INTERVAL '5 minutes') THEN 'stalled'
    WHEN deliveries_24h > 0 AND success_rate_pct < 80 THEN 'degraded'
    ELSE 'ok'
  END AS health
FROM summary;
$function$;

CREATE OR REPLACE FUNCTION public.push_user_health(target_user_id UUID)
RETURNS TABLE (
  checked_at TIMESTAMPTZ,
  user_id UUID,
  token_count BIGINT,
  latest_token_at TIMESTAMPTZ,
  notifications_7d BIGINT,
  latest_notification_at TIMESTAMPTZ,
  latest_delivery_at TIMESTAMPTZ,
  latest_delivery_status TEXT,
  latest_delivery_error_count INTEGER,
  health TEXT
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $function$
WITH token_stats AS (
  SELECT
    COUNT(*) AS token_count,
    MAX(created_at) AS latest_token_at
  FROM public.user_push_tokens
  WHERE user_id = target_user_id
),
notification_stats AS (
  SELECT
    COUNT(*) FILTER (WHERE created_at > NOW() - INTERVAL '7 days') AS notifications_7d,
    MAX(created_at) AS latest_notification_at
  FROM public.notifications
  WHERE user_id = target_user_id
),
delivery_stats AS (
  SELECT
    created_at AS latest_delivery_at,
    status AS latest_delivery_status,
    CASE
      WHEN jsonb_typeof(errors) = 'array' THEN jsonb_array_length(errors)
      ELSE 0
    END AS latest_delivery_error_count
  FROM public.push_delivery_logs
  WHERE user_id = target_user_id
  ORDER BY created_at DESC
  LIMIT 1
)
SELECT
  NOW() AS checked_at,
  target_user_id AS user_id,
  token_stats.token_count,
  token_stats.latest_token_at,
  notification_stats.notifications_7d,
  notification_stats.latest_notification_at,
  delivery_stats.latest_delivery_at,
  delivery_stats.latest_delivery_status,
  COALESCE(delivery_stats.latest_delivery_error_count, 0) AS latest_delivery_error_count,
  CASE
    WHEN token_stats.token_count = 0 THEN 'missing_token'
    WHEN notification_stats.latest_notification_at IS NOT NULL
      AND (delivery_stats.latest_delivery_at IS NULL OR delivery_stats.latest_delivery_at < notification_stats.latest_notification_at - INTERVAL '5 minutes') THEN 'stalled'
    WHEN delivery_stats.latest_delivery_status IN ('error', 'partial', 'no_tokens', 'invalid_request') THEN delivery_stats.latest_delivery_status
    ELSE 'ok'
  END AS health
FROM token_stats
CROSS JOIN notification_stats
LEFT JOIN delivery_stats ON TRUE;
$function$;

COMMENT ON FUNCTION public.push_health_summary() IS
'High-level push pipeline health snapshot: config, token coverage, recent notifications, delivery success rate, and backlog signal.';

COMMENT ON FUNCTION public.push_user_health(UUID) IS
'User-scoped push health snapshot: token presence, latest notification, latest delivery result, and current health classification.';
