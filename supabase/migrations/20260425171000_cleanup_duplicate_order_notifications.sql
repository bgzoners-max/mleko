-- Cleanup and consolidate new order notifications.
-- Ensures only ONE personalized notification is sent for each new order.

-- 1. Drop all possible trigger names that might have been used for new order notifications
-- both regular and constraint triggers.
DROP TRIGGER IF EXISTS on_new_order ON public.orders;
DROP TRIGGER IF EXISTS trg_notify_new_order ON public.orders;
DROP TRIGGER IF EXISTS on_order_inserted ON public.orders;
DROP TRIGGER IF EXISTS notify_new_order_trigger ON public.orders;

-- 2. Ensure the personalized notification function is up to date.
-- Uses '🚜 Nova porudžbina' as title and 'Buyer: Product Info' as body.
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
  -- Fetch buyer display name
  SELECT COALESCE(NULLIF(btrim(display_name), ''), 'Kupac')
  INTO buyer_name
  FROM public.profiles
  WHERE id = NEW.buyer_id;

  -- Build detailed body from order_items (if exist) or order fields (fallback)
  body_text := COALESCE(buyer_name, 'Kupac') || ': ' ||
    public.build_order_notification_body(
      NEW.id,
      NEW.product_name,
      NEW.quantity_kg,
      NEW.unit_type
    );

  -- Insert only ONE notification record.
  -- The type 'new_order' is used by the edge function to handle push delivery.
  INSERT INTO public.notifications (user_id, order_id, type, title, body)
  VALUES (NEW.seller_id, NEW.id, 'new_order', '🚜 Nova porudžbina', body_text);

  RETURN NEW;
END;
$$;

-- 3. Re-create the trigger as a CONSTRAINT TRIGGER.
-- This ensures it fires AFTER all operations in the transaction (like order_items insertion)
-- are complete, allowing build_order_notification_body to fetch correct item info.
CREATE CONSTRAINT TRIGGER on_new_order
  AFTER INSERT ON public.orders
  DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_new_order();

-- 4. Cleanup any duplicate notifications that might have been created recently (optional but good for data integrity)
-- We won't delete existing data to avoid confusion, but we could if needed.
