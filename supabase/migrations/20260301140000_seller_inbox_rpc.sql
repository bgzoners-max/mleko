-- RPC za seller inbox – jedan round-trip umesto 2+5C+2O upita
-- Zamenjuje N+1 petlju u SellerInboxService.getInboxItems()

ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS buyer_address TEXT;

CREATE OR REPLACE FUNCTION public.get_seller_inbox(p_seller_id UUID)
RETURNS JSONB
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH
  -- Konverzacije sa JOIN-ovima
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
  ),
  -- Porudžbine bez konverzacije
  order_ids_with_conv AS (
    SELECT DISTINCT order_id FROM conversations
    WHERE seller_id = p_seller_id AND order_id IS NOT NULL
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
      AND o.id NOT IN (SELECT order_id FROM order_ids_with_conv WHERE order_id IS NOT NULL)
  ),
  -- Multi-item: product_name = "N proizvoda"
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

GRANT EXECUTE ON FUNCTION public.get_seller_inbox(UUID) TO authenticated;
