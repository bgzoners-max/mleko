-- Safe cleanup script for push_delivery_logs.
-- Default behavior is preview-only inside a transaction with ROLLBACK.
-- Review counts first, then change the final ROLLBACK to COMMIT when satisfied.

BEGIN;

-- 0) Current retention preview by status and age bucket
SELECT
  status,
  COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '30 days') AS rows_0_30d,
  COUNT(*) FILTER (
    WHERE created_at < NOW() - INTERVAL '30 days'
      AND created_at >= NOW() - INTERVAL '90 days'
  ) AS rows_30_90d,
  COUNT(*) FILTER (WHERE created_at < NOW() - INTERVAL '90 days') AS rows_90d_plus
FROM public.push_delivery_logs
GROUP BY status
ORDER BY status;

-- 1) Preview rows that would be removed under the recommended policy
-- Recommended policy:
-- - keep success/no_tokens for 30 days
-- - keep partial/error/invalid_request for 90 days
SELECT
  status,
  COUNT(*) AS rows_to_delete,
  MIN(created_at) AS oldest_row,
  MAX(created_at) AS newest_row
FROM public.push_delivery_logs
WHERE (status IN ('success', 'no_tokens') AND created_at < NOW() - INTERVAL '30 days')
   OR (status IN ('partial', 'error', 'invalid_request') AND created_at < NOW() - INTERVAL '90 days')
GROUP BY status
ORDER BY status;

-- 2) Sample of rows that would be deleted
SELECT
  id,
  created_at,
  user_id,
  status,
  token_count,
  sent_count,
  failed_count
FROM public.push_delivery_logs
WHERE (status IN ('success', 'no_tokens') AND created_at < NOW() - INTERVAL '30 days')
   OR (status IN ('partial', 'error', 'invalid_request') AND created_at < NOW() - INTERVAL '90 days')
ORDER BY created_at ASC
LIMIT 100;

-- 3) Execute deletion with RETURNING hidden inside CTEs for summary output
WITH deleted_short_retention AS (
  DELETE FROM public.push_delivery_logs
  WHERE status IN ('success', 'no_tokens')
    AND created_at < NOW() - INTERVAL '30 days'
  RETURNING status, created_at
),
deleted_long_retention AS (
  DELETE FROM public.push_delivery_logs
  WHERE status IN ('partial', 'error', 'invalid_request')
    AND created_at < NOW() - INTERVAL '90 days'
  RETURNING status, created_at
),
deleted AS (
  SELECT * FROM deleted_short_retention
  UNION ALL
  SELECT * FROM deleted_long_retention
)
SELECT
  status,
  COUNT(*) AS deleted_rows,
  MIN(created_at) AS oldest_deleted,
  MAX(created_at) AS newest_deleted
FROM deleted
GROUP BY status
ORDER BY status;

-- 4) Post-delete preview inside the same transaction
SELECT
  status,
  COUNT(*) AS remaining_rows,
  MIN(created_at) AS oldest_remaining,
  MAX(created_at) AS newest_remaining
FROM public.push_delivery_logs
GROUP BY status
ORDER BY status;

ROLLBACK;

-- When you verify the preview is correct, rerun the script and replace
-- ROLLBACK with COMMIT.
