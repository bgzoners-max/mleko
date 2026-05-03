-- ─────────────────────────────────────────────────────────────────────────────
-- get_buyer_stats_dashboard
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_buyer_stats_dashboard(p_buyer_id UUID)
RETURNS JSON
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH
    order_counts AS (
      SELECT
        COUNT(*) FILTER (WHERE status = 'delivered')::int AS total_success_count,
        COUNT(*) FILTER (WHERE status IN ('sent', 'accepted', 'shipped'))::int AS pending_count
      FROM orders
      WHERE buyer_id = p_buyer_id
        AND p_buyer_id = auth.uid()
    ),
    single_spent AS (
      SELECT COALESCE(SUM(COALESCE(o.total_amount, o.quantity_kg * p.price_per_kg)), 0.0) AS spent
      FROM   orders o
      LEFT JOIN products p ON p.id = o.product_id
      WHERE  o.buyer_id  = p_buyer_id
        AND  p_buyer_id = auth.uid()
        AND  o.product_id IS NOT NULL
        AND  o.status = 'delivered'
    ),
    multi_spent AS (
      SELECT COALESCE(SUM(COALESCE(oi.total_price, oi.quantity_kg * p.price_per_kg)), 0.0) AS spent
      FROM   orders o
      JOIN   order_items oi ON oi.order_id  = o.id
      LEFT JOIN products p  ON p.id         = oi.product_id
      WHERE  o.buyer_id  = p_buyer_id
        AND  p_buyer_id = auth.uid()
        AND  o.product_id IS NULL
        AND  o.status = 'delivered'
    )
  SELECT json_build_object(
    'pending_count',       (SELECT pending_count FROM order_counts),
    'total_success_count', (SELECT total_success_count FROM order_counts),
    'total_spent',         (SELECT spent FROM single_spent) + (SELECT spent FROM multi_spent)
  );
$$;

GRANT EXECUTE ON FUNCTION public.get_buyer_stats_dashboard(UUID) TO authenticated;
