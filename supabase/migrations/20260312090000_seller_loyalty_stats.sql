-- Statistika lojalnosti kupaca za prodavca:
-- - broj kupaca koji su poručivali 2+ puta
-- - ukupan broj "ponovljenih" kupovina (sve preko prve po kupcu)
--
-- Računa se samo nad porudžbinama koje su uspešno završene
-- (isporučene ili arhivirane nakon isporuke).

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
      AND status IN ('delivered', 'arhivirano')
    GROUP BY buyer_id
  )
  SELECT json_build_object(
    'repeat_buyers', COALESCE(COUNT(*) FILTER (WHERE cnt >= 2), 0),
    'repeat_orders', COALESCE(SUM(GREATEST(cnt - 1, 0))::int, 0)
  )
  FROM buyer_orders;
$$;

GRANT EXECUTE ON FUNCTION public.get_seller_loyalty_stats(UUID) TO anon, authenticated;

