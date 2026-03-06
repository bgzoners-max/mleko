-- Badge „Popularno“ (broj prodaja) i sortiranje po oceni
-- RPC: broj isporučenih/prihvaćenih porudžbina po proizvodu (bypass RLS)

CREATE OR REPLACE FUNCTION public.get_product_sales_counts()
RETURNS TABLE (product_id uuid, order_count bigint)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT product_id, COUNT(*)::bigint
  FROM orders
  WHERE status IN ('accepted', 'delivered')
  GROUP BY product_id;
$$;

-- RPC: prosečna ocena i broj recenzija po proizvodu
CREATE OR REPLACE FUNCTION public.get_product_ratings()
RETURNS TABLE (product_id uuid, avg_rating numeric, review_count bigint)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT product_id, AVG(rating)::numeric, COUNT(*)::bigint
  FROM reviews
  WHERE product_id IS NOT NULL
  GROUP BY product_id;
$$;
