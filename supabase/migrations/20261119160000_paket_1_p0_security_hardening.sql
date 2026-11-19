-- ============================================================================
-- Paket 1: P0/P1 Bezbednosno očvršćavanje baze (RLS, RPC IDOR, recenzije, zalihe/agregati)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Zabrana direktnog PostgREST INSERT-a na public.orders i public.order_items
--    Porudžbine se kreiraju isključivo kroz SECURITY DEFINER RPC create_order_with_items.
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Authenticated users can create orders" ON public.orders;
DROP POLICY IF EXISTS "Buyers can insert order items" ON public.order_items;

REVOKE INSERT ON public.orders, public.order_items FROM PUBLIC, anon, authenticated;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'orders_total_amount_non_negative'
      AND conrelid = 'public.orders'::regclass
  ) THEN
    ALTER TABLE public.orders
      ADD CONSTRAINT orders_total_amount_non_negative
      CHECK (total_amount >= 0) NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'orders_buyer_not_seller'
      AND conrelid = 'public.orders'::regclass
  ) THEN
    ALTER TABLE public.orders
      ADD CONSTRAINT orders_buyer_not_seller
      CHECK (buyer_id <> seller_id) NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'order_items_non_negative_amounts'
      AND conrelid = 'public.order_items'::regclass
  ) THEN
    ALTER TABLE public.order_items
      ADD CONSTRAINT order_items_non_negative_amounts
      CHECK (unit_price >= 0 AND total_price >= 0 AND quantity_kg > 0) NOT VALID;
  END IF;
END $$;

-- ----------------------------------------------------------------------------
-- 2. create_order_with_items: zabrana samoporudžbine + ograničenja za p_items i količinu
-- ----------------------------------------------------------------------------
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

  IF p_buyer_id = p_seller_id THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'Prodavac ne može poručiti sopstveni proizvod.';
  END IF;

  IF p_buyer_phone IS NULL OR TRIM(p_buyer_phone) = '' THEN
    RAISE EXCEPTION 'buyer_phone is required';
  END IF;

  IF p_items IS NULL
     OR jsonb_typeof(p_items) <> 'array'
     OR jsonb_array_length(p_items) = 0 THEN
    RAISE EXCEPTION 'items are required';
  END IF;

  IF jsonb_array_length(p_items) > 50 THEN
    RAISE EXCEPTION 'Previše stavki u jednoj porudžbini (maksimalno 50).';
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
    CASE WHEN v_delivery_method = 'seller_delivery' THEN v_delivery_slot.delivery_fee_rsd ELSE NULL END,
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

    IF v_item_quantity IS NULL OR v_item_quantity <= 0 OR v_item_quantity > 10000 THEN
      RAISE EXCEPTION 'quantity_kg must be between 0 and 10000 for product %', v_item_product_id;
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
      v_item_total_price := ROUND(v_item_quantity * v_item_unit_price, 2);
    ELSIF v_product.unit_type IN ('kg', 'L')
          AND v_product.min_order_kg > 0
          AND v_product.min_order_kg < 1 THEN
      v_item_total_price := ROUND((v_item_quantity / v_product.min_order_kg) * v_item_unit_price, 2);
    ELSE
      v_item_total_price := ROUND(v_item_quantity * v_item_unit_price, 2);
    END IF;

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

REVOKE ALL ON FUNCTION public.create_order_with_items(
  UUID, UUID, TEXT, JSONB, TEXT, TEXT, TEXT, TEXT, TEXT, UUID, UUID, NUMERIC
) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_order_with_items(
  UUID, UUID, TEXT, JSONB, TEXT, TEXT, TEXT, TEXT, TEXT, UUID, UUID, NUMERIC
) TO authenticated, service_role;

-- ----------------------------------------------------------------------------
-- 3. IDOR zaštita u get_or_create_conversation, get_seller_inbox,
--    get_conversation_info_with_profile i get_conversations_for_user
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_or_create_conversation(
  p_buyer_id UUID,
  p_seller_id UUID,
  p_product_id UUID DEFAULT NULL,
  p_ad_id UUID DEFAULT NULL,
  p_order_id UUID DEFAULT NULL,
  p_update_order_id BOOLEAN DEFAULT TRUE
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_conv_id UUID;
  v_product_id UUID := p_product_id;
  v_ad_id UUID := p_ad_id;
  v_product_owner UUID;
  v_ad_owner UUID;
BEGIN
  IF p_buyer_id = p_seller_id THEN
    RAISE EXCEPTION 'Buyer and seller cannot be the same user';
  END IF;

  IF current_user IN ('anon', 'authenticated')
     AND (auth.uid() IS NULL OR (auth.uid() <> p_buyer_id AND auth.uid() <> p_seller_id)) THEN
    RAISE EXCEPTION USING
      ERRCODE = '42501',
      MESSAGE = 'Not authorized to create conversation for other users';
  END IF;

  -- Provera vlasništva referenciranih entiteta (sprečava IDOR vezivanje tuđeg order/product/ad ID-a)
  IF p_order_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.orders o
      WHERE o.id = p_order_id
        AND o.buyer_id = p_buyer_id
        AND o.seller_id = p_seller_id
    ) THEN
      RAISE EXCEPTION USING
        ERRCODE = '42501',
        MESSAGE = 'Order does not belong to specified buyer and seller';
    END IF;
  END IF;

  IF v_product_id IS NOT NULL THEN
    SELECT p.seller_id INTO v_product_owner
    FROM public.products p
    WHERE p.id = v_product_id;

    IF NOT FOUND THEN
      IF p_order_id IS NOT NULL THEN
        -- Proizvod je u međuvremenu obrisan; dozvoli otvaranje četa za validnu porudžbinu bez product_id
        v_product_id := NULL;
      ELSE
        RAISE EXCEPTION USING
          ERRCODE = '42501',
          MESSAGE = 'Product does not belong to specified seller';
      END IF;
    ELSIF v_product_owner <> p_seller_id THEN
      RAISE EXCEPTION USING
        ERRCODE = '42501',
        MESSAGE = 'Product does not belong to specified seller';
    END IF;
  END IF;

  IF v_ad_id IS NOT NULL THEN
    SELECT ca.user_id INTO v_ad_owner
    FROM public.classified_ads ca
    WHERE ca.id = v_ad_id;

    IF NOT FOUND THEN
      IF p_order_id IS NOT NULL THEN
        v_ad_id := NULL;
      ELSE
        RAISE EXCEPTION USING
          ERRCODE = '42501',
          MESSAGE = 'Classified ad does not belong to specified seller';
      END IF;
    ELSIF v_ad_owner <> p_seller_id THEN
      RAISE EXCEPTION USING
        ERRCODE = '42501',
        MESSAGE = 'Classified ad does not belong to specified seller';
    END IF;
  END IF;

  -- 1. Ako je prosleđen order_id, proveri da li već postoji razgovor vezan za tu porudžbinu i iste učesnike
  IF p_order_id IS NOT NULL THEN
    SELECT id INTO v_conv_id
    FROM public.conversations
    WHERE order_id = p_order_id
      AND buyer_id = p_buyer_id
      AND seller_id = p_seller_id
    LIMIT 1;

    IF v_conv_id IS NOT NULL THEN
      RETURN v_conv_id;
    END IF;
  END IF;

  -- 2. Proveri da li postoji opšti/predmetni razgovor
  IF v_product_id IS NOT NULL THEN
    SELECT id INTO v_conv_id
    FROM public.conversations
    WHERE buyer_id = p_buyer_id
      AND seller_id = p_seller_id
      AND product_id = v_product_id
      AND (p_order_id IS NULL OR order_id IS NULL)
    ORDER BY (order_id IS NULL) DESC, updated_at DESC
    LIMIT 1;
  ELSIF v_ad_id IS NOT NULL THEN
    SELECT id INTO v_conv_id
    FROM public.conversations
    WHERE buyer_id = p_buyer_id
      AND seller_id = p_seller_id
      AND ad_id = v_ad_id
      AND (p_order_id IS NULL OR order_id IS NULL)
    ORDER BY (order_id IS NULL) DESC, updated_at DESC
    LIMIT 1;
  ELSE
    SELECT id INTO v_conv_id
    FROM public.conversations
    WHERE buyer_id = p_buyer_id
      AND seller_id = p_seller_id
      AND product_id IS NULL
      AND ad_id IS NULL
      AND (p_order_id IS NULL OR order_id IS NULL)
    ORDER BY (order_id IS NULL) DESC, updated_at DESC
    LIMIT 1;
  END IF;

  IF v_conv_id IS NOT NULL THEN
    IF p_order_id IS NOT NULL AND p_update_order_id THEN
      UPDATE public.conversations
      SET order_id = p_order_id, updated_at = NOW()
      WHERE id = v_conv_id AND order_id IS NULL;
    END IF;
    RETURN v_conv_id;
  END IF;

  -- 3. Atomska kreacija sa unique_violation zaštitom od konkurentnih upisa
  BEGIN
    INSERT INTO public.conversations (
      buyer_id,
      seller_id,
      product_id,
      ad_id,
      order_id,
      created_at,
      updated_at
    )
    VALUES (
      p_buyer_id,
      p_seller_id,
      v_product_id,
      v_ad_id,
      p_order_id,
      NOW(),
      NOW()
    )
    RETURNING id INTO v_conv_id;

    RETURN v_conv_id;
  EXCEPTION WHEN unique_violation THEN
    IF p_order_id IS NOT NULL THEN
      SELECT id INTO v_conv_id
      FROM public.conversations
      WHERE order_id = p_order_id
        AND buyer_id = p_buyer_id
        AND seller_id = p_seller_id
      LIMIT 1;
    END IF;

    IF v_conv_id IS NULL AND v_product_id IS NOT NULL THEN
      SELECT id INTO v_conv_id
      FROM public.conversations
      WHERE buyer_id = p_buyer_id
        AND seller_id = p_seller_id
        AND product_id = v_product_id
        AND (p_order_id IS NULL OR order_id IS NULL)
      LIMIT 1;
    ELSIF v_conv_id IS NULL AND v_ad_id IS NOT NULL THEN
      SELECT id INTO v_conv_id
      FROM public.conversations
      WHERE buyer_id = p_buyer_id
        AND seller_id = p_seller_id
        AND ad_id = v_ad_id
        AND (p_order_id IS NULL OR order_id IS NULL)
      LIMIT 1;
    ELSIF v_conv_id IS NULL THEN
      SELECT id INTO v_conv_id
      FROM public.conversations
      WHERE buyer_id = p_buyer_id
        AND seller_id = p_seller_id
        AND product_id IS NULL
        AND ad_id IS NULL
        AND (p_order_id IS NULL OR order_id IS NULL)
      LIMIT 1;
    END IF;

    IF v_conv_id IS NOT NULL THEN
      RETURN v_conv_id;
    END IF;

    RAISE;
  END;
END;
$$;

REVOKE ALL ON FUNCTION public.get_or_create_conversation(UUID, UUID, UUID, UUID, UUID, BOOLEAN) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_or_create_conversation(UUID, UUID, UUID, UUID, UUID, BOOLEAN) TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.get_seller_inbox(
  p_seller_id UUID,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS JSONB
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH
  auth_check AS (
    SELECT (p_seller_id = (SELECT auth.uid()) OR (SELECT public.is_admin())) AS is_allowed
  ),
  conv_rows AS (
    SELECT
      'conversation'::text AS item_type,
      c.updated_at AS sort_date,
      c.id AS conversation_id,
      o.id AS order_id,
      c.buyer_id AS buyer_id,
      c.product_id AS product_id,
      c.ad_id AS ad_id,
      COALESCE(pb.farm_name, pb.display_name, 'Kupac') AS other_party_name,
      pb.profile_image_url AS other_party_image_url,
      lm.body AS last_message_body,
      (SELECT COUNT(*)::int FROM public.messages m2
       WHERE m2.conversation_id = c.id
         AND m2.sender_id != p_seller_id
         AND m2.read_at IS NULL) AS unread_count,
      COALESCE(
        p.name,
        ad.title,
        o.product_name,
        CASE
          WHEN oi_agg.cnt > 1 THEN oi_agg.cnt::text || ' proizvoda'
          ELSE oi_agg.first_product_name
        END
      ) AS product_name,
      COALESCE(o.quantity_kg::float8, oi_agg.first_quantity_kg::float8) AS quantity_kg,
      COALESCE(p.unit_type, ad.currency, o.unit_type, oi_agg.first_unit_type) AS unit_type,
      o.status AS status,
      CASE o.status
        WHEN 'sent' THEN 'Na čekanju'
        WHEN 'accepted' THEN 'Prihvaćeno'
        WHEN 'shipped' THEN 'Poslato'
        WHEN 'rejected' THEN 'Odbijeno'
        WHEN 'delivered' THEN 'Isporučeno'
        WHEN 'cancelled_by_seller' THEN 'Otkazano'
        WHEN 'archived' THEN 'Arhivirano'
        WHEN 'arhivirano' THEN 'Arhivirano'
        ELSE NULL
      END AS status_label,
      o.buyer_phone AS buyer_phone,
      o.note AS note,
      o.buyer_city AS buyer_city,
      o.buyer_address AS buyer_address
    FROM public.conversations c
    CROSS JOIN auth_check ac
    JOIN public.profiles pb ON pb.id = c.buyer_id
    LEFT JOIN public.products p ON p.id = c.product_id
    LEFT JOIN public.classified_ads ad ON ad.id = c.ad_id
    LEFT JOIN public.orders o
      ON o.id = c.order_id
     AND o.seller_id = p_seller_id
     AND o.buyer_id = c.buyer_id
    LEFT JOIN LATERAL (
      SELECT
        COUNT(*) AS cnt,
        (ARRAY_AGG(oi.product_name ORDER BY oi.id ASC))[1] AS first_product_name,
        (ARRAY_AGG(oi.quantity_kg ORDER BY oi.id ASC))[1] AS first_quantity_kg,
        (ARRAY_AGG(oi.unit_type ORDER BY oi.id ASC))[1] AS first_unit_type
      FROM public.order_items oi
      WHERE oi.order_id = o.id
    ) oi_agg ON o.id IS NOT NULL AND o.product_id IS NULL
    LEFT JOIN LATERAL (
      SELECT body FROM public.messages
      WHERE conversation_id = c.id
      ORDER BY created_at DESC
      LIMIT 1
    ) lm ON true
    WHERE ac.is_allowed = true
      AND c.seller_id = p_seller_id
  ),
  order_ids_with_conv AS (
    SELECT DISTINCT order_id FROM public.conversations
    WHERE seller_id = p_seller_id AND order_id IS NOT NULL
  ),
  order_rows AS (
    SELECT
      'order'::text AS item_type,
      o.created_at AS sort_date,
      NULL::uuid AS conversation_id,
      o.id AS order_id,
      o.buyer_id AS buyer_id,
      COALESCE(o.product_id, oi_agg.first_product_id) AS product_id,
      NULL::uuid AS ad_id,
      COALESCE(pb.farm_name, pb.display_name, 'Kupac') AS other_party_name,
      pb.profile_image_url AS other_party_image_url,
      NULL::text AS last_message_body,
      0 AS unread_count,
      COALESCE(
        o.product_name,
        CASE
          WHEN oi_agg.cnt > 1 THEN oi_agg.cnt::text || ' proizvoda'
          ELSE oi_agg.first_product_name
        END
      ) AS product_name,
      COALESCE(o.quantity_kg::float8, oi_agg.first_quantity_kg::float8) AS quantity_kg,
      COALESCE(o.unit_type, oi_agg.first_unit_type) AS unit_type,
      o.status AS status,
      CASE o.status
        WHEN 'sent' THEN 'Na čekanju'
        WHEN 'accepted' THEN 'Prihvaćeno'
        WHEN 'shipped' THEN 'Poslato'
        WHEN 'rejected' THEN 'Odbijeno'
        WHEN 'delivered' THEN 'Isporučeno'
        WHEN 'cancelled_by_seller' THEN 'Otkazano'
        WHEN 'archived' THEN 'Arhivirano'
        WHEN 'arhivirano' THEN 'Arhivirano'
        ELSE NULL
      END AS status_label,
      o.buyer_phone AS buyer_phone,
      o.note AS note,
      o.buyer_city AS buyer_city,
      o.buyer_address AS buyer_address
    FROM public.orders o
    CROSS JOIN auth_check ac
    JOIN public.profiles pb ON pb.id = o.buyer_id
    LEFT JOIN LATERAL (
      SELECT
        COUNT(*) AS cnt,
        (ARRAY_AGG(oi.product_id ORDER BY oi.id ASC))[1] AS first_product_id,
        (ARRAY_AGG(oi.product_name ORDER BY oi.id ASC))[1] AS first_product_name,
        (ARRAY_AGG(oi.quantity_kg ORDER BY oi.id ASC))[1] AS first_quantity_kg,
        (ARRAY_AGG(oi.unit_type ORDER BY oi.id ASC))[1] AS first_unit_type
      FROM public.order_items oi
      WHERE oi.order_id = o.id
    ) oi_agg ON o.product_id IS NULL
    WHERE ac.is_allowed = true
      AND o.seller_id = p_seller_id
      AND o.id NOT IN (SELECT order_id FROM order_ids_with_conv WHERE order_id IS NOT NULL)
  ),
  combined AS (
    SELECT * FROM conv_rows
    UNION ALL
    SELECT * FROM order_rows
  )
  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'type', item_type,
        'sort_date', to_char(sort_date, 'YYYY-MM-DD"T"HH24:MI:SS.MS'),
        'order_id', order_id,
        'conversation_id', conversation_id,
        'buyer_id', buyer_id,
        'product_id', product_id,
        'ad_id', ad_id,
        'other_party_name', other_party_name,
        'other_party_image_url', other_party_image_url,
        'product_name', product_name,
        'quantity_kg', quantity_kg,
        'unit_type', unit_type,
        'status', status,
        'last_message_body', last_message_body,
        'unread_count', unread_count,
        'status_label', status_label,
        'buyer_phone', buyer_phone,
        'note', note,
        'buyer_city', buyer_city,
        'buyer_address', buyer_address
      )
      ORDER BY sort_date DESC NULLS LAST, COALESCE(conversation_id, order_id) DESC
    ),
    '[]'::jsonb
  )
  FROM (
    SELECT * FROM combined
    ORDER BY sort_date DESC NULLS LAST, COALESCE(conversation_id, order_id) DESC
    LIMIT GREATEST(COALESCE(p_limit, 20), 0)
    OFFSET GREATEST(COALESCE(p_offset, 0), 0)
  ) AS limited_combined;
$$;

CREATE OR REPLACE FUNCTION public.get_conversation_info_with_profile(
  p_conversation_id TEXT
)
RETURNS TABLE (
  id TEXT,
  buyer_id TEXT,
  seller_id TEXT,
  order_id TEXT,
  buyer_name TEXT,
  seller_name TEXT,
  product_id TEXT,
  ad_id TEXT,
  item_title TEXT,
  item_image_url TEXT,
  item_price NUMERIC,
  item_unit TEXT,
  item_type TEXT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id::text,
    c.buyer_id::text,
    c.seller_id::text,
    o.id::text,
    COALESCE(pb.farm_name, pb.display_name, 'Kupac')::text AS buyer_name,
    COALESCE(ps.farm_name, ps.display_name, 'Prodavac')::text AS seller_name,
    c.product_id::text,
    c.ad_id::text,
    COALESCE(
      p.name,
      ad.title,
      (SELECT oi.product_name FROM public.order_items oi WHERE oi.order_id = o.id LIMIT 1),
      o.product_name
    )::text AS item_title,
    COALESCE(p.image_urls[1], ad.images[1])::text AS item_image_url,
    COALESCE(p.price_per_kg, ad.price)::numeric AS item_price,
    COALESCE(p.unit_type, ad.currency)::text AS item_unit,
    CASE
      WHEN c.product_id IS NOT NULL THEN 'product'
      WHEN c.ad_id IS NOT NULL THEN 'ad'
      WHEN o.id IS NOT NULL THEN 'order'
      ELSE NULL
    END::text AS item_type
  FROM public.conversations c
  LEFT JOIN public.profiles pb ON c.buyer_id = pb.id
  LEFT JOIN public.profiles ps ON c.seller_id = ps.id
  LEFT JOIN public.products p ON c.product_id = p.id
  LEFT JOIN public.classified_ads ad ON c.ad_id = ad.id
  LEFT JOIN public.orders o
    ON o.id = c.order_id
   AND o.buyer_id = c.buyer_id
   AND o.seller_id = c.seller_id
  WHERE c.id::text = p_conversation_id
    AND (
      c.buyer_id = (SELECT auth.uid())
      OR c.seller_id = (SELECT auth.uid())
      OR (SELECT public.is_admin())
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.get_conversations_for_user(p_user_id UUID)
RETURNS JSONB
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    jsonb_agg(row_to_json(t)::jsonb ORDER BY (row_to_json(t) ->> 'updated_at') DESC),
    '[]'::jsonb
  )
  FROM (
    SELECT
      c.id,
      c.buyer_id,
      c.seller_id,
      o.id                                                                 AS order_id,
      c.product_id,
      c.ad_id,
      c.created_at,
      c.updated_at,
      COALESCE(
        CASE WHEN c.buyer_id = p_user_id
             THEN COALESCE(ps.farm_name, ps.display_name)
             ELSE COALESCE(pb.farm_name, pb.display_name)
        END,
        'Korisnik'
      )                                                                    AS other_party_name,
      CASE WHEN c.buyer_id = p_user_id
           THEN ps.profile_image_url
           ELSE pb.profile_image_url
      END                                                                  AS other_party_image_url,
      lm.body                                                              AS last_message_body,
      lm.created_at                                                        AS last_message_at,
      (SELECT COUNT(*)::int
         FROM public.messages m2
        WHERE m2.conversation_id = c.id
          AND m2.sender_id      != p_user_id
          AND m2.read_at         IS NULL)                                  AS unread_count,
      COALESCE(cup.is_favorite, false)                                     AS is_favorite,
      COALESCE(cup.hidden, false)                                          AS hidden,
      COALESCE(
        (SELECT oi.product_name FROM public.order_items oi WHERE oi.order_id = o.id LIMIT 1),
        o.product_name,
        p.name,
        ad.title
      )                                                                    AS item_title,
      COALESCE(
        p.image_urls[1],
        ad.images[1]
      )                                                                    AS item_image_url,
      COALESCE(p.price_per_kg, ad.price)                                   AS item_price,
      COALESCE(p.unit_type, ad.currency)                                   AS item_unit,
      CASE
        WHEN o.id IS NOT NULL THEN 'order'
        WHEN c.product_id IS NOT NULL THEN 'product'
        WHEN c.ad_id IS NOT NULL THEN 'ad'
        ELSE NULL
      END                                                                  AS item_type
    FROM public.conversations c
    JOIN public.profiles pb ON pb.id = c.buyer_id
    JOIN public.profiles ps ON ps.id = c.seller_id
    LEFT JOIN public.products p ON p.id = c.product_id
    LEFT JOIN public.classified_ads ad ON ad.id = c.ad_id
    LEFT JOIN public.orders o
      ON o.id = c.order_id
     AND o.buyer_id = c.buyer_id
     AND o.seller_id = c.seller_id
    LEFT JOIN public.conversation_user_prefs cup
      ON cup.conversation_id = c.id AND cup.user_id = p_user_id
    LEFT JOIN LATERAL (
      SELECT body, created_at
        FROM public.messages
       WHERE conversation_id = c.id
       ORDER BY created_at DESC
       LIMIT 1
    ) lm ON true
    WHERE (c.buyer_id = p_user_id OR c.seller_id = p_user_id)
      AND p_user_id = (SELECT auth.uid())
    ORDER BY c.updated_at DESC
    LIMIT 50
  ) t;
$$;

-- ----------------------------------------------------------------------------
-- 4. Vraćanje RLS i BEFORE INSERT validacije na public.buyer_reviews
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Sellers can insert buyer reviews" ON public.buyer_reviews;
CREATE POLICY "Sellers can insert buyer reviews"
  ON public.buyer_reviews
  FOR INSERT
  TO authenticated
  WITH CHECK (
    (SELECT auth.uid()) = seller_id
    AND EXISTS (
      SELECT 1 FROM public.orders o
      WHERE o.id = order_id
        AND o.seller_id = (SELECT auth.uid())
        AND o.buyer_id = buyer_id
        AND o.buyer_id <> o.seller_id
        AND o.status IN ('delivered', 'archived', 'arhivirano')
    )
  );

CREATE OR REPLACE FUNCTION public.validate_seller_buyer_review_submission()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_order_status TEXT;
  v_order_buyer UUID;
  v_order_seller UUID;
BEGIN
  IF NEW.order_id IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = '23502',
      MESSAGE = 'Ocena kupca mora biti vezana za realizovanu porudžbinu.';
  END IF;

  SELECT status, buyer_id, seller_id
    INTO v_order_status, v_order_buyer, v_order_seller
  FROM public.orders
  WHERE id = NEW.order_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = '23503',
      MESSAGE = 'Navedena porudžbina ne postoji u sistemu.';
  END IF;

  IF v_uid IS NOT NULL AND v_order_seller <> v_uid THEN
    RAISE EXCEPTION USING
      ERRCODE = '42501',
      MESSAGE = 'Možete oceniti kupca isključivo za sopstvenu porudžbinu.';
  END IF;

  IF v_order_buyer = v_order_seller OR NEW.buyer_id = NEW.seller_id THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'Ne možete oceniti sami sebe.';
  END IF;

  IF NEW.buyer_id <> v_order_buyer OR NEW.seller_id <> v_order_seller THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'Učesnici u oceni se ne poklapaju sa porudžbinom.';
  END IF;

  IF v_order_status NOT IN ('delivered', 'archived', 'arhivirano') THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'Kupca možete oceniti tek nakon isporučene porudžbine.';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_seller_buyer_review_submission ON public.buyer_reviews;
CREATE TRIGGER trg_validate_seller_buyer_review_submission
  BEFORE INSERT ON public.buyer_reviews
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_seller_buyer_review_submission();

-- ----------------------------------------------------------------------------
-- 5. Očvršćavanje validate_buyer_review_submission (zabrana self-review i cross-product hijack-a)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.validate_buyer_review_submission()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_order_status TEXT;
  v_order_buyer UUID;
  v_order_seller UUID;
  v_order_product_id UUID;
BEGIN
  IF NEW.order_id IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = '23502',
      MESSAGE = 'Recenzija mora biti vezana za realizovanu porudžbinu.';
  END IF;

  SELECT status, buyer_id, seller_id, product_id
    INTO v_order_status, v_order_buyer, v_order_seller, v_order_product_id
  FROM public.orders
  WHERE id = NEW.order_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = '23503',
      MESSAGE = 'Navedena porudžbina ne postoji u sistemu.';
  END IF;

  IF v_uid IS NOT NULL AND v_order_buyer <> v_uid THEN
    RAISE EXCEPTION USING
      ERRCODE = '42501',
      MESSAGE = 'Možete ostaviti recenziju isključivo za sopstvenu porudžbinu.';
  END IF;

  IF v_order_buyer = v_order_seller OR NEW.buyer_id = NEW.seller_id THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'Ne možete ostaviti recenziju za sopstvenu prodavnicu.';
  END IF;

  IF NEW.seller_id <> v_order_seller THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'Prodavac u recenziji se ne poklapa sa prodavcem iz porudžbine.';
  END IF;

  IF v_order_status NOT IN ('delivered', 'arhivirano', 'archived') THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'Recenziju možete ostaviti tek nakon što je porudžbina isporučena.',
      DETAIL = format('order_status=%s', v_order_status);
  END IF;

  -- Provera da recenzirani proizvod zaista pripada ovoj porudžbini (sprečava cross-product podmetanje)
  IF NEW.product_id IS NOT NULL THEN
    IF NOT (
      v_order_product_id = NEW.product_id
      OR EXISTS (
        SELECT 1 FROM public.order_items oi
        WHERE oi.order_id = NEW.order_id
          AND oi.product_id = NEW.product_id
      )
    ) THEN
      RAISE EXCEPTION USING
        ERRCODE = '23514',
        MESSAGE = 'Recenzirani proizvod ne pripada navedenoj porudžbini.';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- ----------------------------------------------------------------------------
-- 6. public.conversations: uklanjanje FOR ALL (zabrana client DELETE/tampering)
--    i SECURITY DEFINER na trigger-u za ažuriranje updated_at pri slanju poruke
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.conversation_updated_on_message()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.conversations SET updated_at = NOW() WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$;

DROP POLICY IF EXISTS "Users see own conversations" ON public.conversations;
DROP POLICY IF EXISTS "Users insert own conversations" ON public.conversations;
DROP POLICY IF EXISTS "Users update own conversations" ON public.conversations;

CREATE POLICY "Users see own conversations"
  ON public.conversations
  FOR SELECT
  TO authenticated
  USING (
    (SELECT auth.uid()) = buyer_id
    OR (SELECT auth.uid()) = seller_id
    OR (SELECT public.is_admin())
  );

REVOKE INSERT, UPDATE, DELETE ON public.conversations FROM PUBLIC, anon, authenticated;

-- ----------------------------------------------------------------------------
-- 7. public.is_admin(): omogući anon izvršavanje (vraća false za NULL auth.uid())
--    kako anon RLS politike na profiles i classified_ads ne bi bacale 42501
-- ----------------------------------------------------------------------------
GRANT EXECUTE ON FUNCTION public.is_admin() TO anon, authenticated, service_role;

-- ----------------------------------------------------------------------------
-- 8. adjust_product_order_summary & maintain_order_items_summary:
--    zaštita od NULL product_id (obrisani proizvodi) i usklađen skup statusa
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.adjust_product_order_summary(
  p_order_id UUID,
  p_delta BIGINT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_has_items BOOLEAN;
BEGIN
  IF p_delta = 0 THEN
    RETURN;
  END IF;

  SELECT EXISTS(SELECT 1 FROM public.order_items WHERE order_id = p_order_id) INTO v_has_items;

  IF v_has_items THEN
    INSERT INTO public.product_order_summary (product_id, order_count)
    SELECT DISTINCT oi.product_id, p_delta
    FROM public.order_items oi
    WHERE oi.order_id = p_order_id
      AND oi.product_id IS NOT NULL
    ON CONFLICT (product_id)
    DO UPDATE SET order_count = public.product_order_summary.order_count + EXCLUDED.order_count;

    DELETE FROM public.product_order_summary s
    WHERE s.order_count <= 0
      AND EXISTS (
        SELECT 1 FROM public.order_items oi
        WHERE oi.order_id = p_order_id
          AND oi.product_id IS NOT NULL
          AND oi.product_id = s.product_id
      );
  ELSE
    INSERT INTO public.product_order_summary (product_id, order_count)
    SELECT o.product_id, p_delta
    FROM public.orders o
    WHERE o.id = p_order_id
      AND o.product_id IS NOT NULL
    ON CONFLICT (product_id)
    DO UPDATE SET order_count = public.product_order_summary.order_count + EXCLUDED.order_count;

    DELETE FROM public.product_order_summary s
    WHERE s.order_count <= 0
      AND EXISTS (
        SELECT 1 FROM public.orders o
        WHERE o.id = p_order_id
          AND o.product_id IS NOT NULL
          AND o.product_id = s.product_id
      );
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.maintain_product_order_summary()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_old_counted BOOLEAN;
  v_new_counted BOOLEAN;
  v_delta BIGINT;
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.status IN ('accepted', 'shipped', 'delivered', 'archived', 'arhivirano') THEN
      PERFORM public.adjust_product_order_summary(NEW.id, 1);
    END IF;

  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
      v_old_counted := OLD.status IN ('accepted', 'shipped', 'delivered', 'archived', 'arhivirano');
      v_new_counted := NEW.status IN ('accepted', 'shipped', 'delivered', 'archived', 'arhivirano');
      IF v_old_counted <> v_new_counted THEN
        v_delta := CASE WHEN v_new_counted THEN 1 ELSE -1 END;
        PERFORM public.adjust_product_order_summary(NEW.id, v_delta);
      END IF;
    END IF;

  ELSIF TG_OP = 'DELETE' THEN
    IF OLD.status IN ('accepted', 'shipped', 'delivered', 'archived', 'arhivirano') THEN
      PERFORM public.adjust_product_order_summary(OLD.id, -1);
    END IF;
  END IF;

  RETURN NULL;
END;
$$;

CREATE OR REPLACE FUNCTION public.maintain_order_items_summary()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_status TEXT;
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.product_id IS NULL THEN
      RETURN NULL;
    END IF;
    SELECT status INTO v_status FROM public.orders WHERE id = NEW.order_id;
    IF v_status IN ('accepted', 'shipped', 'delivered', 'archived', 'arhivirano') THEN
      INSERT INTO public.product_order_summary (product_id, order_count)
      VALUES (NEW.product_id, 1)
      ON CONFLICT (product_id)
      DO UPDATE SET order_count = public.product_order_summary.order_count + 1;
    END IF;
  ELSIF TG_OP = 'DELETE' THEN
    IF OLD.product_id IS NULL THEN
      RETURN NULL;
    END IF;
    SELECT status INTO v_status FROM public.orders WHERE id = OLD.order_id;
    IF v_status IN ('accepted', 'shipped', 'delivered', 'archived', 'arhivirano') THEN
      UPDATE public.product_order_summary
      SET order_count = order_count - 1
      WHERE product_id = OLD.product_id;

      DELETE FROM public.product_order_summary
      WHERE product_id = OLD.product_id AND order_count <= 0;
    END IF;
  END IF;
  RETURN NULL;
END;
$$;

-- Re-sinkronizacija product_order_summary sa usklađenim statusima (ignorišući obrisane proizvode, bez ACCESS EXCLUSIVE locka)
DELETE FROM public.product_order_summary;
INSERT INTO public.product_order_summary (product_id, order_count)
SELECT product_id, COUNT(DISTINCT order_id)::bigint AS order_count
FROM (
  SELECT oi.product_id, oi.order_id
  FROM public.order_items oi
  JOIN public.orders o ON o.id = oi.order_id
  WHERE oi.product_id IS NOT NULL
    AND o.status IN ('accepted', 'shipped', 'delivered', 'archived', 'arhivirano')
  UNION ALL
  SELECT o.product_id, o.id AS order_id
  FROM public.orders o
  WHERE o.product_id IS NOT NULL
    AND o.status IN ('accepted', 'shipped', 'delivered', 'archived', 'arhivirano')
    AND NOT EXISTS (SELECT 1 FROM public.order_items oi WHERE oi.order_id = o.id)
) counted
GROUP BY product_id
HAVING COUNT(DISTINCT order_id) > 0;

-- ----------------------------------------------------------------------------
-- 9. Ukidanje podrazumevanog PUBLIC EXECUTE na SECURITY DEFINER RPC-ovima
-- ----------------------------------------------------------------------------
REVOKE ALL ON FUNCTION public.audit_product_ordering(INT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.audit_product_ordering(INT) TO service_role;

REVOKE ALL ON FUNCTION public.add_buyer_reply(UUID, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.add_buyer_reply(UUID, TEXT) TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.add_seller_reply(UUID, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.add_seller_reply(UUID, TEXT) TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.archive_order(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.archive_order(UUID) TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.get_buyer_stats_dashboard(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_buyer_stats_dashboard(UUID) TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.get_conversation_info_with_profile(TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_conversation_info_with_profile(TEXT) TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.get_conversations_for_user(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_conversations_for_user(UUID) TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.get_favorite_sellers_with_profiles(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_favorite_sellers_with_profiles(UUID) TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.get_my_product_listing_autoflag_summary() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_my_product_listing_autoflag_summary() TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.get_my_product_listing_autoflags() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_my_product_listing_autoflags() TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.get_products_from_favorite_sellers(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_products_from_favorite_sellers(UUID) TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.get_reviewable_order(UUID, UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_reviewable_order(UUID, UUID) TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.get_seller_inbox(UUID, INT, INT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_seller_inbox(UUID, INT, INT) TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.get_seller_stats_dashboard(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_seller_stats_dashboard(UUID) TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.mark_conversation_read(UUID, INT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.mark_conversation_read(UUID, INT) TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.set_conversation_user_prefs(UUID, BOOLEAN, BOOLEAN) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.set_conversation_user_prefs(UUID, BOOLEAN, BOOLEAN) TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.set_product_delivery_scope(UUID, TEXT, UUID[]) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.set_product_delivery_scope(UUID, TEXT, UUID[]) TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.get_product_sales_counts() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_product_sales_counts() TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.get_product_ratings() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_product_ratings() TO anon, authenticated, service_role;
