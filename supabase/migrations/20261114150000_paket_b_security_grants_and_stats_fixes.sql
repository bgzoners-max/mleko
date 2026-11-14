-- ============================================================================
-- Migracija: 20261114150000_paket_b_security_grants_and_stats_fixes.sql
-- Paket B — Baza podataka, RLS bezbednost i tačnost statistika:
--   1. public_classified_ads: maskiranje telefona za ne-vlasnike (sprečava
--      zaobilaženje rate-limitovane get_classified_ad_phone RPC funkcije),
--      (SELECT auth.uid()) InitPlan optimizacija i dopuna novijim kolonama.
--   2. profiles: kolonski GRANT SELECT za legal_type, pib i
--      legal_liability_accepted_at (bpg ostaje zaštićen).
--   3. get_seller_popular_products i get_seller_response_time_stats:
--      SECURITY DEFINER SET search_path = public, uključenje 'shipped',
--      'archived' i 'arhivirano' statusa, i uklanjanje search_vector iz JSONB-a.
--   4. get_seller_stats, get_buyer_stats_dashboard, get_seller_stats_dashboard
--      i get_reviewable_order: uključenje 'archived'/'arhivirano' porudžbina i
--      korišćenje zamrznutih cena (total_amount / total_price) pri obračunu.
--   5. get_seller_inbox LATERAL konsolidacija (1 prolaz kroz order_items umesto 6),
--      parcijalni indeks za nepročitane poruke, rate-limit i GUC propusnica za
--      analitiku oglasa, FORCE RLS na waitlist i ispravka 4 ćirilična unosa u
--      postal_codes.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. public.public_classified_ads: maskiranje telefona i dopuna kolona
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.public_classified_ads AS
SELECT
  ca.id,
  ca.user_id,
  ca.title,
  ca.description,
  ca.price,
  ca.currency,
  ca.price_type,
  ca.category_id,
  ca.condition,
  ca.images,
  ca.city,
  CASE
    WHEN (
      (SELECT auth.uid()) = ca.user_id
      OR (SELECT public.is_admin())
    )
    THEN ca.phone
    ELSE NULL
  END AS phone,
  ca.phone_public,
  ca.status,
  ca.views_count,
  ca.created_at,
  ca.updated_at,
  ca.last_view_at,
  ca.attributes,
  ca.is_featured,
  ca.featured_until,
  ca.is_urgent,
  ca.reports_count,
  ca.call_clicks_count,
  ca.shares_count,
  ca.seller_type
FROM public.classified_ads ca
WHERE ca.status = 'active'
   OR (SELECT auth.uid()) = ca.user_id
   OR (SELECT public.is_admin());

ALTER VIEW public.public_classified_ads SET (security_invoker = false);
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.public_classified_ads FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.public_classified_ads TO anon, authenticated;


-- ----------------------------------------------------------------------------
-- 2. public.profiles: kolonski GRANT SELECT za javne pravne kolone (bez bpg)
-- ----------------------------------------------------------------------------
GRANT SELECT (
  legal_type,
  pib,
  legal_liability_accepted_at
) ON public.profiles TO anon, authenticated;


-- ----------------------------------------------------------------------------
-- 3. get_seller_popular_products & get_seller_response_time_stats
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_seller_popular_products(
  p_seller_id UUID,
  p_limit INTEGER DEFAULT 5
)
RETURNS TABLE(product JSONB, sales_count INTEGER)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH base_orders AS (
    SELECT id, product_id
    FROM public.orders
    WHERE seller_id = p_seller_id
      AND status IN ('accepted', 'shipped', 'delivered', 'archived', 'arhivirano')
  ),
  all_product_ids AS (
    SELECT product_id
    FROM base_orders
    WHERE product_id IS NOT NULL
    UNION ALL
    SELECT oi.product_id
    FROM public.order_items oi
    JOIN base_orders o ON o.id = oi.order_id
    WHERE oi.product_id IS NOT NULL
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
    LIMIT GREATEST(COALESCE(p_limit, 5), 1)
  )
  SELECT
    (to_jsonb(p.*) - 'search_vector') AS product,
    tp.sales_count
  FROM top_products tp
  JOIN public.products p ON p.id = tp.product_id;
$$;

REVOKE ALL ON FUNCTION public.get_seller_popular_products(UUID, INTEGER) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_seller_popular_products(UUID, INTEGER) TO anon, authenticated, service_role;


CREATE OR REPLACE FUNCTION public.get_seller_response_time_stats(p_seller_id UUID)
RETURNS TABLE (
  sample_count INTEGER,
  avg_response_minutes NUMERIC,
  median_response_minutes NUMERIC,
  last_response_minutes NUMERIC
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH buyer_messages AS (
    SELECT
      m.id,
      m.conversation_id,
      m.created_at
    FROM public.messages m
    JOIN public.conversations c ON c.id = m.conversation_id
    WHERE c.seller_id = p_seller_id
      AND m.sender_id = c.buyer_id
  ),
  first_replies AS (
    SELECT
      bm.id AS buyer_message_id,
      bm.created_at AS buyer_created_at,
      (
        SELECT m2.created_at
        FROM public.messages m2
        WHERE m2.conversation_id = bm.conversation_id
          AND m2.created_at > bm.created_at
          AND m2.sender_id = p_seller_id
        ORDER BY m2.created_at ASC
        LIMIT 1
      ) AS seller_reply_at
    FROM buyer_messages bm
  ),
  durations AS (
    SELECT
      EXTRACT(EPOCH FROM (seller_reply_at - buyer_created_at)) / 60.0 AS minutes,
      seller_reply_at
    FROM first_replies
    WHERE seller_reply_at IS NOT NULL
  )
  SELECT
    COUNT(*)::INTEGER AS sample_count,
    ROUND(AVG(minutes)::NUMERIC, 1) AS avg_response_minutes,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY minutes)::NUMERIC, 1) AS median_response_minutes,
    ROUND((SELECT minutes::NUMERIC FROM durations ORDER BY seller_reply_at DESC LIMIT 1), 1) AS last_response_minutes
  FROM durations;
$$;

REVOKE ALL ON FUNCTION public.get_seller_response_time_stats(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_seller_response_time_stats(UUID) TO anon, authenticated, service_role;


-- ----------------------------------------------------------------------------
-- 4. Tačnost statistika i recenzija nakon arhiviranja ('archived'/'arhivirano')
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_seller_stats(p_seller_id UUID)
RETURNS JSON
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH
    order_stats AS (
      SELECT COUNT(*)::int AS delivered_count
      FROM public.orders
      WHERE seller_id = p_seller_id
        AND status IN ('delivered', 'archived', 'arhivirano')
    ),
    rating_stats AS (
      SELECT
        COUNT(*)::int                          AS review_count,
        ROUND(AVG(rating)::numeric, 1)::float  AS avg_rating
      FROM public.reviews
      WHERE seller_id = p_seller_id
    ),
    first_orders AS (
      SELECT DISTINCT ON (buyer_id)
        buyer_id,
        created_at AS order_created_at
      FROM public.orders
      WHERE seller_id = p_seller_id
      ORDER BY buyer_id, created_at ASC
    ),
    first_replies AS (
      SELECT
        c.buyer_id,
        MIN(m.created_at) AS first_reply_at
      FROM public.conversations c
      JOIN public.messages m
        ON m.conversation_id = c.id
       AND m.sender_id       = p_seller_id
      WHERE c.seller_id = p_seller_id
      GROUP BY c.buyer_id
    ),
    response_times AS (
      SELECT
        EXTRACT(EPOCH FROM (fr.first_reply_at - fo.order_created_at)) / 3600.0 AS hours
      FROM first_orders fo
      JOIN first_replies fr ON fr.buyer_id = fo.buyer_id
      WHERE fr.first_reply_at > fo.order_created_at
        AND EXTRACT(EPOCH FROM (fr.first_reply_at - fo.order_created_at)) / 3600.0 < 168
    )
  SELECT json_build_object(
    'orders_count',        (SELECT delivered_count FROM order_stats),
    'avg_rating',          (SELECT avg_rating       FROM rating_stats),
    'review_count',        (SELECT review_count     FROM rating_stats),
    'avg_response_hours',  (SELECT AVG(hours)::float FROM response_times)
  );
$$;

GRANT EXECUTE ON FUNCTION public.get_seller_stats(UUID) TO anon, authenticated;


CREATE OR REPLACE FUNCTION public.get_buyer_stats_dashboard(p_buyer_id UUID)
RETURNS JSON
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH
    auth_guard AS (
      SELECT (p_buyer_id = (SELECT auth.uid())) AS is_allowed
    ),
    order_counts AS (
      SELECT
        COUNT(*) FILTER (WHERE o.status IN ('delivered', 'archived', 'arhivirano'))::int AS total_success_count,
        COUNT(*) FILTER (WHERE o.status IN ('sent', 'accepted', 'shipped'))::int AS pending_count
      FROM public.orders o
      CROSS JOIN auth_guard ag
      WHERE ag.is_allowed = true
        AND o.buyer_id = p_buyer_id
    ),
    single_spent AS (
      SELECT COALESCE(SUM(COALESCE(o.total_amount, o.quantity_kg * p.price_per_kg)), 0.0) AS spent
      FROM public.orders o
      CROSS JOIN auth_guard ag
      LEFT JOIN public.products p ON p.id = o.product_id
      WHERE ag.is_allowed = true
        AND o.buyer_id = p_buyer_id
        AND o.product_id IS NOT NULL
        AND o.status IN ('delivered', 'archived', 'arhivirano')
    ),
    multi_spent AS (
      SELECT COALESCE(SUM(COALESCE(oi.total_price, oi.quantity_kg * p.price_per_kg)), 0.0) AS spent
      FROM public.orders o
      CROSS JOIN auth_guard ag
      JOIN public.order_items oi ON oi.order_id = o.id
      LEFT JOIN public.products p ON p.id = oi.product_id
      WHERE ag.is_allowed = true
        AND o.buyer_id = p_buyer_id
        AND o.product_id IS NULL
        AND o.status IN ('delivered', 'archived', 'arhivirano')
    )
  SELECT json_build_object(
    'pending_count',       (SELECT pending_count FROM order_counts),
    'total_success_count', (SELECT total_success_count FROM order_counts),
    'total_spent',         (SELECT spent FROM single_spent) + (SELECT spent FROM multi_spent)
  );
$$;

GRANT EXECUTE ON FUNCTION public.get_buyer_stats_dashboard(UUID) TO authenticated;


CREATE OR REPLACE FUNCTION public.get_seller_stats_dashboard(p_seller_id UUID)
RETURNS JSON
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH
    auth_guard AS (
      SELECT (p_seller_id = (SELECT auth.uid())) AS is_allowed
    ),
    order_counts AS (
      SELECT
        COUNT(*)::int                                    AS total_count,
        COUNT(*) FILTER (WHERE o.status = 'sent')::int   AS pending_count
      FROM public.orders o
      CROSS JOIN auth_guard ag
      WHERE ag.is_allowed = true
        AND o.seller_id = p_seller_id
    ),
    single_revenue AS (
      SELECT COALESCE(SUM(COALESCE(o.total_amount, o.quantity_kg * p.price_per_kg)), 0.0) AS rev
      FROM public.orders o
      CROSS JOIN auth_guard ag
      LEFT JOIN public.products p ON p.id = o.product_id
      WHERE ag.is_allowed = true
        AND o.seller_id = p_seller_id
        AND o.product_id IS NOT NULL
        AND o.status IN ('accepted', 'shipped', 'delivered', 'archived', 'arhivirano')
    ),
    multi_revenue AS (
      SELECT COALESCE(SUM(COALESCE(oi.total_price, oi.quantity_kg * p.price_per_kg)), 0.0) AS rev
      FROM public.orders o
      CROSS JOIN auth_guard ag
      JOIN public.order_items oi ON oi.order_id = o.id
      LEFT JOIN public.products p ON p.id = oi.product_id
      WHERE ag.is_allowed = true
        AND o.seller_id = p_seller_id
        AND o.product_id IS NULL
        AND o.status IN ('accepted', 'shipped', 'delivered', 'archived', 'arhivirano')
    )
  SELECT json_build_object(
    'pending_count', (SELECT pending_count FROM order_counts),
    'total_count',   (SELECT total_count   FROM order_counts),
    'revenue',       (SELECT rev FROM single_revenue) + (SELECT rev FROM multi_revenue)
  );
$$;

GRANT EXECUTE ON FUNCTION public.get_seller_stats_dashboard(UUID) TO authenticated;


CREATE OR REPLACE FUNCTION public.get_reviewable_order(
  p_buyer_id  UUID,
  p_seller_id UUID
)
RETURNS JSON
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT json_build_object(
    'order_id',     o.id,
    'product_id',   COALESCE(o.product_id,   oi.product_id),
    'product_name', COALESCE(o.product_name, oi.product_name)
  )
  FROM public.orders o
  LEFT JOIN LATERAL (
    SELECT oi.product_id, oi.product_name
      FROM public.order_items oi
     WHERE oi.order_id = o.id
     ORDER BY oi.id ASC
     LIMIT 1
  ) oi ON o.product_id IS NULL
  WHERE o.buyer_id  = p_buyer_id
    AND o.seller_id = p_seller_id
    AND p_buyer_id  = (SELECT auth.uid())
    AND o.status IN ('delivered', 'archived', 'arhivirano')
    AND NOT EXISTS (
          SELECT 1 FROM public.reviews r
           WHERE r.order_id = o.id
             AND r.buyer_id = p_buyer_id
        )
    AND COALESCE(o.product_id, oi.product_id) IS NOT NULL
  ORDER BY o.created_at DESC
  LIMIT 1;
$$;

GRANT EXECUTE ON FUNCTION public.get_reviewable_order(UUID, UUID) TO authenticated;


-- ----------------------------------------------------------------------------
-- 5. get_seller_inbox LATERAL konsolidacija i parcijalni indeks za poruke
-- ----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_messages_unread_by_conv_sender
  ON public.messages (conversation_id, sender_id)
  WHERE read_at IS NULL;

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
      c.order_id AS order_id,
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
    LEFT JOIN public.orders o ON o.id = c.order_id
    LEFT JOIN LATERAL (
      SELECT
        COUNT(*) AS cnt,
        (ARRAY_AGG(oi.product_name ORDER BY oi.id ASC))[1] AS first_product_name,
        (ARRAY_AGG(oi.quantity_kg ORDER BY oi.id ASC))[1] AS first_quantity_kg,
        (ARRAY_AGG(oi.unit_type ORDER BY oi.id ASC))[1] AS first_unit_type
      FROM public.order_items oi
      WHERE oi.order_id = c.order_id
    ) oi_agg ON c.order_id IS NOT NULL AND o.product_id IS NULL
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

GRANT EXECUTE ON FUNCTION public.get_seller_inbox(UUID, INT, INT) TO authenticated;


-- ----------------------------------------------------------------------------
-- 6. Rate-limit i bezbedno ažuriranje brojača na classified_ads
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.protect_classified_ad_administrative_columns()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_is_caller_admin BOOLEAN := public.is_admin_or_service_role();
  v_internal_metrics BOOLEAN := COALESCE(current_setting('app.internal_ad_metrics_update', true), '') = 'true';
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NOT v_is_caller_admin THEN
      NEW.is_featured := false;
      NEW.featured_until := NULL;
      NEW.is_urgent := false;
      NEW.reports_count := 0;
      NEW.call_clicks_count := 0;
      NEW.shares_count := 0;
      NEW.views_count := 0;
    END IF;
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' THEN
    -- Spreči otimanje vlasništva oglasa
    NEW.user_id := OLD.user_id;

    -- Samo administrator sme da menja is_featured, is_urgent ili featured_until
    IF NOT v_is_caller_admin THEN
      IF (NEW.is_featured IS DISTINCT FROM OLD.is_featured) OR
         (NEW.is_urgent IS DISTINCT FROM OLD.is_urgent) OR
         (NEW.featured_until IS DISTINCT FROM OLD.featured_until) THEN
        RAISE EXCEPTION USING
          ERRCODE = '42501',
          MESSAGE = 'Samo administrator može menjati status istaknutosti ili hitnosti oglasa.';
      END IF;

      -- Ako poziv ne dolazi iz verifikovane SECURITY DEFINER RPC/trigger funkcije,
      -- spreči klijenta da direktno menja brojače pregleda, poziva, deljenja ili prijava.
      IF NOT v_internal_metrics THEN
        NEW.reports_count := OLD.reports_count;
        NEW.call_clicks_count := OLD.call_clicks_count;
        NEW.shares_count := OLD.shares_count;
        NEW.views_count := OLD.views_count;
      END IF;
    END IF;
    RETURN NEW;
  END IF;

  RETURN NEW;
END;
$$;


CREATE OR REPLACE FUNCTION public.increment_classified_ad_interaction(
  ad_id UUID,
  p_type TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user UUID := auth.uid();
  v_owner UUID;
  v_status TEXT;
  v_allowed BOOLEAN;
BEGIN
  IF p_type NOT IN ('call', 'share') THEN
    RETURN;
  END IF;

  -- 1. Pronađi vlasnika i status oglasa
  SELECT user_id, status
    INTO v_owner, v_status
  FROM public.classified_ads
  WHERE id = ad_id;

  IF NOT FOUND OR v_status <> 'active' THEN
    RETURN;
  END IF;

  -- 2. Vlasnik oglasa ne povećava sopstvene brojače
  IF v_user IS NOT NULL AND v_user = v_owner THEN
    RETURN;
  END IF;

  -- 3. Rate-limit: najviše 10 interakcija iste vrste po oglasu u 5 minuta (300s)
  v_allowed := public.check_and_record_auth_rate_limit(
    'ad_interaction:' || p_type || ':' || ad_id::text,
    10,
    300
  );
  IF NOT v_allowed THEN
    RETURN;
  END IF;

  -- 4. Dozvoli promenu brojača kroz trigger za vreme trajanja ovog upita
  PERFORM set_config('app.internal_ad_metrics_update', 'true', true);

  IF p_type = 'call' THEN
    UPDATE public.classified_ads
    SET call_clicks_count = call_clicks_count + 1
    WHERE id = ad_id;
  ELSIF p_type = 'share' THEN
    UPDATE public.classified_ads
    SET shares_count = shares_count + 1
    WHERE id = ad_id;
  END IF;

  PERFORM set_config('app.internal_ad_metrics_update', 'false', true);
END;
$$;

REVOKE ALL ON FUNCTION public.increment_classified_ad_interaction(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.increment_classified_ad_interaction(UUID, TEXT) TO anon, authenticated, service_role;


CREATE OR REPLACE FUNCTION public.increment_classified_ad_views(
  ad_id UUID,
  p_viewer_id TEXT DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user UUID := auth.uid();
  v_owner UUID;
  v_status TEXT;
  v_headers JSONB;
  v_ua TEXT;
  v_ip TEXT;
  v_viewer_hash TEXT;
  v_inserted_count INT := 0;
BEGIN
  SELECT user_id, status
    INTO v_owner, v_status
  FROM public.classified_ads
  WHERE id = ad_id;

  IF NOT FOUND OR v_status <> 'active' THEN
    RETURN;
  END IF;

  IF v_user IS NOT NULL AND v_user = v_owner THEN
    RETURN;
  END IF;

  BEGIN
    v_headers := current_setting('request.headers', true)::jsonb;
    v_ua := lower(COALESCE(v_headers->>'user-agent', ''));
  EXCEPTION WHEN OTHERS THEN
    v_headers := '{}'::jsonb;
    v_ua := '';
  END;

  IF v_ua ~* '(bot|crawl|spider|slurp|curl|wget|python|scrapy|aiohttp|httpx|headless|chrome-lighthouse|lighthouse|preview|scraper|facebookexternalhit|whatsapp|telegrambot|discordbot|slackbot|archive\.org|semrush|ahrefs|bingbot|googlebot|yandex|bytespider)' THEN
    RETURN;
  END IF;

  IF p_viewer_id IS NOT NULL AND p_viewer_id ~* '^(bot|spider|crawler)' THEN
    RETURN;
  END IF;

  IF v_user IS NOT NULL THEN
    v_viewer_hash := 'usr:' || v_user::text;
  ELSIF p_viewer_id IS NOT NULL AND length(trim(p_viewer_id)) > 0 THEN
    v_viewer_hash := 'dev:' || md5(trim(p_viewer_id));
  ELSE
    v_ip := COALESCE(
      v_headers->>'cf-connecting-ip',
      v_headers->>'x-real-ip',
      split_part(v_headers->>'x-forwarded-for', ',', 1),
      'unknown'
    );
    v_viewer_hash := 'ip_ua:' || md5(v_ip || ':' || v_ua);
  END IF;

  WITH inserted_or_updated AS (
    INSERT INTO public.classified_ad_views (ad_id, viewer_hash, last_viewed_at)
    VALUES (increment_classified_ad_views.ad_id, v_viewer_hash, now())
    ON CONFLICT (ad_id, viewer_hash)
    DO UPDATE SET last_viewed_at = now()
    WHERE classified_ad_views.last_viewed_at <= now() - INTERVAL '24 hours'
    RETURNING ad_id
  )
  SELECT count(*) INTO v_inserted_count FROM inserted_or_updated;

  IF v_inserted_count > 0 THEN
    PERFORM set_config('app.internal_ad_metrics_update', 'true', true);
    UPDATE public.classified_ads
    SET views_count = views_count + 1,
        last_view_at = now()
    WHERE id = increment_classified_ad_views.ad_id;
    PERFORM set_config('app.internal_ad_metrics_update', 'false', true);
  END IF;

  IF random() < 0.01 THEN
    DELETE FROM public.classified_ad_views
    WHERE last_viewed_at < now() - INTERVAL '14 days';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.increment_classified_ad_views(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.increment_classified_ad_views(UUID, TEXT) TO anon, authenticated, service_role;


CREATE OR REPLACE FUNCTION public.increment_classified_ad_reports_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM set_config('app.internal_ad_metrics_update', 'true', true);
  UPDATE public.classified_ads
  SET reports_count = reports_count + 1
  WHERE id = NEW.ad_id;
  PERFORM set_config('app.internal_ad_metrics_update', 'false', true);
  RETURN NEW;
END;
$$;


-- ----------------------------------------------------------------------------
-- 7. FORCE ROW LEVEL SECURITY na public.waitlist i ispravka postal_codes
-- ----------------------------------------------------------------------------
ALTER TABLE public.waitlist FORCE ROW LEVEL SECURITY;

INSERT INTO public.postal_codes (postal_code, city, settlement, is_primary, normalized_city)
VALUES
  ('15341', 'Lipnički Šor', '', true, 'lipnicki sor'),
  ('15342', 'Rainovača', '', true, 'rainovaca'),
  ('18203', 'Sečanica', '', true, 'secanica'),
  ('18203', 'Sečanica (Sečanica)', 'Sečanica', false, 'secanica (secanica)'),
  ('19232', 'Dubočane', '', true, 'dubocane'),
  ('26214', 'Debeljača', '', true, 'debeljaca'),
  ('32101', 'Čačak', '', true, 'cacak'),
  ('32233', 'Viča', '', true, 'vica'),
  ('37216', 'Novi Bračin', '', true, 'novi bracin')
ON CONFLICT (postal_code, city) DO UPDATE
SET
  settlement = EXCLUDED.settlement,
  is_primary = EXCLUDED.is_primary,
  normalized_city = EXCLUDED.normalized_city;

DELETE FROM public.postal_codes
WHERE (postal_code = '15341' AND city <> 'Lipnički Šor')
   OR (postal_code = '15342' AND city <> 'Rainovača')
   OR (postal_code = '18203' AND city NOT IN ('Sečanica', 'Sečanica (Sečanica)'))
   OR (postal_code = '19232' AND city <> 'Dubočane')
   OR (postal_code = '26214' AND city <> 'Debeljača')
   OR (postal_code = '32101' AND city <> 'Čačak')
   OR (postal_code = '32233' AND city <> 'Viča')
   OR (postal_code = '37216' AND city <> 'Novi Bračin');
