-- ============================================================================
-- Migracija 20260929140000: Fix favorite sellers RPCs
--
-- 1. get_favorite_sellers_with_profiles:
--    Prethodno je bila SECURITY INVOKER i direktno čitala tabelu profiles.
--    Nakon migracije 20260917140000 (kolonska zaštita / revoke table select na profiles),
--    poziv je bacao 'permission denied' jer uloga authenticated nema pravo čitanja
--    svih kolona na tabeli profiles (npr. email, phone).
--    Rešenje: SECURITY DEFINER sa SET search_path = public, vraća public.public_profiles
--    koji bezbedno maskira osetljive podatke.
--
-- 2. get_products_from_favorite_sellers:
--    SECURITY DEFINER sa SET search_path = public, vraća public.products_with_ratings.
-- ============================================================================

DROP FUNCTION IF EXISTS public.get_favorite_sellers_with_profiles(uuid);

CREATE OR REPLACE FUNCTION public.get_favorite_sellers_with_profiles(p_user_id uuid)
RETURNS SETOF public.public_profiles
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT pp.*
  FROM public.public_profiles pp
  JOIN public.favorite_sellers fs ON fs.seller_id = pp.id
  WHERE fs.user_id = p_user_id
    AND (p_user_id = auth.uid() OR public.is_admin())
    AND pp.role = 'seller';
$$;

GRANT EXECUTE ON FUNCTION public.get_favorite_sellers_with_profiles(uuid) TO authenticated;

DROP FUNCTION IF EXISTS public.get_products_from_favorite_sellers(uuid);

CREATE OR REPLACE FUNCTION public.get_products_from_favorite_sellers(p_user_id uuid)
RETURNS SETOF public.products_with_ratings
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT pwr.*
  FROM public.products_with_ratings pwr
  JOIN public.favorite_sellers fs ON fs.seller_id = pwr.seller_id
  WHERE fs.user_id = p_user_id
    AND (p_user_id = auth.uid() OR public.is_admin())
  ORDER BY pwr.created_at DESC;
$$;

GRANT EXECUTE ON FUNCTION public.get_products_from_favorite_sellers(uuid) TO authenticated;
