-- Daily cleanup for stale/duplicate push tokens.
-- Keeps only the newest N tokens per user and removes very old tokens.

CREATE OR REPLACE FUNCTION public.cleanup_push_tokens(
  p_keep_per_user INT DEFAULT 3,
  p_max_age INTERVAL DEFAULT INTERVAL '90 days'
)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_deleted INT := 0;
BEGIN
  WITH ranked AS (
    SELECT
      id,
      user_id,
      created_at,
      row_number() OVER (
        PARTITION BY user_id
        ORDER BY created_at DESC, id DESC
      ) AS rn
    FROM public.user_push_tokens
  ),
  to_delete AS (
    SELECT id
    FROM ranked
    WHERE rn > GREATEST(p_keep_per_user, 1)
       OR created_at < NOW() - p_max_age
  ),
  deleted AS (
    DELETE FROM public.user_push_tokens t
    USING to_delete d
    WHERE t.id = d.id
    RETURNING 1
  )
  SELECT COUNT(*) INTO v_deleted FROM deleted;

  RETURN v_deleted;
END;
$$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'daily_push_token_cleanup') THEN
      PERFORM cron.unschedule('daily_push_token_cleanup');
    END IF;
  END IF;
EXCEPTION WHEN undefined_object THEN NULL;
END
$$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    PERFORM cron.schedule(
      'daily_push_token_cleanup',
      '15 3 * * *',
      'SELECT public.cleanup_push_tokens(3, INTERVAL ''90 days'')'
    );
  END IF;
EXCEPTION WHEN undefined_object THEN NULL;
END
$$;
