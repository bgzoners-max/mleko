-- Obaveštenje kupcu kada prodavac promeni status porudžbine (prihvati, odbije, isporuči)
CREATE OR REPLACE FUNCTION public.notify_order_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  status_label TEXT;
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    status_label := CASE NEW.status
      WHEN 'accepted' THEN 'Prihvaćeno'
      WHEN 'rejected' THEN 'Odbijeno'
      WHEN 'delivered' THEN 'Isporučeno'
      ELSE NEW.status::text
    END;
    INSERT INTO public.notifications (user_id, order_id, type, title, body)
    VALUES (
      NEW.buyer_id,
      NEW.id,
      'order_status',
      CASE NEW.status
        WHEN 'accepted' THEN 'Prodavac je potvrdio porudžbinu'
        WHEN 'rejected' THEN 'Prodavac je odbio porudžbinu'
        WHEN 'delivered' THEN 'Porudžbina je isporučena'
        ELSE 'Porudžbina ažurirana'
      END,
      'Proizvod: ' || COALESCE(NEW.product_name, '') || ' – ' || status_label
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_order_status_change ON public.orders;
CREATE TRIGGER on_order_status_change
  AFTER UPDATE ON public.orders
  FOR EACH ROW EXECUTE FUNCTION public.notify_order_status_change();
