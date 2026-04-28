-- Dodavanje conversation_id u notifications i ažuriranje push trigera za chat navigaciju

-- 1. Dodaj kolonu u notifications tabelu
ALTER TABLE public.notifications 
ADD COLUMN IF NOT EXISTS conversation_id UUID REFERENCES public.conversations(id) ON DELETE SET NULL;

-- 2. Ažuriraj notify_new_message funkciju da ubacuje conversation_id
CREATE OR REPLACE FUNCTION public.notify_new_message()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_buyer_id UUID;
  v_seller_id UUID;
  v_recipient_id UUID;
  v_sender_name TEXT;
BEGIN
  SELECT buyer_id, seller_id INTO v_buyer_id, v_seller_id
  FROM public.conversations WHERE id = NEW.conversation_id;

  IF NEW.sender_id = v_buyer_id THEN
    v_recipient_id := v_seller_id;
  ELSE
    v_recipient_id := v_buyer_id;
  END IF;

  SELECT COALESCE(farm_name, display_name, 'Korisnik') INTO v_sender_name
  FROM public.profiles WHERE id = NEW.sender_id;

  INSERT INTO notifications (user_id, type, title, body, conversation_id)
  VALUES (
    v_recipient_id,
    'new_message',
    'Nova poruka',
    COALESCE(v_sender_name, 'Korisnik') || ': ' || LEFT(NEW.body, 80),
    NEW.conversation_id
  );
  RETURN NEW;
END;
$$;

-- 3. Ažuriraj invoke_send_push da uključuje conversation_id u payload
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
      'title', COALESCE(NEW.title, ''),
      'body', COALESCE(NEW.body, ''),
      'type', COALESCE(NEW.type::text, ''),
      'order_id', CASE WHEN NEW.order_id IS NOT NULL THEN NEW.order_id::text ELSE '' END,
      'ticket_id', CASE WHEN NEW.ticket_id IS NOT NULL THEN NEW.ticket_id::text ELSE '' END,
      'conversation_id', CASE WHEN NEW.conversation_id IS NOT NULL THEN NEW.conversation_id::text ELSE '' END
    ),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || COALESCE(anon_key, ''),
      'apikey', COALESCE(anon_key, '')
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
