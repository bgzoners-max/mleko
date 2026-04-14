-- Atomically sync product delivery mode and selected delivery points.

DROP FUNCTION IF EXISTS public.set_product_delivery_scope(UUID, TEXT, UUID[]);

CREATE FUNCTION public.set_product_delivery_scope(
  p_product_id UUID,
  p_delivery_mode TEXT,
  p_delivery_point_ids UUID[] DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_seller_id UUID;
  v_point_ids UUID[] := '{}';
  v_valid_points_count INTEGER := 0;
BEGIN
  IF p_delivery_mode NOT IN ('none', 'all_seller_points', 'selected_points') THEN
    RAISE EXCEPTION 'invalid delivery_mode';
  END IF;

  SELECT seller_id
  INTO v_seller_id
  FROM public.products
  WHERE id = p_product_id;

  IF v_seller_id IS NULL THEN
    RAISE EXCEPTION 'product not found';
  END IF;

  IF auth.uid() IS DISTINCT FROM v_seller_id THEN
    RAISE EXCEPTION 'Unauthorized: product does not belong to authenticated seller';
  END IF;

  SELECT COALESCE(array_agg(DISTINCT point_id), '{}')
  INTO v_point_ids
  FROM unnest(COALESCE(p_delivery_point_ids, '{}')) AS point_id;

  IF p_delivery_mode = 'selected_points'
     AND COALESCE(array_length(v_point_ids, 1), 0) = 0 THEN
    RAISE EXCEPTION 'selected_points requires at least one delivery point';
  END IF;

  IF COALESCE(array_length(v_point_ids, 1), 0) > 0 THEN
    SELECT COUNT(*)
    INTO v_valid_points_count
    FROM public.seller_delivery_points
    WHERE id = ANY(v_point_ids)
      AND seller_id = v_seller_id;

    IF v_valid_points_count <> array_length(v_point_ids, 1) THEN
      RAISE EXCEPTION 'one or more delivery points are invalid for this seller';
    END IF;
  END IF;

  DELETE FROM public.product_delivery_points
  WHERE product_id = p_product_id;

  IF p_delivery_mode = 'selected_points' THEN
    INSERT INTO public.product_delivery_points (product_id, delivery_point_id)
    SELECT p_product_id, point_id
    FROM unnest(v_point_ids) AS point_id;
  END IF;

  UPDATE public.products
  SET delivery_mode = p_delivery_mode
  WHERE id = p_product_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.set_product_delivery_scope(UUID, TEXT, UUID[]) TO authenticated;
