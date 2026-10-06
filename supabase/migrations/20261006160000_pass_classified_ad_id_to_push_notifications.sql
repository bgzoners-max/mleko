-- ============================================================================
-- Migracija 20261006160000: Prosleđivanje classified_ad_id i apikey hedera u push notifikacije
-- ============================================================================

-- 1. Ažuriraj send_push_notification da šalje apikey i Authorization hedere
CREATE OR REPLACE FUNCTION public.send_push_notification(
  p_user_id         uuid,
  p_title           text,
  p_body            text,
  p_type            text,
  p_order_id        text  DEFAULT ''::text,
  p_ticket_id       text  DEFAULT ''::text,
  p_conversation_id text  DEFAULT ''::text,
  p_data            jsonb DEFAULT '{}'::jsonb
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  base_url    TEXT;
  service_key TEXT;
  fn_url      TEXT;
BEGIN
  IF p_user_id IS NULL THEN
    RETURN false;
  END IF;

  -- 1. Čitanje service_role_key isključivo iz Supabase Vault-a
  BEGIN
    SELECT decrypted_secret INTO service_key 
    FROM vault.decrypted_secrets 
    WHERE name = 'service_role_key' 
    LIMIT 1;
  EXCEPTION WHEN OTHERS THEN
    service_key := NULL;
  END;

  -- 2. Čitanje functions_base_url iz Vault-a ili edge_config fallback
  BEGIN
    SELECT decrypted_secret INTO base_url 
    FROM vault.decrypted_secrets 
    WHERE name = 'functions_base_url' 
    LIMIT 1;
  EXCEPTION WHEN OTHERS THEN
    base_url := NULL;
  END;

  IF base_url IS NULL OR base_url = '' THEN
    SELECT value INTO base_url FROM public.edge_config WHERE key = 'functions_base_url' LIMIT 1;
  END IF;

  IF service_key IS NULL OR service_key = '' OR base_url IS NULL OR base_url = '' THEN
    RAISE WARNING 'send_push_notification: Nedostaje konfiguracija (Vault service_role_key ili URL).';
    RETURN false;
  END IF;

  fn_url := base_url || '/functions/v1/send-push';

  PERFORM net.http_post(
    url := fn_url,
    body := jsonb_build_object(
      'user_id', p_user_id,
      'title', COALESCE(p_title, ''),
      'body', COALESCE(p_body, ''),
      'type', COALESCE(p_type, ''),
      'order_id', COALESCE(p_order_id, ''),
      'ticket_id', COALESCE(p_ticket_id, ''),
      'conversation_id', COALESCE(p_conversation_id, ''),
      'data', COALESCE(p_data, '{}'::jsonb)
    ),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || service_key,
      'apikey', service_key
    ),
    timeout_milliseconds := 5000
  );

  RETURN true;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'send_push_notification greška: %', SQLERRM;
  RETURN false;
END;
$$;

-- 2. Ažuriraj invoke_send_push trigger funkciju da prosledi i classified_ad_id
CREATE OR REPLACE FUNCTION public.invoke_send_push()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public.send_push_notification(
    p_user_id := NEW.user_id,
    p_title := COALESCE(NEW.title, ''),
    p_body := COALESCE(NEW.body, ''),
    p_type := COALESCE(NEW.type::text, ''),
    p_order_id := CASE WHEN NEW.order_id IS NOT NULL THEN NEW.order_id::text ELSE '' END,
    p_ticket_id := CASE WHEN NEW.ticket_id IS NOT NULL THEN NEW.ticket_id::text ELSE '' END,
    p_conversation_id := CASE WHEN NEW.conversation_id IS NOT NULL THEN NEW.conversation_id::text ELSE '' END,
    p_data := jsonb_build_object(
      'classified_ad_id', CASE WHEN NEW.classified_ad_id IS NOT NULL THEN NEW.classified_ad_id::text ELSE '' END
    )
  );
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'invoke_send_push greška: %', SQLERRM;
  RETURN NEW;
END;
$$;
