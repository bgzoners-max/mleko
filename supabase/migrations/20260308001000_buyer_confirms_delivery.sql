-- Order is completed only when buyer confirms receipt.

CREATE OR REPLACE FUNCTION public.buyer_confirm_order_received(p_order_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_updated INT;
BEGIN
  UPDATE public.orders
  SET status = 'delivered'
  WHERE id = p_order_id
    AND buyer_id = auth.uid()
    AND status = 'shipped';

  GET DIAGNOSTICS v_updated = ROW_COUNT;
  RETURN v_updated > 0;
END;
$$;

REVOKE ALL ON FUNCTION public.buyer_confirm_order_received(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.buyer_confirm_order_received(UUID) TO authenticated;

CREATE OR REPLACE FUNCTION public.notify_order_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_title TEXT;
  v_body TEXT;
  v_target_user UUID;
BEGIN
  IF NEW.status IS NOT DISTINCT FROM OLD.status THEN
    RETURN NEW;
  END IF;

  IF NEW.status = 'accepted' THEN
    v_target_user := NEW.buyer_id;
    v_title := 'Porudzbina prihvacena';
    v_body := 'Prodavac je prihvatio vasu porudzbinu.';
  ELSIF NEW.status = 'shipped' THEN
    v_target_user := NEW.buyer_id;
    v_title := 'Porudzbina poslata';
    v_body := 'Prodavac je oznacio porudzbinu kao poslatu.';
  ELSIF NEW.status = 'rejected' THEN
    v_target_user := NEW.buyer_id;
    v_title := 'Porudzbina odbijena';
    v_body := 'Prodavac je odbio vasu porudzbinu.';
  ELSIF NEW.status = 'cancelled_by_seller' THEN
    v_target_user := NEW.buyer_id;
    v_title := 'Porudzbina otkazana';
    v_body := 'Prodavac je otkazao porudzbinu.';
  ELSIF NEW.status = 'delivered' THEN
    v_target_user := NEW.seller_id;
    v_title := 'Kupac potvrdio prijem';
    v_body := 'Kupac je potvrdio da je primio porudzbinu.';
  ELSE
    RETURN NEW;
  END IF;

  INSERT INTO public.notifications (user_id, order_id, type, title, body)
  VALUES (v_target_user, NEW.id, 'order_status_changed', v_title, v_body);

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_order_status_changed_notify_buyer ON public.orders;
CREATE TRIGGER on_order_status_changed_notify_buyer
  AFTER UPDATE OF status ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_order_status_change();
