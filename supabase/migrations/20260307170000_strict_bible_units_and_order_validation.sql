-- Strict Bible backend rules:
-- 1) Allowed units are kg, L, kom.
-- 2) Legacy g rows are normalized to kg.
-- 3) create_order_with_items enforces min quantity + system step on server side.

-- Normalize legacy unit values before tightening constraints.
UPDATE public.products SET unit_type = 'kg' WHERE unit_type = 'g';
UPDATE public.orders SET unit_type = 'kg' WHERE unit_type = 'g';
UPDATE public.order_items SET unit_type = 'kg' WHERE unit_type = 'g';

-- Tighten unit constraints.
ALTER TABLE public.products DROP CONSTRAINT IF EXISTS products_unit_type_check;
ALTER TABLE public.products
  ADD CONSTRAINT products_unit_type_check
  CHECK (unit_type IN ('kg', 'L', 'kom'));

ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS orders_unit_type_check;
ALTER TABLE public.orders
  ADD CONSTRAINT orders_unit_type_check
  CHECK (unit_type IN ('kg', 'L', 'kom'));

ALTER TABLE public.order_items DROP CONSTRAINT IF EXISTS order_items_unit_type_check;
ALTER TABLE public.order_items
  ADD CONSTRAINT order_items_unit_type_check
  CHECK (unit_type IN ('kg', 'L', 'kom'));

CREATE OR REPLACE FUNCTION public.create_order_with_items(
  p_buyer_id UUID,
  p_seller_id UUID,
  p_buyer_phone TEXT,
  p_items JSONB,
  p_note TEXT DEFAULT '',
  p_buyer_city TEXT DEFAULT '',
  p_buyer_address TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_order_id UUID;
  v_item JSONB;
  v_expires_at TIMESTAMPTZ;
  v_item_product_id UUID;
  v_item_quantity NUMERIC;
  v_item_unit_price NUMERIC;
  v_item_total_price NUMERIC;
  v_step NUMERIC;
  v_delta NUMERIC;
  v_total_amount NUMERIC := 0;
  v_product RECORD;
BEGIN
  IF auth.uid() IS DISTINCT FROM p_buyer_id THEN
    RAISE EXCEPTION 'Unauthorized: buyer_id must match authenticated user';
  END IF;

  IF p_buyer_phone IS NULL OR TRIM(p_buyer_phone) = '' THEN
    RAISE EXCEPTION 'buyer_phone is required';
  END IF;

  IF p_items IS NULL
     OR jsonb_typeof(p_items) <> 'array'
     OR jsonb_array_length(p_items) = 0 THEN
    RAISE EXCEPTION 'items are required';
  END IF;

  v_expires_at := NOW() + INTERVAL '365 days';

  INSERT INTO public.orders (
    buyer_id, seller_id, product_id, product_name, quantity_kg,
    total_amount, note, buyer_city, buyer_phone, buyer_address,
    status, archived_at, expires_at
  )
  VALUES (
    p_buyer_id, p_seller_id, NULL, NULL, NULL,
    0,
    NULLIF(TRIM(p_note), ''), NULLIF(TRIM(p_buyer_city), ''), p_buyer_phone, p_buyer_address,
    'sent', NULL, v_expires_at
  )
  RETURNING id INTO v_order_id;

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
  LOOP
    v_item_product_id := (v_item->>'product_id')::UUID;
    v_item_quantity := (v_item->>'quantity_kg')::NUMERIC;

    IF v_item_product_id IS NULL THEN
      RAISE EXCEPTION 'product_id is required for each item';
    END IF;

    IF v_item_quantity IS NULL OR v_item_quantity <= 0 THEN
      RAISE EXCEPTION 'quantity_kg must be > 0 for product %', v_item_product_id;
    END IF;

    SELECT
      p.id,
      p.seller_id,
      p.name,
      p.category,
      p.unit_type,
      p.min_order_kg,
      p.price_per_kg,
      p.available_now
    INTO v_product
    FROM public.products p
    WHERE p.id = v_item_product_id
      AND p.seller_id = p_seller_id;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'product % not found for seller %', v_item_product_id, p_seller_id;
    END IF;

    IF v_product.available_now IS NOT TRUE THEN
      RAISE EXCEPTION 'product % is currently unavailable', v_product.name;
    END IF;

    IF v_product.unit_type NOT IN ('kg', 'L', 'kom') THEN
      RAISE EXCEPTION 'invalid unit for product %', v_product.name;
    END IF;

    IF (lower(coalesce(v_product.name, '') || ' ' || coalesce(v_product.category, '')) LIKE '%med%'
        OR lower(coalesce(v_product.name, '') || ' ' || coalesce(v_product.category, '')) LIKE '%honey%')
       AND v_product.unit_type <> 'kg' THEN
      RAISE EXCEPTION 'honey products must use kg unit';
    END IF;

    IF v_item_quantity < v_product.min_order_kg THEN
      RAISE EXCEPTION 'quantity for % is below min_order_kg', v_product.name;
    END IF;

    v_step := CASE
      WHEN v_product.unit_type = 'kom' THEN 10::NUMERIC
      WHEN v_product.unit_type = 'L' THEN 1::NUMERIC
      WHEN lower(coalesce(v_product.category, '')) LIKE '%suhomesnat%' THEN 0.1::NUMERIC
      ELSE 0.5::NUMERIC
    END;

    v_delta := v_item_quantity - v_product.min_order_kg;

    IF abs(v_delta - (ROUND(v_delta / v_step) * v_step)) > 0.000001 THEN
      RAISE EXCEPTION 'quantity for % must align with system step %', v_product.name, v_step;
    END IF;

    v_item_unit_price := v_product.price_per_kg;
    v_item_total_price := v_item_quantity * v_item_unit_price;

    INSERT INTO public.order_items (
      order_id, product_id, product_name, quantity_kg, unit_type,
      unit_price, total_price
    )
    VALUES (
      v_order_id,
      v_item_product_id,
      v_product.name,
      v_item_quantity,
      v_product.unit_type,
      v_item_unit_price,
      v_item_total_price
    );

    v_total_amount := v_total_amount + v_item_total_price;
  END LOOP;

  UPDATE public.orders
  SET total_amount = v_total_amount
  WHERE id = v_order_id;

  RETURN v_order_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_order_with_items(UUID, UUID, TEXT, JSONB, TEXT, TEXT, TEXT) TO authenticated;
