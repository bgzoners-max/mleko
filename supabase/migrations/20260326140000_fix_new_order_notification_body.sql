-- Fix new order notification body.
-- Root cause: notify_new_order fires on orders insert before order_items exist.
-- Solution: use deferred trigger and build body from order_items when transaction finishes.

CREATE OR REPLACE FUNCTION public.build_order_notification_body(
  p_order_id UUID,
  p_fallback_product_name TEXT DEFAULT NULL,
  p_fallback_quantity NUMERIC DEFAULT NULL,
  p_fallback_unit_type TEXT DEFAULT 'kg'
)
RETURNS TEXT
LANGUAGE plpgsql
STABLE
SET search_path = public
AS $$
DECLARE
  v_item_count INT;
  v_product_name TEXT;
  v_quantity NUMERIC;
  v_unit_type TEXT;
  v_quantity_text TEXT;
BEGIN
  SELECT COUNT(*) INTO v_item_count
  FROM public.order_items
  WHERE order_id = p_order_id;

  IF v_item_count > 1 THEN
    RETURN v_item_count::text || ' proizvoda u porudžbini';
  END IF;

  IF v_item_count = 1 THEN
    SELECT product_name, quantity_kg, unit_type
    INTO v_product_name, v_quantity, v_unit_type
    FROM public.order_items
    WHERE order_id = p_order_id
    LIMIT 1;
  ELSE
    v_product_name := p_fallback_product_name;
    v_quantity := p_fallback_quantity;
    v_unit_type := COALESCE(NULLIF(p_fallback_unit_type, ''), 'kg');
  END IF;

  IF v_product_name IS NULL OR btrim(v_product_name) = '' THEN
    RETURN 'Nova porudžbina';
  END IF;

  v_quantity_text := CASE
    WHEN v_quantity IS NULL THEN NULL
    WHEN trunc(v_quantity) = v_quantity THEN trunc(v_quantity)::text
    ELSE trim(trailing '.' from trim(trailing '0' from v_quantity::text))
  END;

  IF v_quantity_text IS NULL OR v_quantity_text = '' THEN
    RETURN 'Proizvod: ' || v_product_name;
  END IF;

  RETURN 'Proizvod: ' || v_product_name || ' – ' || v_quantity_text || ' ' || COALESCE(NULLIF(v_unit_type, ''), 'kg');
END;
$$;

CREATE OR REPLACE FUNCTION public.notify_new_order()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  body_text TEXT;
BEGIN
  body_text := public.build_order_notification_body(
    NEW.id,
    NEW.product_name,
    NEW.quantity_kg,
    NEW.unit_type
  );

  INSERT INTO public.notifications (user_id, order_id, type, title, body)
  VALUES (NEW.seller_id, NEW.id, 'new_order', 'Nova porudžbina', body_text);

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_new_order ON public.orders;
CREATE CONSTRAINT TRIGGER on_new_order
  AFTER INSERT ON public.orders
  DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_new_order();

UPDATE public.notifications n
SET body = public.build_order_notification_body(
  n.order_id,
  o.product_name,
  o.quantity_kg,
  o.unit_type
)
FROM public.orders o
WHERE n.order_id = o.id
  AND n.type = 'new_order'
  AND n.body = 'Proizvod:  – 0 kg';
