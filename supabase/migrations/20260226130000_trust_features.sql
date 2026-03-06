-- Trust i društvo: recenzije, provera, galerija, priča prodavca

-- 1. Recenzije i ocene (kupac može oceniti prodavca i proizvod posle isporuke)
CREATE TABLE IF NOT EXISTS public.reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  buyer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  seller_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
  order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
  rating SMALLINT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(buyer_id, order_id)
);

ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Reviews are viewable by everyone" ON public.reviews;
CREATE POLICY "Reviews are viewable by everyone"
  ON public.reviews FOR SELECT
  TO public
  USING (true);

DROP POLICY IF EXISTS "Buyers can insert own reviews" ON public.reviews;
CREATE POLICY "Buyers can insert own reviews"
  ON public.reviews FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = buyer_id);

-- 2. Provera prodavca (badge „Proveren“)
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT false;

-- 3. Priča prodavca (o gazdinstvu, tradiciji)
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS seller_story TEXT DEFAULT '';

-- 4. Galerija gazdinstva (fotografije farme)
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS farm_gallery_urls TEXT[] DEFAULT '{}';

-- Bucket farm-gallery: Storage → New bucket → farm-gallery (Public)
DROP POLICY IF EXISTS "Public read farm-gallery" ON storage.objects;
CREATE POLICY "Public read farm-gallery"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'farm-gallery');

DROP POLICY IF EXISTS "Sellers upload own farm gallery" ON storage.objects;
CREATE POLICY "Sellers upload own farm gallery"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'farm-gallery' AND (storage.foldername(name))[1] = auth.uid()::text);
