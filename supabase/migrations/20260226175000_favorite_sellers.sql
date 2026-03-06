-- Omiljeni prodavci (kupac prati prodavce) – potrebno za get_products_from_favorite_sellers

CREATE TABLE IF NOT EXISTS public.favorite_sellers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  seller_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, seller_id)
);

ALTER TABLE public.favorite_sellers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage own favorite sellers" ON public.favorite_sellers;
CREATE POLICY "Users manage own favorite sellers"
  ON public.favorite_sellers FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
