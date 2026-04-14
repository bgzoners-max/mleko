-- Archive-first cleanup for push_delivery_logs.
-- Creates an archive table if needed, previews affected rows, copies them,
-- deletes them from the live table, and leaves the whole transaction rolled back
-- by default. Replace the final ROLLBACK with COMMIT only after verification.

BEGIN;

-- 0) Ensure archive table exists with the same structure.
CREATE TABLE IF NOT EXISTS public.push_delivery_logs_archive (
  LIKE public.push_delivery_logs INCLUDING ALL
);

-- 1) Preview rows targeted by the recommended retention policy.
WITH candidates AS (
  SELECT *
  FROM public.push_delivery_logs
  WHERE (status IN ('success', 'no_tokens') AND created_at < NOW() - INTERVAL '30 days')
     OR (status IN ('partial', 'error', 'invalid_request') AND created_at < NOW() - INTERVAL '90 days')
)
SELECT
  status,
  COUNT(*) AS rows_to_archive,
  MIN(created_at) AS oldest_row,
  MAX(created_at) AS newest_row
FROM candidates
GROUP BY status
ORDER BY status;

-- 2) Sample candidates before moving them.
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

-- 3) Copy to archive and delete from live table.
WITH moved_rows AS (
  DELETE FROM public.push_delivery_logs
  WHERE (status IN ('success', 'no_tokens') AND created_at < NOW() - INTERVAL '30 days')
     OR (status IN ('partial', 'error', 'invalid_request') AND created_at < NOW() - INTERVAL '90 days')
  RETURNING *
),
archived AS (
  INSERT INTO public.push_delivery_logs_archive
  SELECT * FROM moved_rows
  RETURNING status, created_at
)
SELECT
  status,
  COUNT(*) AS archived_rows,
  MIN(created_at) AS oldest_archived,
  MAX(created_at) AS newest_archived
FROM archived
GROUP BY status
ORDER BY status;

-- 4) Preview resulting live-table retention.
SELECT
  status,
  COUNT(*) AS remaining_rows,
  MIN(created_at) AS oldest_remaining,
  MAX(created_at) AS newest_remaining
FROM public.push_delivery_logs
GROUP BY status
ORDER BY status;

-- 5) Preview resulting archive-table retention.
SELECT
  status,
  COUNT(*) AS archived_rows,
  MIN(created_at) AS oldest_archived,
  MAX(created_at) AS newest_archived
FROM public.push_delivery_logs_archive
GROUP BY status
ORDER BY status;

ROLLBACK;

-- After review, rerun and replace ROLLBACK with COMMIT.
