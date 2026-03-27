-- Push diagnostics package (production-safe read checks)
-- Run sections one by one in SQL Editor.

-- 1) Core config check: edge URL + anon key presence
SELECT key, CASE
  WHEN key = 'functions_base_url' THEN value
  WHEN key = 'anon_key' THEN LEFT(value, 12) || '...'
  ELSE value
END AS value_preview
FROM public.edge_config
WHERE key IN ('functions_base_url', 'anon_key')
ORDER BY key;

-- 2) FCM token health summary
SELECT
  COUNT(*) AS total_tokens,
  COUNT(DISTINCT user_id) AS users_with_tokens,
  COUNT(*) FILTER (WHERE platform = 'android') AS android_tokens,
  COUNT(*) FILTER (WHERE platform = 'ios') AS ios_tokens
FROM public.user_push_tokens;

-- 3) Users that recently received notifications but have no FCM token
SELECT
  n.user_id,
  COUNT(*) AS notif_count_24h,
  MAX(n.created_at) AS last_notification_at
FROM public.notifications n
LEFT JOIN public.user_push_tokens t ON t.user_id = n.user_id
WHERE n.created_at > NOW() - INTERVAL '24 hours'
  AND t.user_id IS NULL
GROUP BY n.user_id
ORDER BY notif_count_24h DESC, last_notification_at DESC
LIMIT 100;

-- 4) Latest failed/partial push sends (uses new diagnostics table)
SELECT
  created_at,
  request_id,
  user_id,
  status,
  token_count,
  sent_count,
  failed_count,
  errors
FROM public.push_delivery_logs
WHERE status <> 'success'
ORDER BY created_at DESC
LIMIT 100;

-- 5) Last sends for one specific user (replace UUID)
-- SELECT
--   created_at,
--   request_id,
--   status,
--   token_count,
--   sent_count,
--   failed_count,
--   title,
--   type,
--   errors
-- FROM public.push_delivery_logs
-- WHERE user_id = '00000000-0000-0000-0000-000000000000'::uuid
-- ORDER BY created_at DESC
-- LIMIT 50;

-- 6) Quick health ratio in the last 24h
SELECT
  COUNT(*) AS total_requests,
  COUNT(*) FILTER (WHERE status = 'success') AS success_requests,
  COUNT(*) FILTER (WHERE status = 'partial') AS partial_requests,
  COUNT(*) FILTER (WHERE status IN ('error', 'no_tokens', 'invalid_request')) AS failed_requests,
  ROUND(
    CASE WHEN COUNT(*) = 0 THEN 0
    ELSE (COUNT(*) FILTER (WHERE status = 'success')::numeric / COUNT(*)::numeric) * 100
    END,
    2
  ) AS success_rate_pct
FROM public.push_delivery_logs
WHERE created_at > NOW() - INTERVAL '24 hours';

-- 7) Optional manual live test (uncomment and set target user id)
-- INSERT INTO public.notifications (user_id, type, title, body)
-- VALUES (
--   '00000000-0000-0000-0000-000000000000'::uuid,
--   'system',
--   'Test push',
--   'Ako dobijes ovaj push kao sistemsku notifikaciju sa zvukom, tok je ispravan.'
-- )
-- RETURNING id, user_id, type, title, created_at;

-- 8) After manual test, verify that notification row was created
-- SELECT id, user_id, type, title, created_at
-- FROM public.notifications
-- WHERE type = 'system' AND title = 'Test push'
-- ORDER BY created_at DESC
-- LIMIT 5;

-- 9) After manual test, verify push delivery logs were written
-- SELECT created_at, request_id, user_id, status, token_count, sent_count, failed_count, errors
-- FROM public.push_delivery_logs
-- ORDER BY created_at DESC
-- LIMIT 10;

-- 10) Token distribution by user (useful before/after cleanup)
SELECT
  user_id,
  COUNT(*) AS token_count,
  MIN(created_at) AS oldest_token_at,
  MAX(created_at) AS newest_token_at
FROM public.user_push_tokens
GROUP BY user_id
ORDER BY token_count DESC, newest_token_at DESC;

-- 11) Tokens older than 60 days (should trend toward 0 after cleanup)
SELECT
  user_id,
  platform,
  token,
  created_at
FROM public.user_push_tokens
WHERE created_at < NOW() - INTERVAL '60 days'
ORDER BY created_at ASC
LIMIT 100;
