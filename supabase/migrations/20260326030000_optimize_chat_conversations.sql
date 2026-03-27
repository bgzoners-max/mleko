-- RPC za dohvatanje kompletne info o razgovoru sa profilima u jednom upitu
-- Umesto dve odvojene pretrage (conversations + profiles), sve u jednom RPC-u

CREATE OR REPLACE FUNCTION public.get_conversation_info_with_profile(
  p_conversation_id TEXT
)
RETURNS TABLE (
  id TEXT,
  buyer_id TEXT,
  seller_id TEXT,
  order_id TEXT,
  buyer_name TEXT,
  seller_name TEXT
)
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id,
    c.buyer_id,
    c.seller_id,
    c.order_id,
    COALESCE(pb.farm_name, pb.display_name, 'Kupac') AS buyer_name,
    COALESCE(ps.farm_name, ps.display_name, 'Prodavac') AS seller_name
  FROM public.conversations c
  LEFT JOIN public.profiles pb ON c.buyer_id = pb.id
  LEFT JOIN public.profiles ps ON c.seller_id = ps.id
  WHERE c.id = p_conversation_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_conversation_info_with_profile(TEXT) TO authenticated;
