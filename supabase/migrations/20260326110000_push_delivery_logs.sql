-- Structured delivery logs for push notifications.
-- Allows SQL diagnostics for last failed sends and delivery health.

CREATE TABLE IF NOT EXISTS public.push_delivery_logs (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  request_id UUID NOT NULL,
  source TEXT NOT NULL DEFAULT 'send-push',
  user_id UUID NULL,
  title TEXT NULL,
  type TEXT NULL,
  token_count INT NOT NULL DEFAULT 0,
  sent_count INT NOT NULL DEFAULT 0,
  failed_count INT NOT NULL DEFAULT 0,
  status TEXT NOT NULL CHECK (status IN ('success', 'partial', 'error', 'no_tokens', 'invalid_request')),
  errors JSONB NOT NULL DEFAULT '[]'::jsonb,
  payload JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_push_delivery_logs_created_at
  ON public.push_delivery_logs (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_push_delivery_logs_status_created_at
  ON public.push_delivery_logs (status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_push_delivery_logs_user_created_at
  ON public.push_delivery_logs (user_id, created_at DESC);

ALTER TABLE public.push_delivery_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Service role manages push delivery logs" ON public.push_delivery_logs;
CREATE POLICY "Service role manages push delivery logs"
  ON public.push_delivery_logs
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);
