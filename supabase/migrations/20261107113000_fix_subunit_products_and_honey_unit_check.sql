-- ============================================================================
-- Migracija: 20261107113000_fix_subunit_products_and_honey_unit_check.sql
-- Naziv: Ispravka oglasa sa teglicama/flasicama (ml/g) i uklanjanje ogranicenja
--        da med mora biti iskljucivo u kg u create_order_with_items
-- ============================================================================

-- 1. Azuriraj create_order_with_items:
--    - Ukloni zastarelo ogranicenje "honey products must use kg unit" (med se prodaje i u teglicama u ml/kom/pak)
--    - Zaokruzi v_item_total_price na 2 decimale (kako cene za podjedinice poput 330ml ne bi imale 399.9999)
CREATE OR REPLACE FUNCTION public.create_order_with_items(
  p_buyer_id UUID,
  p_seller_id UUID,
  p_buyer_phone TEXT,
  p_items JSONB,
  p_note TEXT DEFAULT '',
  p_buyer_city TEXT DEFAULT '',
  p_buyer_address TEXT DEFAULT NULL,
  p_buyer_postal_code TEXT DEFAULT NULL,
  p_delivery_method TEXT DEFAULT 'courier',
  p_delivery_point_id UUID DEFAULT NULL,
  p_delivery_slot_id UUID DEFAULT NULL,
  p_delivery_fee_rsd NUMERIC DEFAULT NULL
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
  v_item_product_name TEXT;
  v_variant_id TEXT;
  v_variant_label TEXT;
  v_matched_variant JSONB;
  v_step NUMERIC;
  v_delta NUMERIC;
  v_total_amount NUMERIC := 0;
  v_product RECORD;
  v_delivery_method TEXT := COALESCE(NULLIF(TRIM(p_delivery_method), ''), 'courier');
  v_delivery_point public.seller_delivery_points%ROWTYPE;
  v_delivery_slot public.seller_delivery_slots%ROWTYPE;
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

  IF v_delivery_method NOT IN ('agreement', 'pickup', 'courier', 'seller_delivery') THEN
    RAISE EXCEPTION 'invalid delivery_method';
  END IF;

  IF v_delivery_method = 'seller_delivery' THEN
    IF p_delivery_point_id IS NULL OR p_delivery_slot_id IS NULL THEN
      RAISE EXCEPTION 'delivery point and slot are required for seller_delivery';
    END IF;

    SELECT *
    INTO v_delivery_point
    FROM public.seller_delivery_points
    WHERE id = p_delivery_point_id
      AND seller_id = p_seller_id
      AND is_active = true;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'delivery point not found or inactive';
    END IF;

    SELECT *
    INTO v_delivery_slot
    FROM public.seller_delivery_slots
    WHERE id = p_delivery_slot_id
      AND delivery_point_id = p_delivery_point_id
      AND is_active = true;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'delivery slot not found or inactive';
    END IF;
  END IF;

  v_expires_at := NOW() + INTERVAL '365 days';

  INSERT INTO public.orders (
    buyer_id,
    seller_id,
    product_id,
    product_name,
    quantity_kg,
    total_amount,
    note,
    buyer_city,
    buyer_phone,
    buyer_address,
    buyer_postal_code,
    delivery_method,
    delivery_city,
    delivery_point_id,
    delivery_point_label,
    delivery_address,
    delivery_weekday,
    delivery_time_from,
    delivery_time_to,
    delivery_fee_rsd,
    status,
    archived_at,
    expires_at
  )
  VALUES (
    p_buyer_id,
    p_seller_id,
    NULL,
    NULL,
    NULL,
    0,
    NULLIF(TRIM(p_note), ''),
    NULLIF(TRIM(p_buyer_city), ''),
    p_buyer_phone,
    NULLIF(TRIM(p_buyer_address), ''),
    NULLIF(TRIM(p_buyer_postal_code), ''),
    v_delivery_method,
    CASE WHEN v_delivery_method = 'seller_delivery' THEN v_delivery_point.city ELSE NULL END,
    CASE WHEN v_delivery_method = 'seller_delivery' THEN v_delivery_point.id ELSE NULL END,
    CASE WHEN v_delivery_method = 'seller_delivery' THEN v_delivery_point.label ELSE NULL END,
    CASE WHEN v_delivery_method = 'seller_delivery' THEN v_delivery_point.address ELSE NULL END,
    CASE WHEN v_delivery_method = 'seller_delivery' THEN v_delivery_slot.weekday ELSE NULL END,
    CASE WHEN v_delivery_method = 'seller_delivery' THEN v_delivery_slot.time_from ELSE NULL END,
    CASE WHEN v_delivery_method = 'seller_delivery' THEN v_delivery_slot.time_to ELSE NULL END,
    CASE WHEN v_delivery_method = 'seller_delivery' THEN COALESCE(p_delivery_fee_rsd, v_delivery_slot.delivery_fee_rsd) ELSE NULL END,
    'sent',
    NULL,
    v_expires_at
  )
  RETURNING id INTO v_order_id;

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
  LOOP
    v_item_product_id := (v_item->>'product_id')::UUID;
    v_item_quantity := (v_item->>'quantity_kg')::NUMERIC;
    v_variant_id := NULLIF(TRIM(v_item->>'variant_id'), '');
    v_variant_label := NULLIF(TRIM(v_item->>'variant_label'), '');
    v_matched_variant := NULL;

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
      p.order_step,
      p.price_per_kg,
      p.available_now,
      p.delivery_mode,
      p.variants
    INTO v_product
    FROM public.products p
    WHERE p.id = v_item_product_id
      AND p.seller_id = p_seller_id;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'product % not found for seller %', v_item_product_id, p_seller_id;
    END IF;

    IF v_delivery_method = 'seller_delivery' THEN
      IF COALESCE(v_product.delivery_mode, 'none') = 'none' THEN
        RAISE EXCEPTION 'product % does not support seller delivery', v_product.name;
      END IF;

      IF v_product.delivery_mode = 'selected_points'
         AND NOT EXISTS (
           SELECT 1
           FROM public.product_delivery_points pdp
           WHERE pdp.product_id = v_item_product_id
             AND pdp.delivery_point_id = p_delivery_point_id
         ) THEN
        RAISE EXCEPTION 'delivery point is not allowed for product %', v_product.name;
      END IF;
    END IF;

    IF v_product.available_now IS NOT TRUE THEN
      RAISE EXCEPTION 'product % is currently unavailable', v_product.name;
    END IF;

    IF v_product.unit_type NOT IN ('kg', 'L', 'kom', 'veza', 'pak') THEN
      RAISE EXCEPTION 'invalid unit for product %', v_product.name;
    END IF;

    IF v_item_quantity < v_product.min_order_kg THEN
      RAISE EXCEPTION 'quantity for % is below min_order_kg', v_product.name;
    END IF;

    v_step := v_product.order_step::NUMERIC;

    v_delta := v_item_quantity - v_product.min_order_kg;

    IF abs(v_delta - (ROUND(v_delta / v_step) * v_step)) > 0.000001 THEN
      RAISE EXCEPTION 'quantity for % must align with order step %', v_product.name, v_step;
    END IF;

    -- Cena se striktno uzima iz baze (osnovna cena ili cena izabrane varijante)
    v_item_unit_price := v_product.price_per_kg;
    v_item_product_name := v_product.name;

    IF v_variant_id IS NOT NULL OR v_variant_label IS NOT NULL THEN
      SELECT elem
      INTO v_matched_variant
      FROM jsonb_array_elements(COALESCE(v_product.variants, '[]'::jsonb)) elem
      WHERE (v_variant_id IS NOT NULL AND elem->>'id' = v_variant_id)
         OR (v_variant_id IS NULL AND v_variant_label IS NOT NULL AND lower(elem->>'label') = lower(v_variant_label))
      LIMIT 1;

      IF v_matched_variant IS NULL THEN
        RAISE EXCEPTION 'variant not found for product %', v_product.name;
      END IF;

      v_item_unit_price := (v_matched_variant->>'price')::NUMERIC;
      IF v_item_unit_price IS NULL OR v_item_unit_price <= 0 THEN
        RAISE EXCEPTION 'invalid variant price for product %', v_product.name;
      END IF;

      v_item_product_name := v_product.name || ' (' || (v_matched_variant->>'label') || ')';
    END IF;

    v_item_total_price := ROUND(v_item_quantity * v_item_unit_price, 2);

    INSERT INTO public.order_items (
      order_id, product_id, product_name, quantity_kg, unit_type,
      unit_price, total_price
    )
    VALUES (
      v_order_id,
      v_item_product_id,
      v_item_product_name,
      v_item_quantity,
      v_product.unit_type,
      v_item_unit_price,
      v_item_total_price
    );

    v_total_amount := v_total_amount + v_item_total_price;
  END LOOP;

  UPDATE public.orders
  SET total_amount = ROUND(v_total_amount, 2)
  WHERE id = v_order_id;

  RETURN v_order_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_order_with_items(
  UUID, UUID, TEXT, JSONB, TEXT, TEXT, TEXT, TEXT, TEXT, UUID, UUID, NUMERIC
) TO authenticated;

-- 2. Ispravi oglase gde je u opisu navedena mililitraza/gramaza teglice ili flasice,
--    a postavljeno je 1 L ili kom bez tacne mere:

-- 2a. Gazdinstvo "Slatko I Pomalo Uvrnuto" (767f238b-1b24-4d57-a92e-b262f6b5c0e5)
-- "Džem od kajsija" (Teglica 330ml, 400 RSD - bilo postavljeno 1 L)
UPDATE public.products
SET
  unit_type = 'L',
  min_order_kg = 0.33,
  order_step = 0.33,
  price_per_kg = ROUND(400.0 / 0.33, 6)
WHERE id = '5c475847-aa30-4584-9776-381c43422c50';

-- "Slatko od smokava sa čili papričicama" (Teglica 330ml, 500 RSD - bilo postavljeno 1 L)
UPDATE public.products
SET
  unit_type = 'L',
  min_order_kg = 0.33,
  order_step = 0.33,
  price_per_kg = ROUND(500.0 / 0.33, 6)
WHERE id = '42e0f1ec-b5ca-4413-8c34-5ab2e248f418';

-- "Med sa orašastim plodovima" (Teglica 105ml, 400 RSD - bilo postavljeno 1 kom)
UPDATE public.products
SET
  unit_type = 'L',
  min_order_kg = 0.105,
  order_step = 0.105,
  price_per_kg = ROUND(400.0 / 0.105, 6)
WHERE id = '1c7a0cf6-b057-4bb8-b2b2-448b9fab46f5';

-- "Prirodni macerati - biljna ulja" (Bočice po 100ml: sve 400 RSD, Kantarion 500 RSD)
UPDATE public.products
SET
  variants = '[
    {"id": "lavanda-100ml", "label": "Lavanda (100 ml)", "price": 400},
    {"id": "hajducka-trava-100ml", "label": "Hajdučka trava (100 ml)", "price": 400},
    {"id": "menta-100ml", "label": "Menta (100 ml)", "price": 400},
    {"id": "smilje-100ml", "label": "Smilje (100 ml)", "price": 400},
    {"id": "zalfija-100ml", "label": "Žalfija (100 ml)", "price": 400},
    {"id": "ruzmarin-100ml", "label": "Ruzmarin (100 ml)", "price": 400},
    {"id": "kantarion-100ml", "label": "Kantarion (100 ml)", "price": 500}
  ]'::jsonb
WHERE id = '91452b70-2b93-4d91-b4ab-b64248e5c481'
  AND (variants IS NULL OR variants = '[]'::jsonb);

-- "Dehidrirano voće" (Pakovanja po 60g, banana 100g - 400 RSD)
UPDATE public.products
SET
  variants = '[
    {"id": "narandza-60g", "label": "Narandža (60 g)", "price": 400},
    {"id": "limun-60g", "label": "Limun (60 g)", "price": 400},
    {"id": "jabuka-60g", "label": "Jabuka (60 g)", "price": 400},
    {"id": "banana-100g", "label": "Banana (100 g)", "price": 400}
  ]'::jsonb
WHERE id = 'c46e4142-cbda-43bc-88f8-04ca46abf9b2'
  AND (variants IS NULL OR variants = '[]'::jsonb);

-- 2b. Jasmina Djordjevic (4ab96545-8734-4ab9-a764-39da8276df90) - tegle 720ml i 900ml
-- "Kompot od breskve" (720ml, 500 RSD)
UPDATE public.products
SET
  unit_type = 'L',
  min_order_kg = 0.72,
  order_step = 0.72,
  price_per_kg = ROUND(500.0 / 0.72, 6)
WHERE id = '610abed6-c883-4577-ba6a-82980895d1cb';

-- "Ajvar od pečene paprike" (720ml, 1000 RSD)
UPDATE public.products
SET
  unit_type = 'L',
  min_order_kg = 0.72,
  order_step = 0.72,
  price_per_kg = ROUND(1000.0 / 0.72, 6)
WHERE id = 'f704800f-9c3b-470e-98c0-0a50e7aa99fb';

-- "Paprika sa sirom i pavlakom" (900ml, 900 RSD)
UPDATE public.products
SET
  unit_type = 'L',
  min_order_kg = 0.90,
  order_step = 0.90,
  price_per_kg = ROUND(900.0 / 0.90, 6)
WHERE id = 'dbdceca0-c448-4aca-88af-098d1b43ed3f';

-- "Ljutenica" (720ml, 800 RSD)
UPDATE public.products
SET
  unit_type = 'L',
  min_order_kg = 0.72,
  order_step = 0.72,
  price_per_kg = ROUND(800.0 / 0.72, 6)
WHERE id = '2086f505-daa9-4a87-a184-add893233bd3';

-- "Džem od Kajsija" (720ml, 700 RSD)
UPDATE public.products
SET
  unit_type = 'L',
  min_order_kg = 0.72,
  order_step = 0.72,
  price_per_kg = ROUND(700.0 / 0.72, 6)
WHERE id = 'ab9b41b1-3115-4704-84c7-5de4dc4ec85b';

-- 2c. Stefan (93db4a74-40be-45aa-b0d9-f3cb5a886ce2) - tegla 800ml
-- "Kompot od sumske borovnice" (800ml, 500 RSD)
UPDATE public.products
SET
  unit_type = 'L',
  min_order_kg = 0.80,
  order_step = 0.80,
  price_per_kg = ROUND(500.0 / 0.80, 6)
WHERE id = '68aa3952-5a5d-4955-b9d7-0cd3425b2401';

-- 2d. Dragana Zivkovic / "Šumski darovi Zabrege" (eacaa79d-47f7-4a34-b7de-3391aeb62c2d) - 100g i 30g
-- "Zabreški začin za piletinu 100gr" (100g, 500 RSD)
UPDATE public.products
SET
  unit_type = 'kg',
  min_order_kg = 0.10,
  order_step = 0.10,
  price_per_kg = ROUND(500.0 / 0.10, 6)
WHERE id = '84e22943-222c-48ad-bc36-bd7bcdff6a15';

-- "Zabreški biljni detoks čaj 30gr" (30g, 300 RSD)
UPDATE public.products
SET
  unit_type = 'kg',
  min_order_kg = 0.03,
  order_step = 0.03,
  price_per_kg = ROUND(300.0 / 0.03, 6)
WHERE id = '6e18ebfc-f905-4dad-a028-1ea5af89b18b';

-- "Zabreški začin za krompir 100gr" (100g, 500 RSD)
UPDATE public.products
SET
  unit_type = 'kg',
  min_order_kg = 0.10,
  order_step = 0.10,
  price_per_kg = ROUND(500.0 / 0.10, 6)
WHERE id = 'eb1f87ad-5c3c-4ce9-8926-614be0a6d378';

