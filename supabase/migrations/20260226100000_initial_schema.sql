-- Bazne tabele: profiles, products, orders (potrebno za seed i ostatak)
-- Ostale tabele (favorites, categories, itd.) dolaze u kasnijim migracijama

CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT,
  phone TEXT,
  display_name TEXT,
  city TEXT,
  role TEXT DEFAULT 'buyer' CHECK (role IN ('buyer', 'seller')),
  is_guest BOOLEAN DEFAULT false,
  farm_name TEXT,
  location TEXT,
  profile_image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Profiles are viewable by authenticated users" ON public.profiles;
CREATE POLICY "Profiles are viewable by authenticated users" ON public.profiles FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE TO authenticated USING (auth.uid() = id);
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);

CREATE TABLE IF NOT EXISTS public.products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id UUID NOT NULL REFERENCES auth.users(id),
  category TEXT NOT NULL,
  name TEXT NOT NULL,
  price_per_kg NUMERIC NOT NULL,
  min_order_kg NUMERIC DEFAULT 1,
  available_kg NUMERIC DEFAULT 0,
  description TEXT DEFAULT '',
  image_urls TEXT[] DEFAULT '{}',
  pickup_options TEXT[] DEFAULT '{}',
  location TEXT NOT NULL,
  is_domestic BOOLEAN DEFAULT true,
  available_now BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Products are viewable by everyone" ON public.products;
CREATE POLICY "Products are viewable by everyone" ON public.products FOR SELECT TO public USING (true);
DROP POLICY IF EXISTS "Authenticated users can create products" ON public.products;
CREATE POLICY "Authenticated users can create products" ON public.products FOR INSERT TO authenticated WITH CHECK (auth.uid() = seller_id);
DROP POLICY IF EXISTS "Sellers can update own products" ON public.products;
CREATE POLICY "Sellers can update own products" ON public.products FOR UPDATE TO authenticated USING (auth.uid() = seller_id);
DROP POLICY IF EXISTS "Sellers can delete own products" ON public.products;
CREATE POLICY "Sellers can delete own products" ON public.products FOR DELETE TO authenticated USING (auth.uid() = seller_id);

CREATE TABLE IF NOT EXISTS public.orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  buyer_id UUID NOT NULL REFERENCES auth.users(id),
  seller_id UUID NOT NULL REFERENCES auth.users(id),
  product_id UUID NOT NULL,
  product_name TEXT NOT NULL,
  quantity_kg NUMERIC NOT NULL,
  note TEXT DEFAULT '',
  buyer_city TEXT DEFAULT '',
  buyer_phone TEXT NOT NULL,
  prefer_call BOOLEAN DEFAULT true,
  status TEXT DEFAULT 'sent' CHECK (status IN ('sent', 'accepted', 'rejected', 'delivered')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Buyers and sellers can view their orders" ON public.orders;
CREATE POLICY "Buyers and sellers can view their orders" ON public.orders FOR SELECT TO authenticated USING (auth.uid() = buyer_id OR auth.uid() = seller_id);
DROP POLICY IF EXISTS "Authenticated users can create orders" ON public.orders;
CREATE POLICY "Authenticated users can create orders" ON public.orders FOR INSERT TO authenticated WITH CHECK (auth.uid() = buyer_id);
DROP POLICY IF EXISTS "Sellers can update order status" ON public.orders;
CREATE POLICY "Sellers can update order status" ON public.orders FOR UPDATE TO authenticated USING (auth.uid() = seller_id);
