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
    v_title := 'Porudžbina prihvaćena';
    v_body := 'Prodavac je prihvatio vašu porudžbinu.';
  ELSIF NEW.status = 'shipped' THEN
    v_target_user := NEW.buyer_id;
    v_title := 'Porudžbina poslata';
    v_body := 'Prodavac je označio porudžbinu kao poslatu.';
  ELSIF NEW.status = 'rejected' THEN
    v_target_user := NEW.buyer_id;
    v_title := 'Porudžbina odbijena';
    v_body := 'Prodavac je odbio vašu porudžbinu.';
  ELSIF NEW.status = 'cancelled_by_seller' THEN
    v_target_user := NEW.buyer_id;
    v_title := 'Porudžbina otkazana';
    v_body := 'Prodavac je otkazao porudžbinu.';
  ELSIF NEW.status = 'delivered' THEN
    v_target_user := NEW.seller_id;
    v_title := 'Kupac potvrdio prijem';
    v_body := 'Kupac je potvrdio da je primio porudžbinu.';

    -- Dodatna notifikacija za kupca da oceni proizvod i prodavca
    INSERT INTO public.notifications (user_id, order_id, type, title, body)
    VALUES (NEW.buyer_id, NEW.id, 'order_status_changed', 'Ocenite porudžbinu', 'Vaša porudžbina je isporučena! Molimo vas odvojite trenutak da ocenite proizvod i prodavca.');
  ELSE
    RETURN NEW;
  END IF;

  INSERT INTO public.notifications (user_id, order_id, type, title, body)
  VALUES (v_target_user, NEW.id, 'order_status_changed', v_title, v_body);

  RETURN NEW;
END;
$$;
