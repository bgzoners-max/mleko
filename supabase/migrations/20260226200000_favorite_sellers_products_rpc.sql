-- RPC get_products_from_favorite_sellers – jedan poziv umesto getFavoriteSellerIds + products.inFilter
-- JOIN u bazi umesto 2 round-trip-a

CREATE OR REPLACE FUNCTION public.get_products_from_favorite_sellers(p_user_id uuid)
RETURNS SETOF public.products
LANGUAGE sql
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT p.*
  FROM products p
  JOIN favorite_sellers fs ON fs.seller_id = p.seller_id
  WHERE fs.user_id = p_user_id
  ORDER BY p.created_at DESC;
$$;
