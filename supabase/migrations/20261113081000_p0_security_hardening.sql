-- ============================================================================
-- Migracija: 20261113081000_p0_security_hardening.sql
-- Paket 1 (P0 bezbednosno očvršćavanje):
--   1. enforce_order_status_transition(): sprečava klijentsku izmenu finansijskih
--      i drugih zaštićenih kolona na public.orders čak i kada status ostaje isti
--   2. create_order_with_items(): ignoriše klijentski p_delivery_fee_rsd i uvek
--      koristi cenu dostave iz baze (v_delivery_slot.delivery_fee_rsd)
--   3. get_or_create_conversation(): blokira neautentifikovane pozive (auth.uid() IS NULL)
--      i povlači EXECUTE privilegiju od PUBLIC i anon uloga
--   4. check_phone_exists(): anti-enumeration zaštita identična check_email_exists()
--   5. check_push_configuration(): admin-only provera i povlačenje javnog EXECUTE prava
--   6. admin_set_seller_verified() i interni/cron SECURITY DEFINER helperi:
--      povlačenje nepotrebnih EXECUTE privilegija od PUBLIC/anon/authenticated
--   7. send_push_notification(): transaction-local set_config(..., true) pod PgBouncer-om
--   8. v_classified_categories: security_invoker = true i SELECT-only privilegije
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. enforce_order_status_transition: stroga zaštita kolona na public.orders
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.enforce_order_status_transition()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_caller UUID;
  v_is_seller BOOLEAN := false;
  v_is_buyer BOOLEAN := false;
  v_allowed BOOLEAN := false;
BEGIN
  -- Direktni PostgREST pozivi (anon/authenticated) ne smeju menjati nijednu kolonu
  -- porudžbine osim dozvoljene tranzicije statusa i razloga otkazivanja prilikom
  -- samog otkazivanja od strane prodavca.
  IF current_user IN ('anon', 'authenticated') THEN
    IF NEW.id IS DISTINCT FROM OLD.id
      OR NEW.buyer_id IS DISTINCT FROM OLD.buyer_id
      OR NEW.seller_id IS DISTINCT FROM OLD.seller_id
      OR NEW.product_id IS DISTINCT FROM OLD.product_id
      OR NEW.product_name IS DISTINCT FROM OLD.product_name
      OR NEW.quantity_kg IS DISTINCT FROM OLD.quantity_kg
      OR NEW.unit_type IS DISTINCT FROM OLD.unit_type
      OR NEW.total_amount IS DISTINCT FROM OLD.total_amount
      OR NEW.note IS DISTINCT FROM OLD.note
      OR NEW.buyer_city IS DISTINCT FROM OLD.buyer_city
      OR NEW.buyer_phone IS DISTINCT FROM OLD.buyer_phone
      OR NEW.buyer_address IS DISTINCT FROM OLD.buyer_address
      OR NEW.buyer_postal_code IS DISTINCT FROM OLD.buyer_postal_code
      OR NEW.prefer_call IS DISTINCT FROM OLD.prefer_call
      OR NEW.delivery_method IS DISTINCT FROM OLD.delivery_method
      OR NEW.delivery_city IS DISTINCT FROM OLD.delivery_city
      OR NEW.delivery_point_id IS DISTINCT FROM OLD.delivery_point_id
      OR NEW.delivery_point_label IS DISTINCT FROM OLD.delivery_point_label
      OR NEW.delivery_address IS DISTINCT FROM OLD.delivery_address
      OR NEW.delivery_weekday IS DISTINCT FROM OLD.delivery_weekday
      OR NEW.delivery_time_from IS DISTINCT FROM OLD.delivery_time_from
      OR NEW.delivery_time_to IS DISTINCT FROM OLD.delivery_time_to
      OR NEW.delivery_fee_rsd IS DISTINCT FROM OLD.delivery_fee_rsd
      OR NEW.created_at IS DISTINCT FROM OLD.created_at
      OR NEW.archived_at IS DISTINCT FROM OLD.archived_at
      OR NEW.expires_at IS DISTINCT FROM OLD.expires_at
      OR NEW.status_changed_at IS DISTINCT FROM OLD.status_changed_at
    THEN
      RAISE EXCEPTION 'Izmena zaštićenih podataka porudžbine nije dozvoljena.'
        USING ERRCODE = 'insufficient_privilege';
    END IF;

    IF NEW.cancellation_reason IS DISTINCT FROM OLD.cancellation_reason
       AND NOT (
         OLD.status IS DISTINCT FROM NEW.status
         AND NEW.status = 'cancelled_by_seller'
         AND auth.uid() = OLD.seller_id
       ) THEN
      RAISE EXCEPTION 'Razlog otkazivanja može se izmeniti samo pri otkazivanju porudžbine od strane prodavca.'
        USING ERRCODE = 'insufficient_privilege';
    END IF;
  END IF;

  IF OLD.status = NEW.status THEN
    RETURN NEW;
  END IF;

  -- Dozvoli automatsku i jednokratnu normalizaciju 'arhivirano' -> 'archived'
  IF OLD.status = 'arhivirano' AND NEW.status = 'archived' THEN
    RETURN NEW;
  END IF;

  v_caller := auth.uid();

  -- Sistemski / service_role poziv (cron, background sync, interni helperi)
  IF (current_user NOT IN ('anon', 'authenticated') AND v_caller IS NULL)
     OR auth.role() = 'service_role' THEN
    v_allowed := CASE OLD.status
      WHEN 'sent' THEN NEW.status IN ('accepted', 'rejected')
      WHEN 'accepted' THEN NEW.status IN ('shipped', 'cancelled_by_seller')
      WHEN 'shipped' THEN NEW.status IN ('delivered', 'cancelled_by_seller')
      WHEN 'rejected' THEN NEW.status = 'archived'
      WHEN 'cancelled_by_seller' THEN NEW.status = 'archived'
      WHEN 'delivered' THEN NEW.status = 'archived'
      WHEN 'archived' THEN false
      ELSE false
    END;

    IF NOT v_allowed THEN
      RAISE EXCEPTION 'Nedozvoljena promena statusa porudžbine (sistem): % -> %',
        OLD.status, NEW.status
        USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
  END IF;

  v_is_seller := (v_caller = OLD.seller_id);
  v_is_buyer  := (v_caller = OLD.buyer_id);

  IF NOT v_is_seller AND NOT v_is_buyer THEN
    RAISE EXCEPTION 'Nemate dozvolu za izmenu ove porudžbine.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  v_allowed := CASE OLD.status
    WHEN 'sent' THEN
      v_is_seller AND NEW.status IN ('accepted', 'rejected')
    WHEN 'accepted' THEN
      v_is_seller AND NEW.status IN ('shipped', 'cancelled_by_seller')
    WHEN 'shipped' THEN
      (v_is_seller AND NEW.status = 'cancelled_by_seller')
      OR
      (v_is_buyer AND NEW.status = 'delivered')
    WHEN 'rejected' THEN
      (v_is_seller OR v_is_buyer) AND NEW.status = 'archived'
    WHEN 'cancelled_by_seller' THEN
      (v_is_seller OR v_is_buyer) AND NEW.status = 'archived'
    WHEN 'delivered' THEN
      (v_is_seller OR v_is_buyer) AND NEW.status = 'archived'
    WHEN 'archived' THEN false
    ELSE false
  END;

  IF NOT v_allowed THEN
    RAISE EXCEPTION 'Nedozvoljena promena statusa porudžbine (%): % -> %',
      CASE WHEN v_is_seller THEN 'prodavac' ELSE 'kupac' END,
      OLD.status, NEW.status
      USING ERRCODE = 'check_violation',
      HINT = 'Dozvoljeno: sent->accepted/rejected; accepted->shipped/cancelled_by_seller; shipped->delivered/cancelled_by_seller; rejected/cancelled_by_seller/delivered->archived.';
  END IF;

  RETURN NEW;
END;
$$;


-- ----------------------------------------------------------------------------
-- 2. create_order_with_items: serversko računanje naknade za dostavu
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
      v_item_total_price := ROUND(v_item_quantity * v_item_unit_price, 2);
    ELSIF v_product.unit_type IN ('kg', 'L')
          AND v_product.min_order_kg > 0
          AND v_product.min_order_kg < 1 THEN
      -- Za proizvode u gramima/mililitrima (min_order_kg < 1), price_per_kg je cena tog pakovanja
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
-- 3. get_or_create_conversation: blokada auth.uid() IS NULL i REVOKE PUBLIC/anon
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
BEGIN
  IF p_buyer_id = p_seller_id THEN
    RAISE EXCEPTION 'Buyer and seller cannot be the same user';
  END IF;

  IF current_user IN ('anon', 'authenticated')
     AND (auth.uid() IS NULL OR (auth.uid() <> p_buyer_id AND auth.uid() <> p_seller_id)) THEN
    RAISE EXCEPTION 'Not authorized to create conversation for other users';
  END IF;

  -- 1. Ako je prosleđen order_id, proveri da li već postoji razgovor vezan za tu porudžbinu
  IF p_order_id IS NOT NULL THEN
    SELECT id INTO v_conv_id
    FROM public.conversations
    WHERE order_id = p_order_id
    LIMIT 1;

    IF v_conv_id IS NOT NULL THEN
      RETURN v_conv_id;
    END IF;
  END IF;

  -- 2. Proveri da li postoji opšti/predmetni razgovor
  IF p_product_id IS NOT NULL THEN
    SELECT id INTO v_conv_id
    FROM public.conversations
    WHERE buyer_id = p_buyer_id
      AND seller_id = p_seller_id
      AND product_id = p_product_id
      AND (p_order_id IS NULL OR order_id IS NULL)
    ORDER BY (order_id IS NULL) DESC, updated_at DESC
    LIMIT 1;
  ELSIF p_ad_id IS NOT NULL THEN
    SELECT id INTO v_conv_id
    FROM public.conversations
    WHERE buyer_id = p_buyer_id
      AND seller_id = p_seller_id
      AND ad_id = p_ad_id
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
      p_product_id,
      p_ad_id,
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
      LIMIT 1;
    END IF;

    IF v_conv_id IS NULL AND p_product_id IS NOT NULL THEN
      SELECT id INTO v_conv_id
      FROM public.conversations
      WHERE buyer_id = p_buyer_id
        AND seller_id = p_seller_id
        AND product_id = p_product_id
        AND (p_order_id IS NULL OR order_id IS NULL)
      LIMIT 1;
    ELSIF v_conv_id IS NULL AND p_ad_id IS NOT NULL THEN
      SELECT id INTO v_conv_id
      FROM public.conversations
      WHERE buyer_id = p_buyer_id
        AND seller_id = p_seller_id
        AND ad_id = p_ad_id
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


-- ----------------------------------------------------------------------------
-- 4. check_phone_exists: anti-enumeration zaštita (kao check_email_exists)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.check_phone_exists(p_phone TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_trimmed TEXT;
  v_allowed BOOLEAN;
BEGIN
  IF p_phone IS NULL THEN
    RETURN false;
  END IF;

  v_trimmed := trim(p_phone);

  -- Broj telefona mora imati barem 6 karaktera
  IF length(v_trimmed) < 6 THEN
    RETURN false;
  END IF;

  -- Provera rate limita: maks 10 provera u 5 minuta (300s)
  v_allowed := public.check_and_record_auth_rate_limit('check_phone_exists', 10, 300);
  IF NOT v_allowed THEN
    RAISE EXCEPTION 'Prekoračen dozvoljeni broj provera. Molimo sačekajte nekoliko minuta.'
      USING ERRCODE = 'P0001';
  END IF;

  IF public.is_admin() THEN
    RETURN EXISTS (
      SELECT 1 FROM public.profiles WHERE phone = v_trimmed
    );
  END IF;

  RETURN false;
END;
$$;

REVOKE ALL ON FUNCTION public.check_phone_exists(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.check_phone_exists(TEXT) TO anon, authenticated, service_role;


-- ----------------------------------------------------------------------------
-- 5. check_push_configuration: admin-only provera i REVOKE od PUBLIC/anon
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.check_push_configuration()
RETURNS TABLE (
  checked_at TIMESTAMPTZ,
  edge_config_ok BOOLEAN,
  functions_base_url TEXT,
  anon_key_present BOOLEAN,
  total_tokens BIGINT,
  users_with_tokens BIGINT,
  tokens_created_24h BIGINT,
  notifications_24h BIGINT,
  deliveries_24h BIGINT,
  successful_deliveries_24h BIGINT,
  failed_deliveries_24h BIGINT,
  delivery_success_rate NUMERIC,
  last_notification_at TIMESTAMPTZ,
  last_delivery_at TIMESTAMPTZ,
  overall_status TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_base_url TEXT;
  v_service_key TEXT;
  v_anon_key TEXT;
BEGIN
  IF current_user IN ('anon', 'authenticated') AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Pristup odbijen: samo administrator može proveriti push konfiguraciju.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  -- Čitanje iz Supabase Vault-a
  BEGIN
    SELECT decrypted_secret INTO v_base_url FROM vault.decrypted_secrets WHERE name = 'functions_base_url' LIMIT 1;
  EXCEPTION WHEN OTHERS THEN v_base_url := NULL;
  END;

  BEGIN
    SELECT decrypted_secret INTO v_service_key FROM vault.decrypted_secrets WHERE name = 'service_role_key' LIMIT 1;
  EXCEPTION WHEN OTHERS THEN v_service_key := NULL;
  END;

  BEGIN
    SELECT decrypted_secret INTO v_anon_key FROM vault.decrypted_secrets WHERE name = 'anon_key' LIMIT 1;
  EXCEPTION WHEN OTHERS THEN v_anon_key := NULL;
  END;

  -- Non-sensitive fallback samo za functions_base_url
  IF v_base_url IS NULL OR v_base_url = '' THEN
    SELECT value INTO v_base_url FROM public.edge_config WHERE key = 'functions_base_url' LIMIT 1;
  END IF;

  RETURN QUERY
  WITH token_stats AS (
    SELECT
      COUNT(*) AS total_tokens,
      COUNT(DISTINCT user_id) AS users_with_tokens,
      COUNT(*) FILTER (WHERE user_push_tokens.created_at > NOW() - INTERVAL '24 hours') AS tokens_created_24h
    FROM public.user_push_tokens
  ),
  notification_stats AS (
    SELECT
      COUNT(*) FILTER (WHERE notifications.created_at > NOW() - INTERVAL '24 hours') AS notifications_24h,
      MAX(notifications.created_at) AS last_notification_at
    FROM public.notifications
  ),
  delivery_stats AS (
    SELECT
      COUNT(*) FILTER (WHERE push_delivery_logs.created_at > NOW() - INTERVAL '24 hours') AS deliveries_24h,
      COUNT(*) FILTER (
        WHERE push_delivery_logs.created_at > NOW() - INTERVAL '24 hours'
          AND status = 'success'
      ) AS successful_deliveries_24h,
      COUNT(*) FILTER (
        WHERE push_delivery_logs.created_at > NOW() - INTERVAL '24 hours'
          AND status IN ('error', 'partial', 'no_tokens', 'invalid_request')
      ) AS failed_deliveries_24h,
      MAX(push_delivery_logs.created_at) AS last_delivery_at
    FROM public.push_delivery_logs
  ),
  summary AS (
    SELECT
      NOW() AS checked_at,
      (v_base_url IS NOT NULL AND v_base_url <> ''
        AND ((v_service_key IS NOT NULL AND v_service_key <> '') OR (v_anon_key IS NOT NULL AND v_anon_key <> ''))) AS edge_config_ok,
      v_base_url AS functions_base_url,
      ((v_service_key IS NOT NULL AND v_service_key <> '') OR (v_anon_key IS NOT NULL AND v_anon_key <> '' )) AS anon_key_present,
      token_stats.total_tokens,
      token_stats.users_with_tokens,
      token_stats.tokens_created_24h,
      notification_stats.notifications_24h,
      delivery_stats.deliveries_24h,
      delivery_stats.successful_deliveries_24h,
      delivery_stats.failed_deliveries_24h,
      ROUND(
        CASE
          WHEN delivery_stats.deliveries_24h = 0 THEN 0
          ELSE (delivery_stats.successful_deliveries_24h::NUMERIC / delivery_stats.deliveries_24h::NUMERIC) * 100
        END,
        2
      ) AS delivery_success_rate,
      notification_stats.last_notification_at,
      delivery_stats.last_delivery_at
    FROM token_stats, notification_stats, delivery_stats
  )
  SELECT
    summary.checked_at,
    summary.edge_config_ok,
    summary.functions_base_url,
    summary.anon_key_present,
    summary.total_tokens,
    summary.users_with_tokens,
    summary.tokens_created_24h,
    summary.notifications_24h,
    summary.deliveries_24h,
    summary.successful_deliveries_24h,
    summary.failed_deliveries_24h,
    summary.delivery_success_rate,
    summary.last_notification_at,
    summary.last_delivery_at,
    CASE
      WHEN NOT summary.edge_config_ok THEN 'misconfigured'
      WHEN summary.total_tokens = 0 THEN 'no_tokens'
      WHEN summary.deliveries_24h > 0 AND summary.delivery_success_rate < 50 THEN 'degraded'
      ELSE 'healthy'
    END AS overall_status
  FROM summary;
END;
$$;

REVOKE ALL ON FUNCTION public.check_push_configuration() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.check_push_configuration() TO authenticated, service_role;


-- ----------------------------------------------------------------------------
-- 6. Revoke preširoke EXECUTE privilegije sa admin/internih/cron funkcija
-- ----------------------------------------------------------------------------
REVOKE ALL ON FUNCTION public.admin_set_seller_verified(UUID, BOOLEAN) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_set_seller_verified(UUID, BOOLEAN) TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.cleanup_push_tokens(INT, INTERVAL) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cleanup_push_tokens(INT, INTERVAL) TO service_role;

REVOKE ALL ON FUNCTION public.adjust_product_order_summary(UUID, BIGINT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.adjust_product_order_summary(UUID, BIGINT) TO service_role;

REVOKE ALL ON FUNCTION public.recompute_product_review_summary(UUID) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.recompute_product_review_summary(UUID) TO service_role;

REVOKE ALL ON FUNCTION public.handle_order_retention() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.handle_order_retention() TO service_role;

REVOKE ALL ON FUNCTION public.archive_and_expire_orders() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.archive_and_expire_orders() TO service_role;

REVOKE ALL ON FUNCTION public.cleanup_stale_conversation_typing() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cleanup_stale_conversation_typing() TO service_role;


-- ----------------------------------------------------------------------------
-- 7. send_push_notification: transaction-local set_config (is_local := true)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.send_push_notification(
  p_user_id         uuid,
  p_title           text,
  p_body            text,
  p_type            text,
  p_order_id        text  DEFAULT ''::text,
  p_ticket_id       text  DEFAULT ''::text,
  p_conversation_id text  DEFAULT ''::text,
  p_data            jsonb DEFAULT '{}'::jsonb
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  base_url    TEXT;
  service_key TEXT;
  fn_url      TEXT;
BEGIN
  IF p_user_id IS NULL THEN
    RETURN false;
  END IF;

  -- 1. Čitanje iz transaction-local GUC keša (bez curenja u PgBouncer sesiju)
  service_key := NULLIF(current_setting('app.settings.service_role_key', true), '');
  base_url    := NULLIF(current_setting('app.settings.functions_base_url', true), '');

  -- 2. Ako service_key nije keširan u ovoj transakciji, pročitaj iz Vault-a
  IF service_key IS NULL THEN
    BEGIN
      SELECT decrypted_secret INTO service_key
      FROM vault.decrypted_secrets
      WHERE name = 'service_role_key'
      LIMIT 1;

      IF service_key IS NOT NULL AND service_key <> '' THEN
        PERFORM set_config('app.settings.service_role_key', service_key, true);
      END IF;
    EXCEPTION WHEN OTHERS THEN
      service_key := NULL;
    END;
  END IF;

  -- 3. Ako base_url nije keširan u ovoj transakciji, čitaj edge_config pa Vault fallback
  IF base_url IS NULL THEN
    SELECT value INTO base_url FROM public.edge_config WHERE key = 'functions_base_url' LIMIT 1;

    IF base_url IS NULL OR base_url = '' THEN
      BEGIN
        SELECT decrypted_secret INTO base_url
        FROM vault.decrypted_secrets
        WHERE name = 'functions_base_url'
        LIMIT 1;
      EXCEPTION WHEN OTHERS THEN
        base_url := NULL;
      END;
    END IF;

    IF base_url IS NOT NULL AND base_url <> '' THEN
      PERFORM set_config('app.settings.functions_base_url', base_url, true);
    END IF;
  END IF;

  IF service_key IS NULL OR service_key = '' OR base_url IS NULL OR base_url = '' THEN
    RAISE WARNING 'send_push_notification: Nedostaje konfiguracija (Vault service_role_key ili URL).';
    RETURN false;
  END IF;

  fn_url := base_url || '/functions/v1/send-push';

  PERFORM net.http_post(
    url := fn_url,
    body := jsonb_build_object(
      'user_id', p_user_id,
      'title', COALESCE(p_title, ''),
      'body', COALESCE(p_body, ''),
      'type', COALESCE(p_type, ''),
      'order_id', COALESCE(p_order_id, ''),
      'ticket_id', COALESCE(p_ticket_id, ''),
      'conversation_id', COALESCE(p_conversation_id, ''),
      'data', COALESCE(p_data, '{}'::jsonb)
    ),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || service_key,
      'apikey', service_key
    ),
    timeout_milliseconds := 5000
  );

  RETURN true;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'send_push_notification greška: %', SQLERRM;
  RETURN false;
END;
$$;

REVOKE ALL ON FUNCTION public.send_push_notification(UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.send_push_notification(UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, JSONB) TO service_role;


-- ----------------------------------------------------------------------------
-- 8. v_classified_categories: security_invoker = true i SELECT-only prava
-- ----------------------------------------------------------------------------
ALTER VIEW public.v_classified_categories SET (security_invoker = true);
REVOKE ALL ON public.v_classified_categories FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.v_classified_categories TO anon, authenticated, service_role;

