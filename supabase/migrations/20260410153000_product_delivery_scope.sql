-- Product-level seller delivery scope.
-- Existing products keep current behavior (all seller points),
-- while new products default to no seller-delivery until explicitly enabled.

ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS delivery_mode TEXT;

UPDATE public.products
SET delivery_mode = 'all_seller_points'
WHERE delivery_mode IS NULL OR btrim(delivery_mode) = '';

ALTER TABLE public.products
  ALTER COLUMN delivery_mode SET DEFAULT 'none';

ALTER TABLE public.products
  ALTER COLUMN delivery_mode SET NOT NULL;

ALTER TABLE public.products
  DROP CONSTRAINT IF EXISTS products_delivery_mode_check;

ALTER TABLE public.products
  ADD CONSTRAINT products_delivery_mode_check
  CHECK (delivery_mode IN ('none', 'all_seller_points', 'selected_points'));

CREATE TABLE IF NOT EXISTS public.product_delivery_points (
  product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  delivery_point_id UUID NOT NULL REFERENCES public.seller_delivery_points(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (product_id, delivery_point_id)
);

CREATE INDEX IF NOT EXISTS idx_product_delivery_points_product
  ON public.product_delivery_points (product_id);

CREATE INDEX IF NOT EXISTS idx_product_delivery_points_point
  ON public.product_delivery_points (delivery_point_id);

CREATE OR REPLACE FUNCTION public.validate_product_delivery_point_same_seller()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_product_seller_id UUID;
  v_point_seller_id UUID;
BEGIN
  SELECT seller_id INTO v_product_seller_id
  FROM public.products
  WHERE id = NEW.product_id;

  SELECT seller_id INTO v_point_seller_id
  FROM public.seller_delivery_points
  WHERE id = NEW.delivery_point_id;

  IF v_product_seller_id IS NULL OR v_point_seller_id IS NULL THEN
    RAISE EXCEPTION 'Product or delivery point not found';
  END IF;

  IF v_product_seller_id IS DISTINCT FROM v_point_seller_id THEN
    RAISE EXCEPTION 'Product and delivery point must belong to the same seller';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_product_delivery_points_same_seller
  ON public.product_delivery_points;

CREATE TRIGGER trg_product_delivery_points_same_seller
BEFORE INSERT OR UPDATE ON public.product_delivery_points
FOR EACH ROW
EXECUTE FUNCTION public.validate_product_delivery_point_same_seller();

ALTER TABLE public.product_delivery_points ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public can view product delivery points" ON public.product_delivery_points;
CREATE POLICY "Public can view product delivery points"
ON public.product_delivery_points
FOR SELECT
TO public
USING (
  EXISTS (
    SELECT 1
    FROM public.seller_delivery_points p
    WHERE p.id = delivery_point_id
      AND p.is_active = true
  )
);

DROP POLICY IF EXISTS "Sellers manage own product delivery points" ON public.product_delivery_points;
CREATE POLICY "Sellers manage own product delivery points"
ON public.product_delivery_points
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.products pr
    JOIN public.seller_delivery_points dp
      ON dp.id = product_delivery_points.delivery_point_id
    WHERE pr.id = product_delivery_points.product_id
      AND pr.seller_id = auth.uid()
      AND dp.seller_id = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.products pr
    JOIN public.seller_delivery_points dp
      ON dp.id = product_delivery_points.delivery_point_id
    WHERE pr.id = product_delivery_points.product_id
      AND pr.seller_id = auth.uid()
      AND dp.seller_id = auth.uid()
  )
);

DROP VIEW IF EXISTS public.products_with_ratings;

CREATE VIEW public.products_with_ratings AS
SELECT
  p.id,
  p.seller_id,
  p.category,
  p.name,
  p.price_per_kg,
  p.min_order_kg,
  p.order_step,
  p.available_kg,
  p.unit_type,
  p.description,
  p.image_urls,
  p.pickup_options,
  p.location,
  p.is_domestic,
  p.available_now,
  p.delivery_mode,
  p.created_at,
  COALESCE(r.avg_rating, 0)::numeric AS avg_rating,
  COALESCE(r.review_count, 0)::bigint AS review_count,
  COALESCE(s.order_count, 0)::bigint AS order_count
FROM public.products p
LEFT JOIN (
  SELECT product_id, AVG(rating)::numeric AS avg_rating, COUNT(*)::bigint AS review_count
  FROM public.reviews
  WHERE product_id IS NOT NULL
  GROUP BY product_id
) r ON p.id = r.product_id
LEFT JOIN (
  SELECT product_id, COUNT(*)::bigint AS order_count
  FROM public.orders
  WHERE status IN ('accepted', 'delivered')
  GROUP BY product_id
) s ON p.id = s.product_id;

GRANT SELECT ON public.products_with_ratings TO anon;
GRANT SELECT ON public.products_with_ratings TO authenticated;

DROP FUNCTION IF EXISTS public.get_home_products(int, text, text);

CREATE FUNCTION public.get_home_products(
  p_limit int DEFAULT 50,
  p_region text DEFAULT NULL,
  p_category text DEFAULT NULL
)
RETURNS TABLE (
  id uuid,
  seller_id uuid,
  category text,
  name text,
  price_per_kg numeric,
  min_order_kg numeric,
  order_step numeric,
  available_kg numeric,
  unit_type text,
  description text,
  image_urls text[],
  pickup_options text[],
  location text,
  is_domestic boolean,
  available_now boolean,
  delivery_mode text,
  created_at timestamptz,
  order_count bigint
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  WITH sales AS (
    SELECT product_id, COUNT(*)::bigint AS cnt
    FROM orders
    WHERE status IN ('accepted', 'delivered')
    GROUP BY product_id
  )
  SELECT
    p.id, p.seller_id, p.category, p.name, p.price_per_kg, p.min_order_kg,
    p.order_step, p.available_kg, p.unit_type, p.description, p.image_urls,
    p.pickup_options, p.location, p.is_domestic, p.available_now,
    p.delivery_mode, p.created_at,
    COALESCE(s.cnt, 0)::bigint AS order_count
  FROM products p
  LEFT JOIN sales s ON s.product_id = p.id
  WHERE (p_region IS NULL OR p_region = '' OR p.location = p_region)
    AND (p_category IS NULL OR p_category = '' OR p.category = p_category)
  ORDER BY
    (p.created_at >= NOW() - INTERVAL '14 days') DESC,
    COALESCE(s.cnt, 0) DESC,
    p.created_at DESC
  LIMIT GREATEST(1, LEAST(p_limit, 100));
$$;

DROP FUNCTION IF EXISTS public.create_order_with_items(UUID, UUID, TEXT, JSONB, TEXT, TEXT, TEXT, TEXT, UUID, UUID, NUMERIC);

CREATE FUNCTION public.create_order_with_items(
  p_buyer_id UUID,
  p_seller_id UUID,
  p_buyer_phone TEXT,
  p_items JSONB,
  p_note TEXT DEFAULT '',
  p_buyer_city TEXT DEFAULT '',
  p_buyer_address TEXT DEFAULT NULL,
  p_delivery_method TEXT DEFAULT 'agreement',
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
  v_step NUMERIC;
  v_delta NUMERIC;
  v_total_amount NUMERIC := 0;
  v_product RECORD;
  v_delivery_method TEXT := COALESCE(NULLIF(TRIM(p_delivery_method), ''), 'agreement');
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

  IF v_delivery_method NOT IN ('agreement', 'seller_delivery') THEN
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
      p.delivery_mode
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
      WHEN v_product.order_step IS NOT NULL AND v_product.order_step > 0
        THEN v_product.order_step::NUMERIC
      WHEN v_product.unit_type = 'kom' THEN 10::NUMERIC
      WHEN v_product.unit_type = 'L' THEN 1::NUMERIC
      WHEN lower(coalesce(v_product.category, '')) LIKE '%suhomesnat%' THEN 0.1::NUMERIC
      ELSE 0.5::NUMERIC
    END;

    v_delta := v_item_quantity - v_product.min_order_kg;

    IF abs(v_delta - (ROUND(v_delta / v_step) * v_step)) > 0.000001 THEN
      RAISE EXCEPTION 'quantity for % must align with order step %', v_product.name, v_step;
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

  IF v_delivery_method = 'seller_delivery'
     AND v_delivery_slot.min_order_amount_rsd IS NOT NULL
     AND v_total_amount < v_delivery_slot.min_order_amount_rsd THEN
    RAISE EXCEPTION 'order total is below delivery slot minimum amount';
  END IF;

  UPDATE public.orders
  SET total_amount = v_total_amount
  WHERE id = v_order_id;

  RETURN v_order_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_order_with_items(UUID, UUID, TEXT, JSONB, TEXT, TEXT, TEXT, TEXT, UUID, UUID, NUMERIC) TO authenticated;
