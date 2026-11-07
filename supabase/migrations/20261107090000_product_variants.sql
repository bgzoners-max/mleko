-- ============================================================================
-- Migracija: 20261107090000_product_variants.sql
-- Naziv: Podrska za vise velicina / pakovanja (variants) po proizvodu
-- ============================================================================

-- 1. Dodaj JSONB kolonu variants na public.products
ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS variants JSONB NOT NULL DEFAULT '[]'::jsonb;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'products_variants_is_array_chk'
  ) THEN
    ALTER TABLE public.products
      ADD CONSTRAINT products_variants_is_array_chk
      CHECK (jsonb_typeof(variants) = 'array');
  END IF;
END $$;

-- 2. Azuriraj view public.products_with_ratings (nova kolona na kraju SELECT liste)
CREATE OR REPLACE VIEW public.products_with_ratings
WITH (security_invoker = on)
AS
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
  COALESCE(r.avg_rating, 0)::numeric   AS avg_rating,
  COALESCE(r.review_count, 0)::bigint  AS review_count,
  COALESCE(o.order_count, 0)::bigint   AS order_count,
  COALESCE(prof.is_verified, false)    AS seller_is_verified,
  p.variants
FROM public.products p
LEFT JOIN public.product_review_summary r ON r.product_id = p.id
LEFT JOIN public.product_order_summary o ON o.product_id = p.id
LEFT JOIN public.public_profiles prof ON prof.id = p.seller_id;

GRANT SELECT ON public.products_with_ratings TO anon, authenticated;

-- 3. Azuriraj search_products_fts (RETURNS SETOF public.products_with_ratings)
CREATE OR REPLACE FUNCTION public.search_products_fts(
  p_query             text,
  p_category          text    DEFAULT NULL,
  p_region            text    DEFAULT NULL,
  p_available_now     boolean DEFAULT NULL,
  p_exclude_seller_id uuid    DEFAULT NULL,
  p_limit             int     DEFAULT 20,
  p_offset            int     DEFAULT 0
)
RETURNS SETOF public.products_with_ratings
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, extensions
AS $$
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
    COALESCE(r.avg_rating, 0)::numeric   AS avg_rating,
    COALESCE(r.review_count, 0)::bigint  AS review_count,
    COALESCE(o.order_count, 0)::bigint   AS order_count,
    COALESCE(prof.is_verified, false)    AS seller_is_verified,
    p.variants
  FROM public.products p
  LEFT JOIN public.product_review_summary r ON r.product_id = p.id
  LEFT JOIN public.product_order_summary o ON o.product_id = p.id
  LEFT JOIN public.public_profiles prof ON prof.id = p.seller_id
  WHERE
    (
      p.search_vector @@ websearch_to_tsquery('simple', public.normalize_search_text(p_query))
      OR p.search_vector @@ websearch_to_tsquery('simple', public.immutable_unaccent(p_query))
      OR public.immutable_unaccent(lower(p.name)) ILIKE ('%' || public.immutable_unaccent(lower(p_query)) || '%')
      OR word_similarity(public.immutable_unaccent(lower(p_query)), public.immutable_unaccent(lower(p.name))) >= 0.35
      OR similarity(public.immutable_unaccent(lower(p.name)), public.immutable_unaccent(lower(p_query))) >= 0.3
    ) AND
    (p_category          IS NULL OR p.category     = p_category)             AND
    (p_region            IS NULL OR p.location     = p_region)               AND
    (p_available_now     IS NULL OR p.available_now = p_available_now)       AND
    (p_exclude_seller_id IS NULL OR p.seller_id   <> p_exclude_seller_id)
  ORDER BY
    ts_rank(p.search_vector, websearch_to_tsquery('simple', public.normalize_search_text(p_query))) DESC,
    word_similarity(public.immutable_unaccent(lower(p_query)), public.immutable_unaccent(lower(p.name))) DESC,
    similarity(public.immutable_unaccent(lower(p.name)), public.immutable_unaccent(lower(p_query))) DESC,
    p.created_at DESC
  LIMIT  p_limit
  OFFSET p_offset;
$$;

GRANT EXECUTE ON FUNCTION public.search_products_fts TO anon, authenticated;

-- 4. Osvezi funkcije koje vracaju SETOF public.products_with_ratings
CREATE OR REPLACE FUNCTION public.get_related_seller_products(
  p_seller_id uuid,
  p_exclude_product_id uuid,
  p_limit int DEFAULT 6
)
RETURNS SETOF public.products_with_ratings
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT pwr.*
  FROM public.products_with_ratings pwr
  WHERE pwr.seller_id = p_seller_id
    AND pwr.id <> p_exclude_product_id
    AND pwr.available_now = true
    AND pwr.available_kg > 0
  ORDER BY pwr.created_at DESC
  LIMIT GREATEST(1, LEAST(p_limit, 20));
$$;

GRANT EXECUTE ON FUNCTION public.get_related_seller_products(uuid, uuid, int) TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.get_products_from_favorite_sellers(p_user_id uuid)
RETURNS SETOF public.products_with_ratings
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT pwr.*
  FROM public.products_with_ratings pwr
  JOIN public.favorite_sellers fs ON fs.seller_id = pwr.seller_id
  WHERE fs.user_id = p_user_id
    AND (p_user_id = auth.uid() OR public.is_admin())
  ORDER BY pwr.created_at DESC;
$$;

GRANT EXECUTE ON FUNCTION public.get_products_from_favorite_sellers(uuid) TO authenticated;

-- 5. Azuriraj get_home_products da vraca i variants
DROP FUNCTION IF EXISTS public.get_home_products(int, text, text);

CREATE OR REPLACE FUNCTION public.get_home_products(
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
  seller_is_verified boolean,
  order_count bigint,
  avg_rating numeric,
  review_count bigint,
  variants jsonb
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
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
    COALESCE(prof.is_verified, false)   AS seller_is_verified,
    COALESCE(o.order_count, 0)::bigint  AS order_count,
    COALESCE(r.avg_rating, 0)::numeric  AS avg_rating,
    COALESCE(r.review_count, 0)::bigint AS review_count,
    p.variants
  FROM public.products p
  LEFT JOIN public.product_order_summary o ON o.product_id = p.id
  LEFT JOIN public.product_review_summary r ON r.product_id = p.id
  LEFT JOIN public.profiles prof ON prof.id = p.seller_id
  WHERE (p_region IS NULL OR p_region = '' OR p.location = p_region)
    AND (p_category IS NULL OR p_category = '' OR p.category = p_category)
  ORDER BY
    (COALESCE(array_length(p.image_urls, 1), 0) > 0) DESC,
    (p.created_at >= NOW() - INTERVAL '14 days') DESC,
    COALESCE(r.avg_rating, 0) DESC,
    COALESCE(o.order_count, 0) DESC,
    p.created_at DESC
  LIMIT GREATEST(1, LEAST(p_limit, 100));
$$;

GRANT EXECUTE ON FUNCTION public.get_home_products(INTEGER, TEXT, TEXT) TO anon, authenticated;

-- 6. Azuriraj create_order_with_items tako da prepoznaje opcioni variant_id / variant_label u p_items
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

    IF (lower(coalesce(v_product.name, '') || ' ' || coalesce(v_product.category, '')) LIKE '%med%'
        OR lower(coalesce(v_product.name, '') || ' ' || coalesce(v_product.category, '')) LIKE '%honey%')
       AND v_product.unit_type <> 'kg' THEN
      RAISE EXCEPTION 'honey products must use kg unit';
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

    v_item_total_price := v_item_quantity * v_item_unit_price;

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
  SET total_amount = v_total_amount
  WHERE id = v_order_id;

  RETURN v_order_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_order_with_items(
  UUID, UUID, TEXT, JSONB, TEXT, TEXT, TEXT, TEXT, TEXT, UUID, UUID, NUMERIC
) TO authenticated;

-- 7. Podesi pakovanja za postojeći oglas "Sirup od Trnjina" (250ml = 250 RSD, 750ml = 600 RSD)
UPDATE public.products
SET variants = '[
  {"id": "250ml", "label": "Flašica 250 ml", "price": 250},
  {"id": "750ml", "label": "Flaša 750 ml", "price": 600}
]'::jsonb
WHERE lower(name) = 'sirup od trnjina'
  AND (variants IS NULL OR variants = '[]'::jsonb);

