-- RPC get_favorite_sellers_with_profiles – jedan poziv umesto getFavoriteSellerIds + profiles.inFilter
-- JOIN favorite_sellers sa profiles u bazi

CREATE OR REPLACE FUNCTION public.get_favorite_sellers_with_profiles(p_user_id uuid)
RETURNS SETOF public.profiles
LANGUAGE sql
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT p.*
  FROM profiles p
  JOIN favorite_sellers fs ON fs.seller_id = p.id
  WHERE fs.user_id = p_user_id
    AND p.role = 'seller';
$$;
