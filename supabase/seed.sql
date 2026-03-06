-- Seed: 5 prodavaca, 5 kupaca, proizvodi sa generičkim slikama (Unsplash)
-- Lozinka za sve: password123
-- Pokreće se pri: supabase db reset
--
-- Preduslov: tabele profiles i products moraju postojati (supabase_schema.sql ili migracije)

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ========== POMOĆNA FUNKCIJA: kreiraj korisnika ==========
CREATE OR REPLACE FUNCTION _seed_create_user(
  p_email TEXT,
  p_password TEXT DEFAULT 'password123',
  p_display_name TEXT DEFAULT NULL,
  p_phone TEXT DEFAULT NULL,
  p_city TEXT DEFAULT NULL,
  p_role TEXT DEFAULT 'buyer',
  p_farm_name TEXT DEFAULT NULL,
  p_location TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := gen_random_uuid();
  v_encrypted_pw TEXT := crypt(p_password, gen_salt('bf'));
  v_meta JSONB := jsonb_build_object(
    'display_name', COALESCE(p_display_name, split_part(p_email, '@', 1)),
    'phone', p_phone, 'city', p_city,
    'role', p_role, 'farm_name', p_farm_name, 'location', p_location
  );
BEGIN
  INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
  VALUES (v_user_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', p_email, v_encrypted_pw, NOW(),
    '{"provider":"email","providers":["email"]}', v_meta, NOW(), NOW());

  INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
  VALUES (v_user_id, v_user_id, format('{"sub": "%s", "email": "%s"}', v_user_id, p_email)::jsonb, 'email', v_user_id, NOW(), NOW(), NOW());

  INSERT INTO public.profiles (id, email, display_name, phone, city, role, is_guest, farm_name, location, created_at, updated_at)
  VALUES (v_user_id, p_email, COALESCE(p_display_name, split_part(p_email, '@', 1)), p_phone, p_city, p_role, false, p_farm_name, p_location, NOW(), NOW())
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email, display_name = EXCLUDED.display_name, phone = EXCLUDED.phone,
    city = EXCLUDED.city, role = EXCLUDED.role, farm_name = EXCLUDED.farm_name, location = EXCLUDED.location,
    updated_at = NOW();

  RETURN v_user_id;
END;
$$;

-- ========== 5 PRODAVACA ==========
DO $$
DECLARE
  s1 UUID; s2 UUID; s3 UUID; s4 UUID; s5 UUID;
BEGIN
  s1 := _seed_create_user('prodavac1@test.rs', 'password123', 'Marko Petrović', '0631111111', 'Beograd', 'seller', 'Farma Marković', 'Beograd, Zemun');
  s2 := _seed_create_user('prodavac2@test.rs', 'password123', 'Ana Jovanović', '0632222222', 'Novi Sad', 'seller', 'Seosko dobro Ana', 'Novi Sad, Petrovaradin');
  s3 := _seed_create_user('prodavac3@test.rs', 'password123', 'Stefan Nikolić', '0633333333', 'Kragujevac', 'seller', 'Gazdinstvo Stefan', 'Kragujevac, centar');
  s4 := _seed_create_user('prodavac4@test.rs', 'password123', 'Jelena Đorđević', '0634444444', 'Niš', 'seller', 'Domaći proizvodi Jelena', 'Niš, Palilula');
  s5 := _seed_create_user('prodavac5@test.rs', 'password123', 'Miloš Ilić', '0635555555', 'Subotica', 'seller', 'Miloševo gazdinstvo', 'Subotica, Palić');
END $$;

-- ========== 5 KUPACA ==========
DO $$
DECLARE
  k1 UUID; k2 UUID; k3 UUID; k4 UUID; k5 UUID;
BEGIN
  k1 := _seed_create_user('kupac1@test.rs', 'password123', 'Ivana Marković', '0641111111', 'Beograd', 'buyer');
  k2 := _seed_create_user('kupac2@test.rs', 'password123', 'Nikola Stošić', '0642222222', 'Novi Sad', 'buyer');
  k3 := _seed_create_user('kupac3@test.rs', 'password123', 'Marina Kostić', '0643333333', 'Kragujevac', 'buyer');
  k4 := _seed_create_user('kupac4@test.rs', 'password123', 'Luka Pavlović', '0644444444', 'Niš', 'buyer');
  k5 := _seed_create_user('kupac5@test.rs', 'password123', 'Teodora Milić', '0645555555', 'Subotica', 'buyer');
END $$;

-- ========== PROIZVODI ZA PRODAVCE (sa Unsplash slikama) ==========
-- Slike: sir, meso, mleko, med, džem
INSERT INTO public.products (seller_id, category, name, price_per_kg, min_order_kg, available_kg, description, image_urls, pickup_options, location, is_domestic, available_now)
SELECT p.id, 'Sir', 'Domaći kravlji sir', 1200, 0.5, 50,
  'Tradicionalni sir od svežeg mleka, bez aditiva.',
  ARRAY['https://images.unsplash.com/photo-1618164436241-4473940d1f5c?w=400'],
  ARRAY['Preuzimanje na farmi', 'Dostava u gradu'],
  'Beograd, Zemun', true, true
FROM public.profiles p WHERE p.email = 'prodavac1@test.rs' AND p.role = 'seller'
UNION ALL
SELECT p.id, 'Kobasice', 'Domaće dimljene kobasice', 1500, 0.5, 30,
  'Dimljene na bukovom drvetu, bez konzervansa.',
  ARRAY['https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?w=400'],
  ARRAY['Preuzimanje na farmi'], 'Beograd, Zemun', true, true
FROM public.profiles p WHERE p.email = 'prodavac1@test.rs' AND p.role = 'seller'
UNION ALL
SELECT p.id, 'Šunke i pršute', 'Pršut dimljen', 3500, 0.2, 15,
  'Suva dimljena šunka, tradicionalna receptura.',
  ARRAY['https://images.unsplash.com/photo-1558030006-450675393462?w=400'],
  ARRAY['Preuzimanje na farmi'], 'Beograd, Zemun', true, true
FROM public.profiles p WHERE p.email = 'prodavac1@test.rs' AND p.role = 'seller';

INSERT INTO public.products (seller_id, category, name, price_per_kg, min_order_kg, available_kg, description, image_urls, pickup_options, location, is_domestic, available_now)
SELECT p.id, 'Mleko', 'Sveže kravlje mleko', 180, 1, 100,
  'Sveža dnevna dostava, nepasterizovano.',
  ARRAY['https://images.unsplash.com/photo-1563636619-e9143da7973b?w=400'],
  ARRAY['Preuzimanje na farmi'], 'Novi Sad, Petrovaradin', true, true
FROM public.profiles p WHERE p.email = 'prodavac2@test.rs' AND p.role = 'seller'
UNION ALL
SELECT p.id, 'Džemovi', 'Džem od šljiva', 450, 0.2, 40,
  'Domaći džem bez šećera, prirodna slatkoća voća.',
  ARRAY['https://images.unsplash.com/photo-1595855759920-86582396756a?w=400'],
  ARRAY['Preuzimanje na farmi', 'Dostava'], 'Novi Sad, Petrovaradin', true, true
FROM public.profiles p WHERE p.email = 'prodavac2@test.rs' AND p.role = 'seller';

INSERT INTO public.products (seller_id, category, name, price_per_kg, min_order_kg, available_kg, description, image_urls, pickup_options, location, is_domestic, available_now)
SELECT p.id, 'Med', 'Med od bagrema', 2000, 0.25, 25,
  'Čist med, bez dodataka, iz sopstvenih košnica.',
  ARRAY['https://images.unsplash.com/photo-1587049352846-4a222e784d38?w=400'],
  ARRAY['Preuzimanje na farmi'], 'Kragujevac, centar', true, true
FROM public.profiles p WHERE p.email = 'prodavac3@test.rs' AND p.role = 'seller'
UNION ALL
SELECT p.id, 'Kajmak', 'Domaći kajmak', 1400, 0.2, 20,
  'Tradicionalni kajmak od svežeg mleka.',
  ARRAY['https://images.unsplash.com/photo-1628088062853-00fc69fd4c38?w=400'],
  ARRAY['Preuzimanje na farmi'], 'Kragujevac, centar', true, true
FROM public.profiles p WHERE p.email = 'prodavac3@test.rs' AND p.role = 'seller';

INSERT INTO public.products (seller_id, category, name, price_per_kg, min_order_kg, available_kg, description, image_urls, pickup_options, location, is_domestic, available_now)
SELECT p.id, 'Slanina i panceta', 'Domaća slanina', 1800, 0.3, 20,
  'Suhomesnata slanina, dimljena na tradiconalan način.',
  ARRAY['https://images.unsplash.com/photo-1542838132-92c53300491e?w=400'],
  ARRAY['Preuzimanje na farmi'], 'Niš, Palilula', true, true
FROM public.profiles p WHERE p.email = 'prodavac4@test.rs' AND p.role = 'seller'
UNION ALL
SELECT p.id, 'Jogurt i kiselo mleko', 'Domaći jogurt', 350, 0.5, 60,
  'Prirodni jogurt bez aditiva, kremast.',
  ARRAY['https://images.unsplash.com/photo-1571212515416-ffe4b2d2b6a8?w=400'],
  ARRAY['Preuzimanje na farmi', 'Dostava'], 'Niš, Palilula', true, true
FROM public.profiles p WHERE p.email = 'prodavac4@test.rs' AND p.role = 'seller';

INSERT INTO public.products (seller_id, category, name, price_per_kg, min_order_kg, available_kg, description, image_urls, pickup_options, location, is_domestic, available_now)
SELECT p.id, 'Sveže voće', 'Organska jabuka', 120, 2, 80,
  'Voće iz organske proizvodnje, sezonsko.',
  ARRAY['https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=400'],
  ARRAY['Preuzimanje na farmi'], 'Subotica, Palić', true, true
FROM public.profiles p WHERE p.email = 'prodavac5@test.rs' AND p.role = 'seller'
UNION ALL
SELECT p.id, 'Sir', 'Kačkavalj', 1300, 0.3, 35,
  'Domaći dimljeni kačkavalj, vrhunski kvalitet.',
  ARRAY['https://images.unsplash.com/photo-1452195100486-9cc805987862?w=400'],
  ARRAY['Preuzimanje na farmi'], 'Subotica, Palić', true, true
FROM public.profiles p WHERE p.email = 'prodavac5@test.rs' AND p.role = 'seller';

-- Ukloni pomoćnu funkciju
DROP FUNCTION IF EXISTS _seed_create_user(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT);
