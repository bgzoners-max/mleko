-- Obaveštenje primaocu kada stigne nova poruka
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

  INSERT INTO notifications (user_id, type, title, body)
  VALUES (
    v_recipient_id,
    'new_message',
    'Nova poruka',
    COALESCE(v_sender_name, 'Korisnik') || ': ' || LEFT(NEW.body, 80)
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_new_message ON public.messages;
CREATE TRIGGER on_new_message
  AFTER INSERT ON public.messages
  FOR EACH ROW EXECUTE FUNCTION public.notify_new_message();
