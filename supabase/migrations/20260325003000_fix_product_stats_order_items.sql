-- Ispravka: Brojanje prodaja iz order_items tabele (jer proizvodi mogu biti u multi-item narudžbinama)
DROP VIEW IF EXISTS public.products_with_ratings CASCADE;

CREATE VIEW public.products_with_ratings AS
SELECT
  p.id,
  p.seller_id,
  p.category,
  p.name,
  p.price_per_kg,
  p.min_order_kg,
  p.available_kg,
  p.description,
  p.image_urls,
  p.pickup_options,
  p.location,
  p.is_domestic,
  p.available_now,
  p.created_at,
  COALESCE(r.avg_rating, 0)::numeric AS avg_rating,
  COALESCE(r.review_count, 0)::bigint AS review_count,
  COALESCE(s.order_count, 0)::bigint AS order_count
FROM public.products p
LEFT JOIN (
  SELECT product_id, AVG(rating)::numeric AS avg_rating, COUNT(*)::bigint AS review_count
  FROM public.reviews
  WHERE product_id IS NOT NULL
  GROUP BY product_id
) r ON p.id = r.product_id
LEFT JOIN (
  -- Brojanje iz order_items jer proizvodi mogu biti u multi-item narudžbinama
  SELECT DISTINCT oi.product_id, COUNT(DISTINCT oi.order_id)::bigint AS order_count
  FROM public.order_items oi
  INNER JOIN public.orders o ON oi.order_id = o.id
  WHERE o.status IN ('accepted', 'delivered', 'sent', 'arhivirano')
  GROUP BY oi.product_id
) s ON p.id = s.product_id;

GRANT SELECT ON public.products_with_ratings TO anon;
GRANT SELECT ON public.products_with_ratings TO authenticated;
