-- Ensure order status notifications use Serbian diacritics.

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
  ELSE
    RETURN NEW;
  END IF;

  INSERT INTO public.notifications (user_id, order_id, type, title, body)
  VALUES (v_target_user, NEW.id, 'order_status_changed', v_title, v_body);

  RETURN NEW;
END;
$$;

-- Backfill legacy ASCII-only texts so existing notifications are shown correctly.
UPDATE public.notifications
SET
  title = CASE title
    WHEN 'Porudzbina prihvacena' THEN 'Porudžbina prihvaćena'
    WHEN 'Porudzbina poslata' THEN 'Porudžbina poslata'
    WHEN 'Porudzbina odbijena' THEN 'Porudžbina odbijena'
    WHEN 'Porudzbina otkazana' THEN 'Porudžbina otkazana'
    ELSE title
  END,
  body = CASE body
    WHEN 'Prodavac je prihvatio vasu porudzbinu.' THEN 'Prodavac je prihvatio vašu porudžbinu.'
    WHEN 'Prodavac je oznacio porudzbinu kao poslatu.' THEN 'Prodavac je označio porudžbinu kao poslatu.'
    WHEN 'Prodavac je odbio vasu porudzbinu.' THEN 'Prodavac je odbio vašu porudžbinu.'
    WHEN 'Prodavac je otkazao porudzbinu.' THEN 'Prodavac je otkazao porudžbinu.'
    WHEN 'Kupac je potvrdio da je primio porudzbinu.' THEN 'Kupac je potvrdio da je primio porudžbinu.'
    ELSE body
  END
WHERE type = 'order_status_changed';
