-- ─────────────────────────────────────────────────────────────────────────────
-- 1. get_conversations_for_user
--    Zamenjuje 3N DB poziva u ChatService.getConversations().
--    Jedan round-trip: conversations JOIN profili + LATERAL poslednja poruka
--    + correlated subquery za broj nepročitanih (sve u DB-u, nema Flutter iteracije).
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
    WHERE c.buyer_id = p_user_id OR c.seller_id = p_user_id
    ORDER BY c.updated_at DESC
    LIMIT 50
  ) t;
$$;

GRANT EXECUTE ON FUNCTION public.get_conversations_for_user(UUID) TO authenticated;


-- ─────────────────────────────────────────────────────────────────────────────
-- 2. get_seller_stats_dashboard
--    Zamenjuje N+N+1 loop u OrdersService.getSellerStats().
--    Jedan round-trip: COUNT na orders + JOIN sa products za prihod.
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
    ),
    -- Porudžbine sa jednim proizvodom (product_id direktno na order redu)
    single_revenue AS (
      SELECT COALESCE(SUM(o.quantity_kg * p.price_per_kg), 0.0) AS rev
      FROM   orders o
      JOIN   products p ON p.id = o.product_id
      WHERE  o.seller_id  = p_seller_id
        AND  o.product_id IS NOT NULL
        AND  o.status      IN ('accepted', 'delivered')
    ),
    -- Porudžbine sa više proizvoda (stavke u order_items)
    multi_revenue AS (
      SELECT COALESCE(SUM(oi.quantity_kg * p.price_per_kg), 0.0) AS rev
      FROM   orders o
      JOIN   order_items oi ON oi.order_id  = o.id
      JOIN   products    p  ON p.id         = oi.product_id
      WHERE  o.seller_id  = p_seller_id
        AND  o.product_id IS NULL
        AND  o.status      IN ('accepted', 'delivered')
    )
  SELECT json_build_object(
    'pending_count', (SELECT pending_count FROM order_counts),
    'total_count',   (SELECT total_count   FROM order_counts),
    'revenue',       (SELECT rev FROM single_revenue) + (SELECT rev FROM multi_revenue)
  );
$$;

GRANT EXECUTE ON FUNCTION public.get_seller_stats_dashboard(UUID) TO authenticated;


-- ─────────────────────────────────────────────────────────────────────────────
-- 3. get_reviewable_order
--    Zamenjuje N+1 loop + extra N upita u ReviewsService.getReviewableOrder().
--    Direktan query sa NOT EXISTS — vraća prvu isporučenu nerecenziranu porudžbinu.
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

GRANT EXECUTE ON FUNCTION public.get_reviewable_order(UUID, UUID) TO authenticated;
