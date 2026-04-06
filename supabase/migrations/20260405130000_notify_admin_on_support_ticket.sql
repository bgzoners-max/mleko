-- Na novi support tiket kreiraj adminima in-app notifikaciju.
-- Push se zatim automatski šalje preko postojećeg triggera na public.notifications.

CREATE OR REPLACE FUNCTION public.notify_admins_on_support_ticket()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  ticket_label text;
  title_text text;
  body_text text;
BEGIN
  ticket_label := COALESCE(NULLIF(NEW.ticket_number, ''), 'novi tiket');
  title_text := 'Novi tiket podrške';
  body_text := '[' || ticket_label || '] '
    || COALESCE(NULLIF(NEW.subject, ''), 'Bez naslova');

  INSERT INTO public.notifications (user_id, type, title, body)
  SELECT p.id, 'support_ticket_created', title_text, body_text
  FROM public.profiles p
  WHERE p.is_admin = true;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_support_ticket_notify_admins ON public.support_tickets;
CREATE TRIGGER on_support_ticket_notify_admins
  AFTER INSERT ON public.support_tickets
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_admins_on_support_ticket();
