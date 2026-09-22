-- Integration checks for create_order_with_items RPC parity & schema guards.
-- Run with: psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f supabase/tests/create_order_rpc_integration.sql

BEGIN;

-- 1. Provera kolona u orders i notifications tabelama
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'orders' AND column_name = 'buyer_postal_code'
  ) THEN
    RAISE EXCEPTION 'orders.buyer_postal_code column missing';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'orders' AND column_name = 'status_changed_at'
  ) THEN
    RAISE EXCEPTION 'orders.status_changed_at column missing';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'notifications' AND column_name = 'metadata'
  ) THEN
    RAISE EXCEPTION 'notifications.metadata column missing';
  END IF;
END $$;

-- 2. Provera tabele waitlist i RLS politika
DO $$
BEGIN
  IF to_regclass('public.waitlist') IS NULL THEN
    RAISE EXCEPTION 'waitlist table missing';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'waitlist' AND policyname = 'Anyone can join waitlist'
  ) THEN
    RAISE EXCEPTION 'waitlist INSERT policy missing';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'waitlist' AND policyname = 'Admins can view waitlist'
  ) THEN
    RAISE EXCEPTION 'waitlist SELECT policy for admins missing';
  END IF;
END $$;

-- 3. Provera da rogue cron i auto-archive funkcija NE postoje
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc WHERE proname = 'auto_archive_stale_orders_5_days'
  ) THEN
    RAISE EXCEPTION 'auto_archive_stale_orders_5_days function must be dropped';
  END IF;

  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    IF EXISTS (
      SELECT 1 FROM cron.job WHERE jobname = 'auto-archive-stale-orders-5-days'
    ) THEN
      RAISE EXCEPTION 'auto-archive-stale-orders-5-days cron job must be unscheduled';
    END IF;
  END IF;
END $$;

-- 4. Provera da create_order_with_items ima TAČNO JEDNU definiciju sa 12 argumenata
DO $$
DECLARE
  v_count INTEGER;
  v_args TEXT;
BEGIN
  SELECT count(*) INTO v_count
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public' AND p.proname = 'create_order_with_items';

  IF v_count <> 1 THEN
    RAISE EXCEPTION 'create_order_with_items must have exactly 1 definition, found %', v_count;
  END IF;

  SELECT pg_get_function_identity_arguments(p.oid) INTO v_args
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public' AND p.proname = 'create_order_with_items';

  IF v_args NOT LIKE '%p_buyer_postal_code%' THEN
    RAISE EXCEPTION 'create_order_with_items signature must include p_buyer_postal_code';
  END IF;
END $$;

-- 5. Funkcionalni test RPC poziva sa parametrima koje klijent šalje
DO $$
DECLARE
  v_buyer_id UUID := gen_random_uuid();
  v_seller_id UUID := gen_random_uuid();
  v_product_id UUID := gen_random_uuid();
  v_order_id UUID;
  v_saved_postal TEXT;
  v_saved_total NUMERIC;
  v_items JSONB;
BEGIN
  -- Privremeni korisnici u auth.users (triger on_auth_user_created automatski popunjava profiles)
  INSERT INTO auth.users (id, email, raw_user_meta_data)
  VALUES
    (v_buyer_id, 'test_buyer@mleko.rs', jsonb_build_object('display_name', 'Test Kupac', 'phone', '0601234567', 'role', 'buyer')),
    (v_seller_id, 'test_seller@mleko.rs', jsonb_build_object('display_name', 'Test Prodavac', 'phone', '0607654321', 'role', 'seller'));

  -- Ažuriraj telefone u profiles u slučaju da trigger koristi specifičan format
  UPDATE public.profiles SET phone = '0601234567' WHERE id = v_buyer_id;
  UPDATE public.profiles SET phone = '0607654321' WHERE id = v_seller_id;

  -- Privremeni proizvod (cena 500 RSD, korak 0.5, min 1)
  INSERT INTO public.products (
    id, seller_id, name, category, unit_type, min_order_kg, order_step,
    price_per_kg, available_now, available_kg, location
  )
  VALUES (
    v_product_id, v_seller_id, 'Domaće Mleko', 'Mlečni proizvodi', 'L', 1.0, 0.5,
    500, true, 100, 'Beograd'
  );

  -- Simuliraj autentifikovanog kupca
  PERFORM set_config('request.jwt.claim.sub', v_buyer_id::text, true);
  PERFORM set_config('role', 'authenticated', true);

  -- Klijent šalje p_items sa lažnom niskom cenom (10 RSD) – baza MORA ignorisati ovo i uzeti 500 RSD
  v_items := jsonb_build_array(
    jsonb_build_object(
      'product_id', v_product_id,
      'quantity_kg', 2.0,
      'unit_price', 10,
      'unit_type', 'L'
    )
  );

  -- Poziv kanonskog RPC-a sa tačnim parametrima
  v_order_id := public.create_order_with_items(
    p_buyer_id := v_buyer_id,
    p_seller_id := v_seller_id,
    p_buyer_phone := '0601234567',
    p_items := v_items,
    p_note := 'Test porudžbina',
    p_buyer_city := 'Beograd',
    p_buyer_address := 'Knez Mihailova 1',
    p_buyer_postal_code := '11000',
    p_delivery_method := 'courier',
    p_delivery_point_id := NULL,
    p_delivery_slot_id := NULL,
    p_delivery_fee_rsd := NULL
  );

  IF v_order_id IS NULL THEN
    RAISE EXCEPTION 'create_order_with_items returned NULL order_id';
  END IF;

  SELECT buyer_postal_code, total_amount
  INTO v_saved_postal, v_saved_total
  FROM public.orders
  WHERE id = v_order_id;

  IF v_saved_postal <> '11000' THEN
    RAISE EXCEPTION 'buyer_postal_code was not saved properly: expected 11000, got %', v_saved_postal;
  END IF;

  -- 2.0 L * 500 RSD = 1000 RSD (klijentska lažna cena 10 RSD mora biti ignorisana)
  IF v_saved_total <> 1000 THEN
    RAISE EXCEPTION 'total_amount security check failed: expected 1000 RSD from DB price, got % RSD', v_saved_total;
  END IF;

  -- 6. Provera da RPC odbija nevalidan korak
  BEGIN
    PERFORM public.create_order_with_items(
      p_buyer_id := v_buyer_id,
      p_seller_id := v_seller_id,
      p_buyer_phone := '0601234567',
      p_items := jsonb_build_array(
        jsonb_build_object(
          'product_id', v_product_id,
          'quantity_kg', 1.3,
          'unit_type', 'L'
        )
      ),
      p_buyer_postal_code := '11000'
    );
    RAISE EXCEPTION 'RPC should have rejected unaligned order_step (1.3 with step 0.5)';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM LIKE '%order step%' THEN
      -- Očekivano ponašanje
      NULL;
    ELSE
      RAISE;
    END IF;
  END;

  -- 7. Provera da RPC odbija nedostupan proizvod
  PERFORM set_config('role', 'postgres', true);
  UPDATE public.products SET available_now = false WHERE id = v_product_id;
  PERFORM set_config('role', 'authenticated', true);

  BEGIN
    PERFORM public.create_order_with_items(
      p_buyer_id := v_buyer_id,
      p_seller_id := v_seller_id,
      p_buyer_phone := '0601234567',
      p_items := jsonb_build_array(
        jsonb_build_object(
          'product_id', v_product_id,
          'quantity_kg', 1.5,
          'unit_type', 'L'
        )
      ),
      p_buyer_postal_code := '11000'
    );
    RAISE EXCEPTION 'RPC should have rejected unavailable product';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM LIKE '%currently unavailable%' THEN
      -- Očekivano ponašanje
      NULL;
    ELSE
      RAISE;
    END IF;
  END;
END $$;

ROLLBACK;
