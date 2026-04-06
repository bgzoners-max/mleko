-- support_ticket_messages: chat između admina i korisnika na tiketu (max 5 poruka po strani)

-- Dodaj ticket_id na notifications za pravilno rutiranje
ALTER TABLE public.notifications
  ADD COLUMN IF NOT EXISTS ticket_id uuid REFERENCES public.support_tickets(id) ON DELETE SET NULL;

-- Tabela poruka
CREATE TABLE IF NOT EXISTS public.support_ticket_messages (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id   uuid        NOT NULL REFERENCES public.support_tickets(id) ON DELETE CASCADE,
  sender_id   uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  sender_role text        NOT NULL CHECK (sender_role IN ('user', 'admin')),
  body        text        NOT NULL CHECK (char_length(body) BETWEEN 1 AND 2000),
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_support_ticket_messages_ticket
  ON public.support_ticket_messages(ticket_id, created_at);

-- Limit: max 5 poruka po strani po tiketu
CREATE OR REPLACE FUNCTION public.check_ticket_message_limit()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  msg_count integer;
BEGIN
  SELECT COUNT(*) INTO msg_count
  FROM public.support_ticket_messages
  WHERE ticket_id = NEW.ticket_id AND sender_role = NEW.sender_role;
  IF msg_count >= 5 THEN
    RAISE EXCEPTION 'Dostignut je maksimalan broj poruka (5) za ovu stranu.';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_check_ticket_message_limit ON public.support_ticket_messages;
CREATE TRIGGER trg_check_ticket_message_limit
  BEFORE INSERT ON public.support_ticket_messages
  FOR EACH ROW EXECUTE FUNCTION public.check_ticket_message_limit();

-- RLS
ALTER TABLE public.support_ticket_messages ENABLE ROW LEVEL SECURITY;

-- Korisnik: čita poruke za svoje tikete
DROP POLICY IF EXISTS "user_select_ticket_messages" ON public.support_ticket_messages;
CREATE POLICY "user_select_ticket_messages" ON public.support_ticket_messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.support_tickets t
      WHERE t.id = ticket_id AND t.user_id = auth.uid()
    )
  );

-- Korisnik: šalje poruke (samo kao 'user', tiket ne smije biti zatvoren)
DROP POLICY IF EXISTS "user_insert_ticket_message" ON public.support_ticket_messages;
CREATE POLICY "user_insert_ticket_message" ON public.support_ticket_messages
  FOR INSERT WITH CHECK (
    sender_id = auth.uid()
    AND sender_role = 'user'
    AND EXISTS (
      SELECT 1 FROM public.support_tickets t
      WHERE t.id = ticket_id AND t.user_id = auth.uid()
        AND t.status <> 'zatvoren'
    )
  );

-- Admin: čita sve poruke
DROP POLICY IF EXISTS "admin_select_ticket_messages" ON public.support_ticket_messages;
CREATE POLICY "admin_select_ticket_messages" ON public.support_ticket_messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.is_admin = true
    )
  );

-- Admin: šalje poruke kao 'admin'
DROP POLICY IF EXISTS "admin_insert_ticket_message" ON public.support_ticket_messages;
CREATE POLICY "admin_insert_ticket_message" ON public.support_ticket_messages
  FOR INSERT WITH CHECK (
    sender_id = auth.uid()
    AND sender_role = 'admin'
    AND EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.is_admin = true
    )
  );

-- Obavesti korisnika kad admin pošalje poruku
CREATE OR REPLACE FUNCTION public.notify_user_on_admin_ticket_reply()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_user_id    uuid;
  v_ticket_num text;
BEGIN
  IF NEW.sender_role <> 'admin' THEN RETURN NEW; END IF;

  SELECT t.user_id, t.ticket_number
  INTO v_user_id, v_ticket_num
  FROM public.support_tickets t
  WHERE t.id = NEW.ticket_id;

  IF v_user_id IS NULL THEN RETURN NEW; END IF;

  INSERT INTO public.notifications (user_id, ticket_id, type, title, body)
  VALUES (
    v_user_id,
    NEW.ticket_id,
    'admin_reply',
    'Odgovor administratora',
    '[' || COALESCE(v_ticket_num, 'tiket') || '] ' || LEFT(NEW.body, 100)
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_admin_ticket_message_notify_user ON public.support_ticket_messages;
CREATE TRIGGER on_admin_ticket_message_notify_user
  AFTER INSERT ON public.support_ticket_messages
  FOR EACH ROW EXECUTE FUNCTION public.notify_user_on_admin_ticket_reply();

-- Ažuriraj invoke_send_push da uključuje ticket_id u payload
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
      'order_id', CASE WHEN NEW.order_id IS NOT NULL THEN NEW.order_id::text ELSE '' END,
      'ticket_id', CASE WHEN NEW.ticket_id IS NOT NULL THEN NEW.ticket_id::text ELSE '' END
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

-- Realtime za support_ticket_messages
ALTER PUBLICATION supabase_realtime ADD TABLE public.support_ticket_messages;
