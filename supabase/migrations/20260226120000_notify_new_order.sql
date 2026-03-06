-- Trigger: obaveštenje prodavcu kada kupac pošalje novu porudžbinu
CREATE OR REPLACE FUNCTION public.notify_new_order()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO notifications (user_id, order_id, type, title, body)
  VALUES (
    NEW.seller_id,
    NEW.id,
    'new_order',
    'Nova porudžbina',
    'Proizvod: ' || NEW.product_name || ' – ' || NEW.quantity_kg::text || ' kg'
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_new_order ON public.orders;
CREATE TRIGGER on_new_order
  AFTER INSERT ON public.orders
  FOR EACH ROW EXECUTE FUNCTION public.notify_new_order();
