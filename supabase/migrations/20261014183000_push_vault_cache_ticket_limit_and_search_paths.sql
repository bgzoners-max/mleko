-- ============================================================================
-- Migracija 20261014183000:
-- 1. Keširanje Vault tajni u send_push_notification preko sesijskih GUC promenljivih
-- 2. Konfigurabilan limit poruka po tiketu preko public.edge_config tabele
-- 3. Eksplicitno definisan search_path = public za validate_product_delivery_point_same_seller i get_conversation_info_with_profile
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. send_push_notification sa GUC sesijskim keširanjem Vault tajni
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

  -- 1. Čitanje iz sesijskog GUC keša (sub-mikrosekundna pretraga)
  service_key := NULLIF(current_setting('app.settings.service_role_key', true), '');
  base_url    := NULLIF(current_setting('app.settings.functions_base_url', true), '');

  -- 2. Ako service_key nije keširan, pročitaj iz Supabase Vault-a i keširaj za trajanje sesije
  IF service_key IS NULL THEN
    BEGIN
      SELECT decrypted_secret INTO service_key 
      FROM vault.decrypted_secrets 
      WHERE name = 'service_role_key' 
      LIMIT 1;

      IF service_key IS NOT NULL AND service_key <> '' THEN
        PERFORM set_config('app.settings.service_role_key', service_key, false);
      END IF;
    EXCEPTION WHEN OTHERS THEN
      service_key := NULL;
    END;
  END IF;

  -- 3. Ako base_url nije keširan, prvo pročitaj iz non-secret edge_config, pa Vault kao fallback
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
      PERFORM set_config('app.settings.functions_base_url', base_url, false);
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
-- 2. Konfigurabilan limit poruka po tiketu u edge_config
-- ----------------------------------------------------------------------------
INSERT INTO public.edge_config (key, value)
VALUES ('ticket_max_messages_per_role', '5')
ON CONFLICT (key) DO NOTHING;

CREATE OR REPLACE FUNCTION public.check_ticket_message_limit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  msg_count integer;
  max_limit integer := 5;
  cfg_val   text;
BEGIN
  SELECT value INTO cfg_val FROM public.edge_config WHERE key = 'ticket_max_messages_per_role' LIMIT 1;
  IF cfg_val ~ '^[0-9]+$' THEN
    max_limit := cfg_val::integer;
  END IF;

  SELECT COUNT(*) INTO msg_count
  FROM public.support_ticket_messages
  WHERE ticket_id = NEW.ticket_id AND sender_role = NEW.sender_role;

  IF msg_count >= max_limit THEN
    RAISE EXCEPTION 'Dostignut je maksimalan broj poruka (%) za ovu stranu.', max_limit;
  END IF;

  RETURN NEW;
END;
$$;

-- ----------------------------------------------------------------------------
-- 3. SET search_path = public za SECURITY INVOKER RPC i triger funkcije
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.validate_product_delivery_point_same_seller()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
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
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id::text,
    c.buyer_id::text,
    c.seller_id::text,
    c.order_id::text,
    COALESCE(pb.farm_name, pb.display_name, 'Kupac')::text AS buyer_name,
    COALESCE(ps.farm_name, ps.display_name, 'Prodavac')::text AS seller_name,
    c.product_id::text,
    c.ad_id::text,
    COALESCE(
      p.name,
      ad.title,
      (SELECT oi.product_name FROM public.order_items oi WHERE oi.order_id = c.order_id LIMIT 1),
      (SELECT o.product_name FROM public.orders o WHERE o.id = c.order_id)
    )::text AS item_title,
    COALESCE(p.image_urls[1], ad.images[1])::text AS item_image_url,
    COALESCE(p.price_per_kg, ad.price)::numeric AS item_price,
    COALESCE(p.unit_type, ad.currency)::text AS item_unit,
    CASE
      WHEN c.product_id IS NOT NULL THEN 'product'
      WHEN c.ad_id IS NOT NULL THEN 'ad'
      WHEN c.order_id IS NOT NULL THEN 'order'
      ELSE NULL
    END::text AS item_type
  FROM public.conversations c
  LEFT JOIN public.profiles pb ON c.buyer_id = pb.id
  LEFT JOIN public.profiles ps ON c.seller_id = ps.id
  LEFT JOIN public.products p ON c.product_id = p.id
  LEFT JOIN public.classified_ads ad ON c.ad_id = ad.id
  WHERE c.id::text = p_conversation_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_conversation_info_with_profile(TEXT) TO authenticated;
