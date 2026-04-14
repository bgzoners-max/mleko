-- Scope push tokens to a concrete app installation so logout removes only
-- the current device and token refreshes stay tied to one row.

ALTER TABLE public.user_push_tokens
  ADD COLUMN IF NOT EXISTS installation_id TEXT;

ALTER TABLE public.user_push_tokens
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

UPDATE public.user_push_tokens
SET installation_id = COALESCE(installation_id, 'legacy-' || id::text),
    updated_at = COALESCE(updated_at, created_at, NOW())
WHERE installation_id IS NULL OR updated_at IS NULL;

ALTER TABLE public.user_push_tokens
  ALTER COLUMN installation_id SET NOT NULL;

ALTER TABLE public.user_push_tokens
  ALTER COLUMN updated_at SET NOT NULL;

CREATE INDEX IF NOT EXISTS idx_push_tokens_installation
  ON public.user_push_tokens(installation_id);

CREATE UNIQUE INDEX IF NOT EXISTS idx_push_tokens_user_installation_unique
  ON public.user_push_tokens(user_id, installation_id);

CREATE OR REPLACE FUNCTION public.cleanup_push_tokens(
  p_keep_per_user INT DEFAULT 3,
  p_max_age INTERVAL DEFAULT INTERVAL '60 days'
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
      COALESCE(updated_at, created_at) AS activity_at,
      row_number() OVER (
        PARTITION BY user_id
        ORDER BY COALESCE(updated_at, created_at) DESC, id DESC
      ) AS rn
    FROM public.user_push_tokens
  ),
  to_delete AS (
    SELECT id
    FROM ranked
    WHERE rn > GREATEST(p_keep_per_user, 1)
       OR activity_at < NOW() - p_max_age
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
