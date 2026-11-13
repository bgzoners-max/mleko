-- Paket 2 (P1): Ispravke handle_order_retention(), get_seller_loyalty_stats() i get_seller_inbox().

-- 1. handle_order_retention():
--    trg_maintain_product_order_summary već održava product_order_summary pri prelazu
--    u 'archived' i pri brisanju iz orders. Raniji UPDATE/DELETE je pri svakom cron
--    pokretanju skidao -1 za istekle 'accepted'/'delivered' porudžbine koje se uopšte
--    ne brišu (brišu se samo 'archived'), što je kvarilo brojač do brisanja reda.
CREATE OR REPLACE FUNCTION public.handle_order_retention()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Brisanje: isključivo arhivirane porudžbine kojima je istekao expires_at
  -- (order_items padaju CASCADE; trigger trg_maintain_product_order_summary čuva brojače).
  DELETE FROM public.orders
  WHERE status = 'archived'
    AND expires_at IS NOT NULL
    AND expires_at <= now();
END;
$$;

-- 2. get_seller_loyalty_stats(UUID):
--    Podržava kanonski status 'archived' (uz nasleđeni 'arhivirano' za starije zapise).
CREATE OR REPLACE FUNCTION public.get_seller_loyalty_stats(p_seller_id UUID)
RETURNS JSON
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH buyer_orders AS (
    SELECT
      buyer_id,
      COUNT(*)::int AS cnt
    FROM public.orders
    WHERE seller_id = p_seller_id
      AND status IN ('delivered', 'archived', 'arhivirano')
    GROUP BY buyer_id
  )
  SELECT json_build_object(
    'repeat_buyers', COALESCE(COUNT(*) FILTER (WHERE cnt >= 2), 0),
    'repeat_orders', COALESCE(SUM(GREATEST(cnt - 1, 0))::int, 0)
  )
  FROM buyer_orders;
$$;

GRANT EXECUTE ON FUNCTION public.get_seller_loyalty_stats(UUID) TO anon, authenticated;

-- 3. get_seller_inbox(UUID, INT, INT):
--    - Sortiranje pre LIMIT/OFFSET paginacije (ranije je paginacija bila bez ORDER BY).
--    - Usaglašeno mapiranje status_label ('sent' -> 'Na čekanju', 'shipped' -> 'Poslato',
--      'archived'/'arhivirano' -> 'Arhivirano', bez lažnog 'Poslato' kad nema porudžbine).
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
  -- Verifikacija autorizacije: pozivalac mora biti p_seller_id ili administrator
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
      COALESCE(p.name, ad.title, o.product_name, oi_first.product_name) AS product_name,
      COALESCE(o.quantity_kg::float8, oi_first.quantity_kg::float8) AS quantity_kg,
      COALESCE(p.unit_type, ad.currency, o.unit_type, oi_first.unit_type) AS unit_type,
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
        CASE WHEN (SELECT COUNT(*) FROM public.order_items WHERE order_id = c.order_id) > 1
             THEN (SELECT COUNT(*)::text FROM public.order_items WHERE order_id = c.order_id) || ' proizvoda'
             ELSE (SELECT product_name FROM public.order_items WHERE order_id = c.order_id LIMIT 1)
        END AS product_name,
        (SELECT quantity_kg FROM public.order_items WHERE order_id = c.order_id LIMIT 1) AS quantity_kg,
        (SELECT unit_type FROM public.order_items WHERE order_id = c.order_id LIMIT 1) AS unit_type
    ) oi_first ON c.order_id IS NOT NULL AND o.product_id IS NULL
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
      COALESCE(o.product_id, (SELECT oi.product_id FROM public.order_items oi WHERE oi.order_id = o.id LIMIT 1)) AS product_id,
      NULL::uuid AS ad_id,
      COALESCE(pb.farm_name, pb.display_name, 'Kupac') AS other_party_name,
      pb.profile_image_url AS other_party_image_url,
      NULL::text AS last_message_body,
      0 AS unread_count,
      COALESCE(o.product_name, oi_first.product_name) AS product_name,
      COALESCE(o.quantity_kg::float8, oi_first.quantity_kg::float8) AS quantity_kg,
      COALESCE(o.unit_type, oi_first.unit_type) AS unit_type,
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
        CASE WHEN (SELECT COUNT(*) FROM public.order_items WHERE order_id = o.id) > 1
             THEN (SELECT COUNT(*)::text FROM public.order_items WHERE order_id = o.id) || ' proizvoda'
             ELSE (SELECT product_name FROM public.order_items WHERE order_id = o.id LIMIT 1)
        END AS product_name,
        (SELECT quantity_kg FROM public.order_items WHERE order_id = o.id LIMIT 1) AS quantity_kg,
        (SELECT unit_type FROM public.order_items WHERE order_id = o.id LIMIT 1) AS unit_type
    ) oi_first ON o.product_id IS NULL
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

