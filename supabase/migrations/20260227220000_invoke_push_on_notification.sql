-- Poziv Edge Function send-push kada se doda obaveštenje
-- Zahteva: pg_net extension (enable u Dashboard: Database → Extensions)

CREATE EXTENSION IF NOT EXISTS pg_net;

-- Konfiguracija za poziv Edge Function
CREATE TABLE IF NOT EXISTS public.edge_config (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

-- Podrazumevano za lokalni Supabase (port 54321)
INSERT INTO public.edge_config (key, value)
VALUES 
  ('functions_base_url', 'http://host.docker.internal:54321'),
  ('anon_key', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0')
ON CONFLICT (key) DO NOTHING;

-- Za produkciju pokreni:
-- UPDATE public.edge_config SET value = 'https://YOUR_PROJECT_REF.supabase.co' WHERE key = 'functions_base_url';
-- UPDATE public.edge_config SET value = 'YOUR_ANON_KEY' WHERE key = 'anon_key';

CREATE OR REPLACE FUNCTION public.invoke_send_push()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  base_url TEXT;
  anon_key TEXT;
  fn_url TEXT;
BEGIN
  SELECT value INTO base_url FROM public.edge_config WHERE key = 'functions_base_url' LIMIT 1;
  SELECT value INTO anon_key FROM public.edge_config WHERE key = 'anon_key' LIMIT 1;
  IF base_url IS NULL OR base_url = '' THEN
    RETURN NEW;
  END IF;

  fn_url := base_url || '/functions/v1/send-push';

  PERFORM net.http_post(
    url := fn_url,
    body := jsonb_build_object(
      'user_id', NEW.user_id,
      'title', NEW.title,
      'body', COALESCE(NEW.body, ''),
      'type', COALESCE(NEW.type, ''),
      'order_id', CASE WHEN NEW.order_id IS NOT NULL THEN NEW.order_id::text ELSE '' END
    ),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || COALESCE(anon_key, '')
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

DROP TRIGGER IF EXISTS on_notification_insert_send_push ON public.notifications;
CREATE TRIGGER on_notification_insert_send_push
  AFTER INSERT ON public.notifications
  FOR EACH ROW
  EXECUTE FUNCTION public.invoke_send_push();
