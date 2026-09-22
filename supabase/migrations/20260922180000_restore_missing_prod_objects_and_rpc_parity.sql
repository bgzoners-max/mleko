-- ============================================================================
-- Migracija: Usaglašavanje šeme sa produkcijom, konsolidacija RPC-a i sanacija
-- Datum: 2026-09-22
-- Opis:
--   1. Dodavanje nedostajućih kolona (orders.buyer_postal_code, status_changed_at,
--      notifications.metadata).
--   2. Trigeri za orders.status_changed_at (set_order_status_changed_at).
--   3. Tabela public.waitlist sa RLS politikama (uključujući admin pristup).
--   4. auth.users trigger (handle_new_user) za automatsko kreiranje profila.
--   5. Konsolidacija create_order_with_items na tačno 12 parametara (sa
--      p_buyer_postal_code i svim striktnim proverama, brisanje 11-arg overload-a).
--   6. Ispravka handle_order_retention (korišćenje status = 'archived').
--   7. Uklanjanje neispravnog auto-archive cron posla i funkcije.
--   8. Čišćenje legacy trigera nad product_stats i uklanjanje napuštenih tabela.
--   9. get_seller_popular_products i ostale pomoćne funkcije.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Nedostajuće kolone
-- ----------------------------------------------------------------------------
ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS buyer_postal_code TEXT,
  ADD COLUMN IF NOT EXISTS status_changed_at TIMESTAMPTZ;

ALTER TABLE public.notifications
  ADD COLUMN IF NOT EXISTS metadata JSONB NOT NULL DEFAULT '{}'::jsonb;

-- ----------------------------------------------------------------------------
-- 2. Trigeri za orders.status_changed_at
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_order_status_changed_at()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    NEW.status_changed_at := now();
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.set_order_status_changed_at_on_insert()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  NEW.status_changed_at := COALESCE(NEW.created_at, now());
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_set_order_status_changed_at ON public.orders;
CREATE TRIGGER trg_set_order_status_changed_at
  BEFORE UPDATE ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.set_order_status_changed_at();

DROP TRIGGER IF EXISTS trg_set_order_status_changed_at_insert ON public.orders;
CREATE TRIGGER trg_set_order_status_changed_at_insert
  BEFORE INSERT ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.set_order_status_changed_at_on_insert();

-- ----------------------------------------------------------------------------
-- 3. Tabela public.waitlist i RLS politike
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.waitlist (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.waitlist ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'waitlist' AND policyname = 'Anyone can join waitlist'
  ) THEN
    CREATE POLICY "Anyone can join waitlist"
      ON public.waitlist FOR INSERT TO public
      WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'waitlist' AND policyname = 'Admins can view waitlist'
  ) THEN
    CREATE POLICY "Admins can view waitlist"
      ON public.waitlist FOR SELECT TO authenticated
      USING ((SELECT public.is_admin()));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'waitlist' AND policyname = 'Admins can delete from waitlist'
  ) THEN
    CREATE POLICY "Admins can delete from waitlist"
      ON public.waitlist FOR DELETE TO authenticated
      USING ((SELECT public.is_admin()));
  END IF;
END $$;

GRANT INSERT ON public.waitlist TO anon, authenticated;
GRANT SELECT, DELETE ON public.waitlist TO authenticated;

-- ----------------------------------------------------------------------------
-- 4. auth.users triger: handle_new_user()
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (
    id, email, display_name, phone, city, role, farm_name, location, is_guest
  )
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'display_name',
    NEW.raw_user_meta_data->>'phone',
    NEW.raw_user_meta_data->>'city',
    COALESCE(NEW.raw_user_meta_data->>'role', 'buyer'),
    NEW.raw_user_meta_data->>'farm_name',
    NEW.raw_user_meta_data->>'location',
    COALESCE((NEW.raw_app_meta_data->>'is_anonymous')::boolean, false)
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    display_name = COALESCE(EXCLUDED.display_name, profiles.display_name),
    phone = COALESCE(EXCLUDED.phone, profiles.phone),
    city = COALESCE(EXCLUDED.city, profiles.city),
    role = EXCLUDED.role,
    farm_name = COALESCE(EXCLUDED.farm_name, profiles.farm_name),
    location = COALESCE(EXCLUDED.location, profiles.location),
    updated_at = NOW();
  RETURN NEW;
END;
$$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'auth') AND
     EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = 'auth' AND c.relname = 'users') THEN
    DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
    CREATE TRIGGER on_auth_user_created
      AFTER INSERT ON auth.users
      FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
  END IF;
END $$;

-- ----------------------------------------------------------------------------
-- 5. handle_new_order_notification() i triger na orders
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_order_notification()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_buyer_name TEXT;
BEGIN
  SELECT COALESCE(display_name, 'Kupac') INTO v_buyer_name
  FROM public.profiles
  WHERE id = NEW.buyer_id;

  INSERT INTO public.notifications (
    user_id,
    type,
    title,
    body,
    order_id
  )
  VALUES (
    NEW.seller_id,
    'new_order',
    'Nova porudžbina 🛒',
    v_buyer_name || ' vam je upravo poslao novu porudžbinu.',
    NEW.id
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_new_order_notify_seller ON public.orders;
CREATE TRIGGER on_new_order_notify_seller
  AFTER INSERT ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_order_notification();

-- ----------------------------------------------------------------------------
-- 6. set_support_ticket_updated_at() i triger na support_tickets
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_support_ticket_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_support_tickets_updated_at ON public.support_tickets;
CREATE TRIGGER trg_support_tickets_updated_at
  BEFORE UPDATE ON public.support_tickets
  FOR EACH ROW
  EXECUTE FUNCTION public.set_support_ticket_updated_at();

-- ----------------------------------------------------------------------------
-- 7. get_seller_popular_products()
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_seller_popular_products(
  p_seller_id UUID,
  p_limit INTEGER DEFAULT 5
)
RETURNS TABLE(product JSONB, sales_count INTEGER)
LANGUAGE sql
STABLE
SET search_path TO ''
AS $$
  WITH base_orders AS (
    SELECT id, product_id
    FROM public.orders
    WHERE seller_id = p_seller_id
      AND status IN ('accepted', 'delivered')
  ),
  all_product_ids AS (
    SELECT product_id
    FROM base_orders
    WHERE product_id IS NOT NULL
    UNION ALL
    SELECT oi.product_id
    FROM public.order_items oi
    JOIN base_orders o ON o.id = oi.order_id
  ),
  product_counts AS (
    SELECT
      product_id,
      COUNT(*)::INTEGER AS sales_count
    FROM all_product_ids
    GROUP BY product_id
  ),
  top_products AS (
    SELECT
      pc.product_id,
      pc.sales_count
    FROM product_counts pc
    ORDER BY pc.sales_count DESC
    LIMIT GREATEST(p_limit, 1)
  )
  SELECT
    to_jsonb(p.*) AS product,
    tp.sales_count
  FROM top_products tp
  JOIN public.products p ON p.id = tp.product_id;
$$;

GRANT EXECUTE ON FUNCTION public.get_seller_popular_products(UUID, INTEGER) TO authenticated, anon;

-- ----------------------------------------------------------------------------
-- 8. Konsolidacija RPC funkcije create_order_with_items (12 parametara)
--    Uklanjamo stari 11-arg potpis i zamenjujemo 12-arg implementaciju striktnom.
-- ----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.create_order_with_items(
  UUID, UUID, TEXT, JSONB, TEXT, TEXT, TEXT, TEXT, UUID, UUID, NUMERIC
);

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

    v_step := v_product.order_step::NUMERIC;

    v_delta := v_item_quantity - v_product.min_order_kg;

    IF abs(v_delta - (ROUND(v_delta / v_step) * v_step)) > 0.000001 THEN
      RAISE EXCEPTION 'quantity for % must align with order step %', v_product.name, v_step;
    END IF;

    -- Cena se striktno uzima iz baze, a ne iz klijentskog inputa
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

GRANT EXECUTE ON FUNCTION public.create_order_with_items(
  UUID, UUID, TEXT, JSONB, TEXT, TEXT, TEXT, TEXT, TEXT, UUID, UUID, NUMERIC
) TO authenticated;

-- ----------------------------------------------------------------------------
-- 9. Ispravka handle_order_retention() (status = 'archived')
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_order_retention()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Uskladi sumarni brojač pre nego što redovi orders budu obrisani
  UPDATE public.product_order_summary s
  SET order_count = s.order_count - 1
  FROM (
    SELECT DISTINCT oi.product_id
    FROM public.order_items oi
    JOIN public.orders o ON o.id = oi.order_id
    WHERE o.expires_at IS NOT NULL AND o.expires_at <= now()
      AND o.status IN ('accepted', 'delivered')
  ) x
  WHERE s.product_id = x.product_id;

  DELETE FROM public.product_order_summary s WHERE s.order_count <= 0;

  -- Brisanje: arhivirane porudžbine kojima je istekao expires_at (order_items padaju CASCADE)
  DELETE FROM public.orders
  WHERE status = 'archived'
    AND expires_at IS NOT NULL
    AND expires_at <= now();
END;
$$;

-- ----------------------------------------------------------------------------
-- 10. Uklanjanje neispravnog cron posla auto-archive-stale-orders-5-days
-- ----------------------------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    PERFORM cron.unschedule('auto-archive-stale-orders-5-days')
    WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'auto-archive-stale-orders-5-days');
  END IF;
EXCEPTION WHEN OTHERS THEN
  NULL;
END $$;

DROP FUNCTION IF EXISTS public.auto_archive_stale_orders_5_days();

-- ----------------------------------------------------------------------------
-- 11. Čišćenje legacy trigera i napuštenih tabela
-- ----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_orders_refresh_product_stats ON public.orders;
DROP TRIGGER IF EXISTS trg_orders_before_delete_refresh_product_stats ON public.orders;
DROP TRIGGER IF EXISTS trg_order_items_refresh_product_stats ON public.order_items;
DROP TRIGGER IF EXISTS trg_reviews_refresh_product_stats ON public.reviews;

DROP FUNCTION IF EXISTS public.trg_refresh_product_stats_on_order_after() CASCADE;
DROP FUNCTION IF EXISTS public.trg_refresh_product_stats_on_order_before_delete() CASCADE;
DROP FUNCTION IF EXISTS public.trg_refresh_product_stats_on_order_item() CASCADE;
DROP FUNCTION IF EXISTS public.trg_refresh_product_stats_on_review() CASCADE;
DROP FUNCTION IF EXISTS public.refresh_product_stats(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.refresh_all_product_stats() CASCADE;

DROP TABLE IF EXISTS public.product_stats CASCADE;
DROP TABLE IF EXISTS public.push_logs CASCADE;
DROP TABLE IF EXISTS public.conversation_user_settings CASCADE;
DROP TABLE IF EXISTS public.message_retention_notice_log CASCADE;
DROP FUNCTION IF EXISTS public.run_message_retention_maintenance() CASCADE;
