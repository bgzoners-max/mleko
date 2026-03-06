-- RPC za transakciju: order + order_items u jednom atomicnom koraku
-- Sprečava siročad porudžbine ako order_items insert padne

-- Proširi unit_type da podrži g i kom (kao products)
ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS orders_unit_type_check;
ALTER TABLE public.orders ADD CONSTRAINT orders_unit_type_check
  CHECK (unit_type IN ('kg', 'L', 'g', 'kom'));

ALTER TABLE public.order_items DROP CONSTRAINT IF EXISTS order_items_unit_type_check;
ALTER TABLE public.order_items ADD CONSTRAINT order_items_unit_type_check
  CHECK (unit_type IN ('kg', 'L', 'g', 'kom'));

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
BEGIN
  IF auth.uid() IS DISTINCT FROM p_buyer_id THEN
    RAISE EXCEPTION 'Unauthorized: buyer_id must match authenticated user';
  END IF;
  IF p_buyer_phone IS NULL OR TRIM(p_buyer_phone) = '' THEN
    RAISE EXCEPTION 'buyer_phone is required';
  END IF;

  v_expires_at := NOW() + INTERVAL '365 days';

  INSERT INTO public.orders (
    buyer_id, seller_id, product_id, product_name, quantity_kg,
    total_amount, note, buyer_city, buyer_phone, buyer_address,
    status, archived_at, expires_at
  )
  VALUES (
    p_buyer_id, p_seller_id, NULL, NULL, NULL,
    (SELECT COALESCE(SUM((elem->>'total_price')::numeric), 0) FROM jsonb_array_elements(p_items) elem),
    NULLIF(TRIM(p_note), ''), NULLIF(TRIM(p_buyer_city), ''), p_buyer_phone, p_buyer_address,
    'sent', NULL, v_expires_at
  )
  RETURNING id INTO v_order_id;

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
  LOOP
    INSERT INTO public.order_items (
      order_id, product_id, product_name, quantity_kg, unit_type,
      unit_price, total_price
    )
    VALUES (
      v_order_id,
      (v_item->>'product_id')::UUID,
      v_item->>'product_name',
      (v_item->>'quantity_kg')::numeric,
      COALESCE(NULLIF(v_item->>'unit_type', ''), 'kg'),
      (v_item->>'unit_price')::numeric,
      (v_item->>'total_price')::numeric
    );
  END LOOP;

  RETURN v_order_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_order_with_items(UUID, UUID, TEXT, JSONB, TEXT, TEXT, TEXT) TO authenticated;
