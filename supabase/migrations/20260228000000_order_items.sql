-- Porudžbina sa više proizvoda od istog prodavca
-- order_items: stavke za porudžbine (jedna ili više po proizvodu)

CREATE TABLE IF NOT EXISTS public.order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE SET NULL,
  product_name TEXT NOT NULL,
  quantity_kg NUMERIC NOT NULL,
  UNIQUE(order_id, product_id)
);

ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Order items visible to buyer and seller" ON public.order_items;
CREATE POLICY "Order items visible to buyer and seller"
  ON public.order_items FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.orders o
      WHERE o.id = order_id AND (auth.uid() = o.buyer_id OR auth.uid() = o.seller_id)
    )
  );

DROP POLICY IF EXISTS "Buyers can insert order items" ON public.order_items;
CREATE POLICY "Buyers can insert order items"
  ON public.order_items FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.orders o
      WHERE o.id = order_id AND auth.uid() = o.buyer_id
    )
  );

-- orders: product_id, product_name, quantity_kg postaju nullable za multi-item porudžbine
ALTER TABLE public.orders ALTER COLUMN product_id DROP NOT NULL;
ALTER TABLE public.orders ALTER COLUMN product_name DROP NOT NULL;
ALTER TABLE public.orders ALTER COLUMN quantity_kg DROP NOT NULL;

-- Ažuriranje notify_new_order za multi-item (koristi order_items ako postoji)
CREATE OR REPLACE FUNCTION public.notify_new_order()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  body_text TEXT;
  item_count INT;
BEGIN
  SELECT COUNT(*) INTO item_count FROM public.order_items WHERE order_id = NEW.id;
  IF item_count > 0 THEN
    body_text := item_count::text || ' proizvod(a) u porudžbini';
  ELSE
    body_text := 'Proizvod: ' || COALESCE(NEW.product_name, '') || ' – ' || COALESCE(NEW.quantity_kg::text, '0') || ' kg';
  END IF;
  INSERT INTO notifications (user_id, order_id, type, title, body)
  VALUES (NEW.seller_id, NEW.id, 'new_order', 'Nova porudžbina', body_text);
  RETURN NEW;
END;
$$;

-- Ažuriranje notify_order_status_change za multi-item
CREATE OR REPLACE FUNCTION public.notify_order_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  status_label TEXT;
  body_text TEXT;
  item_count INT;
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    status_label := CASE NEW.status
      WHEN 'accepted' THEN 'Prihvaćeno'
      WHEN 'rejected' THEN 'Odbijeno'
      WHEN 'delivered' THEN 'Isporučeno'
      ELSE NEW.status::text
    END;
    SELECT COUNT(*) INTO item_count FROM public.order_items WHERE order_id = NEW.id;
    IF item_count > 0 THEN
      body_text := item_count::text || ' proizvod(a) – ' || status_label;
    ELSE
      body_text := 'Proizvod: ' || COALESCE(NEW.product_name, '') || ' – ' || status_label;
    END IF;
    INSERT INTO public.notifications (user_id, order_id, type, title, body)
    VALUES (
      NEW.buyer_id,
      NEW.id,
      'order_status',
      CASE NEW.status
        WHEN 'accepted' THEN 'Prodavac je potvrdio porudžbinu'
        WHEN 'rejected' THEN 'Prodavac je odbio porudžbinu'
        WHEN 'delivered' THEN 'Porudžbina je isporučena'
        ELSE 'Porudžbina ažurirana'
      END,
      body_text
    );
  END IF;
  RETURN NEW;
END;
$$;
