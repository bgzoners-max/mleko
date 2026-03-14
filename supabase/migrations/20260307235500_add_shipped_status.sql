-- Adds seller-visible/order-visible status "shipped" (label in app: Poslato).
-- Also notifies buyer when seller marks an order as shipped.

ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS orders_status_check;
ALTER TABLE public.orders ADD CONSTRAINT orders_status_check
  CHECK (
    status IN (
      'sent',
      'accepted',
      'shipped',
      'rejected',
      'delivered',
      'cancelled_by_seller',
      'arhivirano'
    )
  );

CREATE OR REPLACE FUNCTION public.notify_order_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_title TEXT;
  v_body TEXT;
BEGIN
  IF NEW.status IS NOT DISTINCT FROM OLD.status THEN
    RETURN NEW;
  END IF;

  IF NEW.status = 'accepted' THEN
    v_title := 'Porudzbina prihvacena';
    v_body := 'Prodavac je prihvatio vasu porudzbinu.';
  ELSIF NEW.status = 'shipped' THEN
    v_title := 'Porudzbina poslata';
    v_body := 'Prodavac je oznacio porudzbinu kao poslatu.';
  ELSIF NEW.status = 'rejected' THEN
    v_title := 'Porudzbina odbijena';
    v_body := 'Prodavac je odbio vasu porudzbinu.';
  ELSIF NEW.status = 'delivered' THEN
    v_title := 'Porudzbina isporucena';
    v_body := 'Prodavac je oznacio porudzbinu kao isporucenu.';
  ELSIF NEW.status = 'cancelled_by_seller' THEN
    v_title := 'Porudzbina otkazana';
    v_body := 'Prodavac je otkazao porudzbinu.';
  ELSE
    RETURN NEW;
  END IF;

  INSERT INTO public.notifications (user_id, order_id, type, title, body)
  VALUES (NEW.buyer_id, NEW.id, 'order_status_changed', v_title, v_body);

  RETURN NEW;
END;
$$;
