-- Refine multi-item new order notification wording and include total amount.
-- Example: "2 proizvoda, prva stavka: Domaće mleko 3 L. Ukupno: 1250 RSD"

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
  v_total_amount NUMERIC;
  v_total_text TEXT;
BEGIN
  SELECT COUNT(*) INTO v_item_count
  FROM public.order_items
  WHERE order_id = p_order_id;

  SELECT o.total_amount
  INTO v_total_amount
  FROM public.orders o
  WHERE o.id = p_order_id;

  IF v_total_amount IS NULL THEN
    SELECT COALESCE(SUM(oi.total_price), 0)
    INTO v_total_amount
    FROM public.order_items oi
    WHERE oi.order_id = p_order_id;
  END IF;

  IF v_item_count >= 1 THEN
    SELECT product_name, quantity_kg, unit_type
    INTO v_product_name, v_quantity, v_unit_type
    FROM public.order_items
    WHERE order_id = p_order_id
    ORDER BY product_name ASC, product_id ASC
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

  v_total_text := CASE
    WHEN v_total_amount IS NULL OR v_total_amount <= 0 THEN NULL
    WHEN trunc(v_total_amount) = v_total_amount THEN trunc(v_total_amount)::text
    ELSE trim(trailing '.' from trim(trailing '0' from v_total_amount::text))
  END;

  IF v_item_count > 1 THEN
    IF v_quantity_text IS NULL OR v_quantity_text = '' THEN
      IF v_total_text IS NULL THEN
        RETURN v_item_count::text || ' proizvoda, prva stavka: ' || v_product_name;
      END IF;
      RETURN v_item_count::text || ' proizvoda, prva stavka: ' || v_product_name || '. Ukupno: ' || v_total_text || ' RSD';
    END IF;

    IF v_total_text IS NULL THEN
      RETURN v_item_count::text || ' proizvoda, prva stavka: ' || v_product_name || ' – ' || v_quantity_text || ' ' || COALESCE(NULLIF(v_unit_type, ''), 'kg');
    END IF;

    RETURN v_item_count::text || ' proizvoda, prva stavka: ' || v_product_name || ' – ' || v_quantity_text || ' ' || COALESCE(NULLIF(v_unit_type, ''), 'kg') || '. Ukupno: ' || v_total_text || ' RSD';
  END IF;

  IF v_quantity_text IS NULL OR v_quantity_text = '' THEN
    RETURN 'Proizvod: ' || v_product_name;
  END IF;

  RETURN 'Proizvod: ' || v_product_name || ' – ' || v_quantity_text || ' ' || COALESCE(NULLIF(v_unit_type, ''), 'kg');
END;
$$;

UPDATE public.notifications n
SET body = public.build_order_notification_body(
  n.order_id,
  o.product_name,
  o.quantity_kg,
  o.unit_type
)
FROM public.orders o
WHERE n.order_id = o.id
  AND n.type = 'new_order';
