-- Otkazivanje porudžbine od strane prodavca (nakon prihvatanja)
-- Dodajemo status 'cancelled_by_seller' i kolonu cancellation_reason

ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS cancellation_reason TEXT;

-- Proširujemo CHECK constraint za status
ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS orders_status_check;
ALTER TABLE public.orders ADD CONSTRAINT orders_status_check
  CHECK (status IN ('sent', 'accepted', 'rejected', 'delivered', 'cancelled_by_seller'));

-- Ažuriranje notify_order_status_change za cancelled_by_seller
CREATE OR REPLACE FUNCTION public.notify_order_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  status_label TEXT;
  body_text TEXT;
  item_count INT;
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    status_label := CASE NEW.status
      WHEN 'accepted' THEN 'Prihvaćeno'
      WHEN 'rejected' THEN 'Odbijeno'
      WHEN 'delivered' THEN 'Isporučeno'
      WHEN 'cancelled_by_seller' THEN 'Otkazano'
      ELSE NEW.status::text
    END;
    SELECT COUNT(*) INTO item_count FROM public.order_items WHERE order_id = NEW.id;
    IF item_count > 0 THEN
      body_text := item_count::text || ' proizvod(a) – ' || status_label;
    ELSE
      body_text := 'Proizvod: ' || COALESCE(NEW.product_name, '') || ' – ' || status_label;
    END IF;
    IF NEW.status = 'cancelled_by_seller' AND NEW.cancellation_reason IS NOT NULL AND NEW.cancellation_reason != '' THEN
      body_text := body_text || E'\nRazlog: ' || NEW.cancellation_reason;
    END IF;
    INSERT INTO public.notifications (user_id, order_id, type, title, body)
    VALUES (
      NEW.buyer_id,
      NEW.id,
      'order_status',
      CASE NEW.status
        WHEN 'accepted' THEN 'Prodavac je potvrdio porudžbinu'
        WHEN 'rejected' THEN 'Prodavac je odbio porudžbinu'
        WHEN 'delivered' THEN 'Porudžbina je isporučena'
        WHEN 'cancelled_by_seller' THEN 'Prodavac je otkazao porudžbinu'
        ELSE 'Porudžbina ažurirana'
      END,
      body_text
    );
  END IF;
  RETURN NEW;
END;
$$;
