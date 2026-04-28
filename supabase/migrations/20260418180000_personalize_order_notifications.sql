-- Personalizovana obaveštenja: dodaj ime kupca u new_order notifikaciju

CREATE OR REPLACE FUNCTION public.notify_new_order()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  body_text TEXT;
  buyer_name TEXT;
BEGIN
  SELECT COALESCE(NULLIF(btrim(display_name), ''), 'Kupac')
  INTO buyer_name
  FROM public.profiles
  WHERE id = NEW.buyer_id;

  body_text := COALESCE(buyer_name, 'Kupac') || ': ' ||
    public.build_order_notification_body(
      NEW.id,
      NEW.product_name,
      NEW.quantity_kg,
      NEW.unit_type
    );

  INSERT INTO public.notifications (user_id, order_id, type, title, body)
  VALUES (NEW.seller_id, NEW.id, 'new_order', '🚜 Nova porudžbina', body_text);

  RETURN NEW;
END;
$$;
