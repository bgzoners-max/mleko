-- Pokreni u Supabase SQL Editor (Dashboard → SQL Editor → New query)

-- 1. Profili korisnika (povezani sa auth.users)
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

-- RLS za profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Profiles are viewable by authenticated users" ON public.profiles;
CREATE POLICY "Profiles are viewable by authenticated users"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- 2. Proizvodi
CREATE TABLE IF NOT EXISTS public.products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id UUID NOT NULL REFERENCES auth.users(id),
  category TEXT NOT NULL,
  name TEXT NOT NULL,
  price_per_kg NUMERIC NOT NULL,
  min_order_kg NUMERIC DEFAULT 1,
  available_kg NUMERIC DEFAULT 0,
  unit_type TEXT NOT NULL DEFAULT 'kg' CHECK (unit_type IN ('kg', 'L', 'g', 'kom')),
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
CREATE POLICY "Products are viewable by everyone"
  ON public.products FOR SELECT
  TO public
  USING (true);

DROP POLICY IF EXISTS "Authenticated users can create products" ON public.products;
CREATE POLICY "Authenticated users can create products"
  ON public.products FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = seller_id);

DROP POLICY IF EXISTS "Sellers can update own products" ON public.products;
CREATE POLICY "Sellers can update own products"
  ON public.products FOR UPDATE
  TO authenticated
  USING (auth.uid() = seller_id);

DROP POLICY IF EXISTS "Sellers can delete own products" ON public.products;
CREATE POLICY "Sellers can delete own products"
  ON public.products FOR DELETE
  TO authenticated
  USING (auth.uid() = seller_id);

-- 3. Porudžbine
CREATE TABLE IF NOT EXISTS public.orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  buyer_id UUID NOT NULL REFERENCES auth.users(id),
  seller_id UUID NOT NULL REFERENCES auth.users(id),
  product_id UUID,
  product_name TEXT,
  quantity_kg NUMERIC,
  unit_type TEXT NOT NULL DEFAULT 'kg' CHECK (unit_type IN ('kg', 'L', 'g', 'kom')),
  note TEXT DEFAULT '',
  buyer_city TEXT DEFAULT '',
  buyer_phone TEXT NOT NULL,
  prefer_call BOOLEAN DEFAULT true,
  status TEXT DEFAULT 'sent' CHECK (status IN ('sent', 'accepted', 'rejected', 'delivered')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Buyers and sellers can view their orders" ON public.orders;
CREATE POLICY "Buyers and sellers can view their orders"
  ON public.orders FOR SELECT
  TO authenticated
  USING (auth.uid() = buyer_id OR auth.uid() = seller_id);

DROP POLICY IF EXISTS "Authenticated users can create orders" ON public.orders;
CREATE POLICY "Authenticated users can create orders"
  ON public.orders FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = buyer_id);

DROP POLICY IF EXISTS "Sellers can update order status" ON public.orders;
CREATE POLICY "Sellers can update order status"
  ON public.orders FOR UPDATE
  TO authenticated
  USING (auth.uid() = seller_id);

-- Trigger za auto-kreiranje profila pri signup (email ili anon)
-- SECURITY DEFINER = izvršava se sa pravima vlasnika (bypass RLS)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (
    id, email, display_name, phone, city, role, farm_name, location, is_guest
  )
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'display_name',
    NEW.raw_user_meta_data->>'phone',
    NEW.raw_user_meta_data->>'city',
    COALESCE(NEW.raw_user_meta_data->>'role', 'buyer'),
    NEW.raw_user_meta_data->>'farm_name',
    NEW.raw_user_meta_data->>'location',
    COALESCE((NEW.raw_app_meta_data->>'is_anonymous')::boolean, false)
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    display_name = COALESCE(EXCLUDED.display_name, profiles.display_name),
    phone = COALESCE(EXCLUDED.phone, profiles.phone),
    city = COALESCE(EXCLUDED.city, profiles.city),
    role = EXCLUDED.role,
    farm_name = COALESCE(EXCLUDED.farm_name, profiles.farm_name),
    location = COALESCE(EXCLUDED.location, profiles.location),
    updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 4. Omiljeni proizvodi (kupac)
CREATE TABLE IF NOT EXISTS public.favorites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, product_id)
);

ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users manage own favorites" ON public.favorites;
CREATE POLICY "Users manage own favorites"
  ON public.favorites FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 5. Omiljeni prodavci (kupac prati prodavce)
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

-- 6. Notifikacije (in-app, promena statusa porudžbine)
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT DEFAULT '',
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users see own notifications" ON public.notifications;
CREATE POLICY "Users see own notifications"
  ON public.notifications FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 7. Koordinate za mapu (opciono u profiles)
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS lat NUMERIC;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS lng NUMERIC;

-- Trigger: notifikacija kupcu kada prodavac promeni status porudžbine
CREATE OR REPLACE FUNCTION public.notify_order_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    INSERT INTO notifications (user_id, order_id, type, title, body)
    VALUES (
      NEW.buyer_id,
      NEW.id,
      'order_status',
      'Porudžbina ažurirana',
      'Proizvod: ' || NEW.product_name || ' – ' || NEW.status
    );
  END IF;
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS on_order_status_change ON public.orders;
CREATE TRIGGER on_order_status_change
  AFTER UPDATE ON public.orders
  FOR EACH ROW EXECUTE FUNCTION public.notify_order_status_change();

-- Trigger: obaveštenje prodavcu kada kupac pošalje novu porudžbinu
CREATE OR REPLACE FUNCTION public.notify_new_order()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO notifications (user_id, order_id, type, title, body)
  VALUES (
    NEW.seller_id,
    NEW.id,
    'new_order',
    'Nova porudžbina',
    'Proizvod: ' || NEW.product_name || ' – ' || NEW.quantity_kg::text || ' kg'
  );
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS on_new_order ON public.orders;
CREATE TRIGGER on_new_order
  AFTER INSERT ON public.orders
  FOR EACH ROW EXECUTE FUNCTION public.notify_new_order();

-- Storage RLS – dozvoli upload i čitanje za profiles i product-images
DROP POLICY IF EXISTS "Public read profiles" ON storage.objects;
CREATE POLICY "Public read profiles"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'profiles');

DROP POLICY IF EXISTS "Authenticated upload profiles" ON storage.objects;
CREATE POLICY "Authenticated upload profiles"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'profiles' AND name = (auth.uid())::text || '.jpg');

DROP POLICY IF EXISTS "Authenticated update profiles" ON storage.objects;
CREATE POLICY "Authenticated update profiles"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (bucket_id = 'profiles' AND name = auth.uid()::text || '.jpg');

DROP POLICY IF EXISTS "Public read product-images" ON storage.objects;
CREATE POLICY "Public read product-images"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'product-images');

DROP POLICY IF EXISTS "Authenticated upload product-images" ON storage.objects;
CREATE POLICY "Authenticated upload product-images"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'product-images');
