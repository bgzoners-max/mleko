-- View za sortiranje proizvoda po oceni – pravilna paginacija (ORDER BY u bazi)
-- Bez view-a, paginacija po ratingDesc je netačna jer se sortiralo samo unutar stranice.

CREATE OR REPLACE VIEW public.products_with_ratings AS
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
  COALESCE(r.review_count, 0)::bigint AS review_count
FROM public.products p
LEFT JOIN (
  SELECT product_id, AVG(rating)::numeric AS avg_rating, COUNT(*)::bigint AS review_count
  FROM public.reviews
  WHERE product_id IS NOT NULL
  GROUP BY product_id
) r ON p.id = r.product_id;

-- Dozvola za čitanje (anon/authenticated čitaju products)
GRANT SELECT ON public.products_with_ratings TO anon;
GRANT SELECT ON public.products_with_ratings TO authenticated;
