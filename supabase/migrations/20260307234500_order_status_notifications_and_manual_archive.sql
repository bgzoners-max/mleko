-- Buyer must track status until manual archive.
-- 1) Notify buyer when seller changes order status.
-- 2) Disable auto-archiving from retention job.

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

DROP TRIGGER IF EXISTS on_order_status_changed_notify_buyer ON public.orders;
CREATE TRIGGER on_order_status_changed_notify_buyer
  AFTER UPDATE OF status ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_order_status_change();

-- Retention: no auto-archive; only delete archived orders after expiry.
CREATE OR REPLACE FUNCTION public.handle_order_retention()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  DELETE FROM public.orders
  WHERE status = 'arhivirano'
    AND expires_at IS NOT NULL
    AND expires_at <= now();
END;
$$;

CREATE OR REPLACE FUNCTION public.archive_and_expire_orders()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public.handle_order_retention();
END;
$$;
