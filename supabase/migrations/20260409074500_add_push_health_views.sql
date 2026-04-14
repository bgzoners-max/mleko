-- Dashboard-friendly views for push health monitoring

DROP VIEW IF EXISTS public.push_health_dashboard;

CREATE VIEW public.push_health_dashboard AS
SELECT
  checked_at,
  health,
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
  delivery_backlog_minutes
FROM public.push_health_summary();

DROP VIEW IF EXISTS public.push_health_user_issues;

CREATE VIEW public.push_health_user_issues AS
WITH recent_users AS (
  SELECT DISTINCT user_id
  FROM public.notifications
  WHERE created_at > NOW() - INTERVAL '7 days'

  UNION

  SELECT DISTINCT user_id
  FROM public.user_push_tokens

  UNION

  SELECT DISTINCT user_id
  FROM public.push_delivery_logs
  WHERE created_at > NOW() - INTERVAL '7 days'
)
SELECT
  health.checked_at,
  health.user_id,
  health.health,
  health.token_count,
  health.latest_token_at,
  health.notifications_7d,
  health.latest_notification_at,
  health.latest_delivery_at,
  health.latest_delivery_status,
  health.latest_delivery_error_count
FROM recent_users users
CROSS JOIN LATERAL public.push_user_health(users.user_id) AS health
WHERE health.health <> 'ok';

COMMENT ON VIEW public.push_health_dashboard IS
'Single-row dashboard view over push_health_summary() for admin monitoring.';

COMMENT ON VIEW public.push_health_user_issues IS
'Dashboard view listing recent users with non-ok push health states.';

GRANT SELECT ON public.push_health_dashboard TO authenticated;
GRANT SELECT ON public.push_health_user_issues TO authenticated;
