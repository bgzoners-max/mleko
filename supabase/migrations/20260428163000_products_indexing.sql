-- Optimizacija performansi za tabelu products
-- Dodavanje indeksa za kolone koje se najčešće koriste u filterima i sortiranju

-- 1. Indeks za seller_id (prikaz svih proizvoda jednog prodavca)
CREATE INDEX IF NOT EXISTS idx_products_seller_id ON public.products(seller_id);

-- 2. Indeks za category (filtriranje po kategoriji)
CREATE INDEX IF NOT EXISTS idx_products_category ON public.products(category);

-- 3. Indeks za location (filtriranje po regiji)
CREATE INDEX IF NOT EXISTS idx_products_location ON public.products(location);

-- 4. Indeks za datum kreiranja (osnovno sortiranje "Najnovije")
CREATE INDEX IF NOT EXISTS idx_products_created_at_desc ON public.products(created_at DESC);

-- 5. Kombinovani indeks za dostupnost (čest filter na pretrazi)
CREATE INDEX IF NOT EXISTS idx_products_available_now ON public.products(available_now) WHERE available_now = true;
