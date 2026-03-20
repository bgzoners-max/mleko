-- P3: SECURITY DEFINER RPCs bypass RLS — caller-supplied UUID params must match auth.uid()
-- where the data is private (inbox, conversations, seller dashboard, buyer review queue).

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. get_conversations_for_user
-- ─────────────────────────────────────────────────────────────────────────────
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
      c.order_id,
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
         FROM messages m2
        WHERE m2.conversation_id = c.id
          AND m2.sender_id      != p_user_id
          AND m2.read_at         IS NULL)                                  AS unread_count
    FROM conversations c
    JOIN profiles pb ON pb.id = c.buyer_id
    JOIN profiles ps ON ps.id = c.seller_id
    LEFT JOIN LATERAL (
      SELECT body, created_at
        FROM messages
       WHERE conversation_id = c.id
       ORDER BY created_at DESC
       LIMIT 1
    ) lm ON true
    WHERE (c.buyer_id = p_user_id OR c.seller_id = p_user_id)
      AND p_user_id = auth.uid()
    ORDER BY c.updated_at DESC
    LIMIT 50
  ) t;
$$;


-- ─────────────────────────────────────────────────────────────────────────────
-- 2. get_seller_stats_dashboard
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_seller_stats_dashboard(p_seller_id UUID)
RETURNS JSON
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH
    order_counts AS (
      SELECT
        COUNT(*)::int                                  AS total_count,
        COUNT(*) FILTER (WHERE status = 'sent')::int   AS pending_count
      FROM orders
      WHERE seller_id = p_seller_id
        AND p_seller_id = auth.uid()
    ),
    single_revenue AS (
      SELECT COALESCE(SUM(o.quantity_kg * p.price_per_kg), 0.0) AS rev
      FROM   orders o
      JOIN   products p ON p.id = o.product_id
      WHERE  o.seller_id  = p_seller_id
        AND  p_seller_id = auth.uid()
        AND  o.product_id IS NOT NULL
        AND  o.status      IN ('accepted', 'delivered')
    ),
    multi_revenue AS (
      SELECT COALESCE(SUM(oi.quantity_kg * p.price_per_kg), 0.0) AS rev
      FROM   orders o
      JOIN   order_items oi ON oi.order_id  = o.id
      JOIN   products    p  ON p.id         = oi.product_id
      WHERE  o.seller_id  = p_seller_id
        AND  p_seller_id = auth.uid()
        AND  o.product_id IS NULL
        AND  o.status      IN ('accepted', 'delivered')
    )
  SELECT json_build_object(
    'pending_count', (SELECT pending_count FROM order_counts),
    'total_count',   (SELECT total_count   FROM order_counts),
    'revenue',       (SELECT rev FROM single_revenue) + (SELECT rev FROM multi_revenue)
  );
$$;


-- ─────────────────────────────────────────────────────────────────────────────
-- 3. get_reviewable_order
-- ─────────────────────────────────────────────────────────────────────────────
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
  FROM orders o
  LEFT JOIN LATERAL (
    SELECT product_id, product_name
      FROM order_items
     WHERE order_id = o.id
     ORDER BY created_at ASC
     LIMIT 1
  ) oi ON o.product_id IS NULL
  WHERE  o.buyer_id  = p_buyer_id
    AND  o.seller_id = p_seller_id
    AND  p_buyer_id  = auth.uid()
    AND  o.status    = 'delivered'
    AND  NOT EXISTS (
           SELECT 1 FROM reviews r
            WHERE r.order_id  = o.id
              AND r.buyer_id  = p_buyer_id
         )
    AND  COALESCE(o.product_id, oi.product_id) IS NOT NULL
  ORDER BY o.created_at DESC
  LIMIT 1;
$$;


-- ─────────────────────────────────────────────────────────────────────────────
-- 4. get_seller_inbox
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_seller_inbox(p_seller_id UUID)
RETURNS JSONB
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH
  conv_rows AS (
    SELECT
      'conversation'::text AS item_type,
      c.updated_at AS sort_date,
      c.id AS conversation_id,
      c.order_id AS order_id,
      c.buyer_id AS buyer_id,
      COALESCE(pb.farm_name, pb.display_name, 'Kupac') AS other_party_name,
      pb.profile_image_url AS other_party_image_url,
      lm.body AS last_message_body,
      (SELECT COUNT(*)::int FROM messages m2
       WHERE m2.conversation_id = c.id
         AND m2.sender_id != p_seller_id
         AND m2.read_at IS NULL) AS unread_count,
      COALESCE(o.product_name, oi_first.product_name) AS product_name,
      COALESCE(o.quantity_kg::float8, oi_first.quantity_kg::float8) AS quantity_kg,
      COALESCE(o.unit_type, oi_first.unit_type) AS unit_type,
      CASE o.status
        WHEN 'sent' THEN 'Poslato'
        WHEN 'accepted' THEN 'Prihvaćeno'
        WHEN 'rejected' THEN 'Odbijeno'
        WHEN 'delivered' THEN 'Isporučeno'
        WHEN 'cancelled_by_seller' THEN 'Otkazano'
        WHEN 'arhivirano' THEN 'Arhivirano'
        ELSE 'Poslato'
      END AS status_label,
      o.buyer_phone AS buyer_phone,
      o.note AS note,
      o.buyer_city AS buyer_city,
      o.buyer_address AS buyer_address
    FROM conversations c
    JOIN profiles pb ON pb.id = c.buyer_id
    LEFT JOIN orders o ON o.id = c.order_id
    LEFT JOIN LATERAL (
      SELECT
        CASE WHEN (SELECT COUNT(*) FROM order_items WHERE order_id = c.order_id) > 1
             THEN (SELECT COUNT(*)::text FROM order_items WHERE order_id = c.order_id) || ' proizvoda'
             ELSE (SELECT product_name FROM order_items WHERE order_id = c.order_id LIMIT 1)
        END AS product_name,
        (SELECT quantity_kg FROM order_items WHERE order_id = c.order_id LIMIT 1) AS quantity_kg,
        (SELECT unit_type FROM order_items WHERE order_id = c.order_id LIMIT 1) AS unit_type
    ) oi_first ON c.order_id IS NOT NULL AND o.product_id IS NULL
    LEFT JOIN LATERAL (
      SELECT body FROM messages
      WHERE conversation_id = c.id
      ORDER BY created_at DESC
      LIMIT 1
    ) lm ON true
    WHERE c.seller_id = p_seller_id
      AND p_seller_id = auth.uid()
  ),
  order_ids_with_conv AS (
    SELECT DISTINCT order_id FROM conversations
    WHERE seller_id = p_seller_id
      AND p_seller_id = auth.uid()
      AND order_id IS NOT NULL
  ),
  order_rows AS (
    SELECT
      'order'::text AS item_type,
      o.created_at AS sort_date,
      o.id AS order_id,
      NULL::uuid AS conversation_id,
      o.buyer_id AS buyer_id,
      COALESCE(pb.farm_name, pb.display_name, 'Kupac') AS other_party_name,
      pb.profile_image_url AS other_party_image_url,
      NULL::text AS last_message_body,
      0 AS unread_count,
      COALESCE(o.product_name, oi_first.product_name) AS product_name,
      COALESCE(o.quantity_kg::float8, oi_first.quantity_kg::float8) AS quantity_kg,
      COALESCE(o.unit_type, oi_first.unit_type) AS unit_type,
      CASE o.status
        WHEN 'sent' THEN 'Poslato'
        WHEN 'accepted' THEN 'Prihvaćeno'
        WHEN 'rejected' THEN 'Odbijeno'
        WHEN 'delivered' THEN 'Isporučeno'
        WHEN 'cancelled_by_seller' THEN 'Otkazano'
        WHEN 'arhivirano' THEN 'Arhivirano'
        ELSE 'Poslato'
      END AS status_label,
      o.buyer_phone AS buyer_phone,
      o.note AS note,
      o.buyer_city AS buyer_city,
      o.buyer_address AS buyer_address
    FROM orders o
    JOIN profiles pb ON pb.id = o.buyer_id
    LEFT JOIN LATERAL (
      SELECT
        CASE WHEN (SELECT COUNT(*) FROM order_items WHERE order_id = o.id) > 1
             THEN (SELECT COUNT(*)::text FROM order_items WHERE order_id = o.id) || ' proizvoda'
             ELSE (SELECT product_name FROM order_items WHERE order_id = o.id LIMIT 1)
        END AS product_name,
        (SELECT quantity_kg FROM order_items WHERE order_id = o.id LIMIT 1) AS quantity_kg,
        (SELECT unit_type FROM order_items WHERE order_id = o.id LIMIT 1) AS unit_type
    ) oi_first ON o.product_id IS NULL
    WHERE o.seller_id = p_seller_id
      AND p_seller_id = auth.uid()
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
        'other_party_name', other_party_name,
        'other_party_image_url', other_party_image_url,
        'product_name', product_name,
        'quantity_kg', quantity_kg,
        'unit_type', unit_type,
        'last_message_body', last_message_body,
        'unread_count', unread_count,
        'status_label', status_label,
        'buyer_phone', buyer_phone,
        'note', note,
        'buyer_city', buyer_city,
        'buyer_address', buyer_address
      )
      ORDER BY sort_date DESC
    ),
    '[]'::jsonb
  )
  FROM combined;
$$;
