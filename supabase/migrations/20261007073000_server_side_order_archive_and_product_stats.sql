-- ============================================================================
-- Server-side Order Archive Retention & Product Stats
-- ============================================================================
-- 1. Automatsko postavljanje server-side timestamp-ova pri arhiviranju porudžbine:
--    - archived_at = now()
--    - expires_at = now() + INTERVAL '12 months' (eliminacija oslanjanja na klijentski sat)
-- 2. RPC archive_order(p_order_id) za bezbedno arhiviranje sa strane kupca ili prodavca.
-- 3. RPC get_product_stats(p_product_id) za brz O(1) dohvat agregata ocena i broja recenzija.
-- ============================================================================

-- 1. Triger za server-side datum arhive i retention
CREATE OR REPLACE FUNCTION public.set_order_archived_timestamps()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF NEW.status = 'archived' AND (OLD.status IS DISTINCT FROM 'archived') THEN
    NEW.archived_at := COALESCE(NEW.archived_at, now());
    NEW.expires_at := now() + INTERVAL '12 months';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_set_order_archived_timestamps ON public.orders;
CREATE TRIGGER trg_set_order_archived_timestamps
  BEFORE UPDATE OF status ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.set_order_archived_timestamps();

-- 2. RPC archive_order
CREATE OR REPLACE FUNCTION public.archive_order(p_order_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_order RECORD;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Niste prijavljeni.' USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT id, buyer_id, seller_id, status
  INTO v_order
  FROM public.orders
  WHERE id = p_order_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Porudžbina nije pronađena.' USING ERRCODE = 'no_data_found';
  END IF;

  IF v_order.buyer_id != v_uid AND v_order.seller_id != v_uid THEN
    RAISE EXCEPTION 'Nemate dozvolu za arhiviranje ove porudžbine.' USING ERRCODE = 'insufficient_privilege';
  END IF;

  UPDATE public.orders
  SET status = 'archived'
  WHERE id = p_order_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.archive_order(UUID) TO authenticated;

-- 3. RPC get_product_stats
CREATE OR REPLACE FUNCTION public.get_product_stats(p_product_id UUID)
RETURNS JSON
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT json_build_object(
    'avg_rating', COALESCE(s.avg_rating, (SELECT ROUND(AVG(rating)::numeric, 1)::float FROM public.reviews WHERE product_id = p_product_id)),
    'review_count', COALESCE(s.review_count, (SELECT COUNT(*)::int FROM public.reviews WHERE product_id = p_product_id))
  )
  FROM (SELECT 1) _
  LEFT JOIN public.product_review_summary s ON s.product_id = p_product_id;
$$;

GRANT EXECUTE ON FUNCTION public.get_product_stats(UUID) TO anon, authenticated;
