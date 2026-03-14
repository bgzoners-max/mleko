-- Seller -> buyer reviews so both sides have ratings.

CREATE TABLE IF NOT EXISTS public.buyer_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  buyer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  rating SMALLINT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (seller_id, order_id)
);

CREATE INDEX IF NOT EXISTS idx_buyer_reviews_buyer_id
  ON public.buyer_reviews (buyer_id);

CREATE INDEX IF NOT EXISTS idx_buyer_reviews_seller_id
  ON public.buyer_reviews (seller_id);

ALTER TABLE public.buyer_reviews ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Buyer reviews are viewable by everyone" ON public.buyer_reviews;
CREATE POLICY "Buyer reviews are viewable by everyone"
  ON public.buyer_reviews FOR SELECT
  TO public
  USING (true);

DROP POLICY IF EXISTS "Sellers can insert buyer reviews" ON public.buyer_reviews;
CREATE POLICY "Sellers can insert buyer reviews"
  ON public.buyer_reviews FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = seller_id
    AND EXISTS (
      SELECT 1
      FROM public.orders o
      WHERE o.id = order_id
        AND o.seller_id = seller_id
        AND o.buyer_id = buyer_id
        AND (o.status = 'delivered' OR o.status = 'arhivirano')
    )
  );
