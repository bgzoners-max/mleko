-- In-app + push kada neko dobije novu recenziju (isti tok kao za porudžbine → invoke_send_push).

-- Kupac oceni prodavca → obaveštenje prodavcu
CREATE OR REPLACE FUNCTION public.notify_new_review_for_seller()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  snippet TEXT;
BEGIN
  snippet := trim(COALESCE(NEW.comment, ''));
  IF length(snippet) > 100 THEN
    snippet := left(snippet, 97) || '...';
  END IF;

  INSERT INTO public.notifications (user_id, order_id, type, title, body)
  VALUES (
    NEW.seller_id,
    NEW.order_id,
    'new_review',
    'Nova recenzija',
    'Kupac je ostavio ocenu ' || NEW.rating::text || '/5.' ||
      CASE WHEN snippet <> '' THEN ' „' || snippet || '“' ELSE '' END
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_review_insert_notify_seller ON public.reviews;
CREATE TRIGGER on_review_insert_notify_seller
  AFTER INSERT ON public.reviews
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_new_review_for_seller();

-- Prodavac oceni kupca → obaveštenje kupcu
CREATE OR REPLACE FUNCTION public.notify_new_buyer_review_for_buyer()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  snippet TEXT;
BEGIN
  snippet := trim(COALESCE(NEW.comment, ''));
  IF length(snippet) > 100 THEN
    snippet := left(snippet, 97) || '...';
  END IF;

  INSERT INTO public.notifications (user_id, order_id, type, title, body)
  VALUES (
    NEW.buyer_id,
    NEW.order_id,
    'new_buyer_review',
    'Nova recenzija o tebi',
    'Prodavac je ostavio ocenu ' || NEW.rating::text || '/5.' ||
      CASE WHEN snippet <> '' THEN ' „' || snippet || '“' ELSE '' END
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_buyer_review_insert_notify_buyer ON public.buyer_reviews;
CREATE TRIGGER on_buyer_review_insert_notify_buyer
  AFTER INSERT ON public.buyer_reviews
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_new_buyer_review_for_buyer();
