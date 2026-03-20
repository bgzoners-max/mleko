-- Seed: test prodavci/kupci + proizvodi (samo lokalno: `supabase db reset`)
-- Lozinka za sve test naloge: password123
-- Ne primenjuje se na udaljenu bazu osim ako ručno ne pokreneš seed.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ========== POMOĆNA FUNKCIJA: kreiraj korisnika (idempotentno) ==========
CREATE OR REPLACE FUNCTION _seed_create_user(
  p_email TEXT,
  p_password TEXT DEFAULT 'password123',
  p_display_name TEXT DEFAULT NULL,
  p_phone TEXT DEFAULT NULL,
  p_city TEXT DEFAULT NULL,
  p_role TEXT DEFAULT 'buyer',
  p_farm_name TEXT DEFAULT NULL,
  p_location TEXT DEFAULT NULL,
  p_profile_image_url TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
  v_user_id UUID;
  v_encrypted_pw TEXT;
  v_meta JSONB;
BEGIN
  IF EXISTS (SELECT 1 FROM auth.users WHERE email = p_email) THEN
    v_user_id := (SELECT id FROM auth.users WHERE email = p_email LIMIT 1);
    IF p_profile_image_url IS NOT NULL THEN
      UPDATE public.profiles
      SET profile_image_url = p_profile_image_url, updated_at = NOW()
      WHERE id = v_user_id;
    END IF;
    RETURN v_user_id;
  END IF;

  v_user_id := gen_random_uuid();
  v_encrypted_pw := crypt(p_password, gen_salt('bf'));
  v_meta := jsonb_build_object(
    'display_name', COALESCE(p_display_name, split_part(p_email, '@', 1)),
    'phone', p_phone, 'city', p_city,
    'role', p_role, 'farm_name', p_farm_name, 'location', p_location
  );

  INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
  VALUES (v_user_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', p_email, v_encrypted_pw, NOW(),
    '{"provider":"email","providers":["email"]}', v_meta, NOW(), NOW());

  INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
  VALUES (v_user_id, v_user_id, format('{"sub": "%s", "email": "%s"}', v_user_id, p_email)::jsonb, 'email', v_user_id::text, NOW(), NOW(), NOW());

  INSERT INTO public.profiles (id, email, display_name, phone, city, role, is_guest, farm_name, location, profile_image_url, created_at, updated_at)
  VALUES (v_user_id, p_email, COALESCE(p_display_name, split_part(p_email, '@', 1)), p_phone, p_city, p_role, false, p_farm_name, p_location, p_profile_image_url, NOW(), NOW())
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email, display_name = EXCLUDED.display_name, phone = EXCLUDED.phone,
    city = EXCLUDED.city, role = EXCLUDED.role, farm_name = EXCLUDED.farm_name, location = EXCLUDED.location,
    profile_image_url = COALESCE(EXCLUDED.profile_image_url, profiles.profile_image_url),
    updated_at = NOW();

  RETURN v_user_id;
END;
$$;

-- ========== 10 PRODAVACA ==========
DO $$
BEGIN
  PERFORM _seed_create_user('prodavac1@test.rs', 'password123', 'Marko Petrović', '0631111111', 'Beograd', 'seller', 'Farma Marković', 'Beograd, Zemun', NULL);
  PERFORM _seed_create_user('prodavac2@test.rs', 'password123', 'Ana Jovanović', '0632222222', 'Novi Sad', 'seller', 'Seosko dobro Ana', 'Novi Sad, Petrovaradin', NULL);
  PERFORM _seed_create_user('prodavac3@test.rs', 'password123', 'Stefan Nikolić', '0633333333', 'Kragujevac', 'seller', 'Gazdinstvo Stefan', 'Kragujevac, centar', NULL);
  PERFORM _seed_create_user('prodavac4@test.rs', 'password123', 'Jelena Đorđević', '0634444444', 'Niš', 'seller', 'Domaći proizvodi Jelena', 'Niš, Palilula', NULL);
  PERFORM _seed_create_user('prodavac5@test.rs', 'password123', 'Miloš Ilić', '0635555555', 'Subotica', 'seller', 'Miloševo gazdinstvo', 'Subotica, Palić', NULL);
  PERFORM _seed_create_user('prodavac6@test.rs', 'password123', 'Dragana Todorović', '0636666666', 'Kraljevo', 'seller', 'Farma Dragana', 'Kraljevo, centar',
    'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400');
  PERFORM _seed_create_user('prodavac7@test.rs', 'password123', 'Nenad Popović', '0637777777', 'Leskovac', 'seller', 'Seosko Nenad', 'Leskovac, okolina',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400');
  PERFORM _seed_create_user('prodavac8@test.rs', 'password123', 'Snežana Milosavljević', '0638888888', 'Čačak', 'seller', 'Gazdinstvo Snežana', 'Čačak, centar',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400');
  PERFORM _seed_create_user('prodavac9@test.rs', 'password123', 'Vladimir Stojanović', '0639999999', 'Smederevo', 'seller', 'Vladimirova farma', 'Smederevo, vinogradi',
    'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400');
  PERFORM _seed_create_user('prodavac10@test.rs', 'password123', 'Milica Radovanović', '0630000000', 'Valjevo', 'seller', 'Domaće od Milice', 'Valjevo, Kolubara',
    'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400');
END $$;

-- ========== 10 KUPACA ==========
DO $$
BEGIN
  PERFORM _seed_create_user('kupac1@test.rs', 'password123', 'Ivana Marković', '0641111111', 'Beograd', 'buyer', NULL, NULL, NULL);
  PERFORM _seed_create_user('kupac2@test.rs', 'password123', 'Nikola Stošić', '0642222222', 'Novi Sad', 'buyer', NULL, NULL, NULL);
  PERFORM _seed_create_user('kupac3@test.rs', 'password123', 'Marina Kostić', '0643333333', 'Kragujevac', 'buyer', NULL, NULL, NULL);
  PERFORM _seed_create_user('kupac4@test.rs', 'password123', 'Luka Pavlović', '0644444444', 'Niš', 'buyer', NULL, NULL, NULL);
  PERFORM _seed_create_user('kupac5@test.rs', 'password123', 'Teodora Milić', '0645555555', 'Subotica', 'buyer', NULL, NULL, NULL);
  PERFORM _seed_create_user('kupac6@test.rs', 'password123', 'Petar Simić', '0646666666', 'Kraljevo', 'buyer', NULL, NULL,
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400');
  PERFORM _seed_create_user('kupac7@test.rs', 'password123', 'Jovana Đurić', '0647777777', 'Leskovac', 'buyer', NULL, NULL,
    'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400');
  PERFORM _seed_create_user('kupac8@test.rs', 'password123', 'Dušan Antić', '0648888888', 'Čačak', 'buyer', NULL, NULL,
    'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=400');
  PERFORM _seed_create_user('kupac9@test.rs', 'password123', 'Tamara Babić', '0649999999', 'Smederevo', 'buyer', NULL, NULL,
    'https://images.unsplash.com/photo-1547425260-acbc9398fd21?w=400');
  PERFORM _seed_create_user('kupac10@test.rs', 'password123', 'Marko Đorđević', '0640000000', 'Valjevo', 'buyer', NULL, NULL,
    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400');
END $$;

-- ========== PROIZVODI (prodavac 1–5) ==========
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
  'Suhomesnata slanina, dimljena na tradicionalan način.',
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

-- ========== PROIZVODI (prodavac 6–10) ==========
INSERT INTO public.products (seller_id, category, name, price_per_kg, min_order_kg, available_kg, description, image_urls, pickup_options, location, is_domestic, available_now)
SELECT p.id, 'Brašno', 'Organsko brašno', 180, 1, 40, 'Mleveno na kamenu, puno vrednosti.',
  ARRAY['https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=400'], ARRAY['Preuzimanje na farmi'], 'Kraljevo, centar', true, true
FROM public.profiles p WHERE p.email = 'prodavac6@test.rs' AND p.role = 'seller'
AND NOT EXISTS (SELECT 1 FROM public.products WHERE seller_id = p.id LIMIT 1)
UNION ALL
SELECT p.id, 'Ajvar i ljutenica', 'Domaći ajvar', 800, 0.5, 30, 'Prženi ajvar, bez boja.',
  ARRAY['https://images.unsplash.com/photo-1547592180-85f173990554?w=400'], ARRAY['Preuzimanje na farmi'], 'Kraljevo, centar', true, true
FROM public.profiles p WHERE p.email = 'prodavac6@test.rs' AND p.role = 'seller'
AND NOT EXISTS (SELECT 1 FROM public.products WHERE seller_id = p.id LIMIT 1);

INSERT INTO public.products (seller_id, category, name, price_per_kg, min_order_kg, available_kg, description, image_urls, pickup_options, location, is_domestic, available_now)
SELECT p.id, 'Pečenice i vrat', 'Dimljena pečenica', 2200, 0.3, 25, 'Tradicionalna dimljena pečenica.',
  ARRAY['https://images.unsplash.com/photo-1558030006-450675393462?w=400'], ARRAY['Preuzimanje na farmi'], 'Leskovac, okolina', true, true
FROM public.profiles p WHERE p.email = 'prodavac7@test.rs' AND p.role = 'seller'
AND NOT EXISTS (SELECT 1 FROM public.products WHERE seller_id = p.id LIMIT 1)
UNION ALL
SELECT p.id, 'Čvarci', 'Domaći čvarci', 2500, 0.2, 15, 'Čisti svinjski čvarci.',
  ARRAY['https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?w=400'], ARRAY['Preuzimanje na farmi'], 'Leskovac, okolina', true, true
FROM public.profiles p WHERE p.email = 'prodavac7@test.rs' AND p.role = 'seller'
AND NOT EXISTS (SELECT 1 FROM public.products WHERE seller_id = p.id LIMIT 1);

INSERT INTO public.products (seller_id, category, name, price_per_kg, min_order_kg, available_kg, description, image_urls, pickup_options, location, is_domestic, available_now)
SELECT p.id, 'Sveže povrće', 'Sveže šargarepa', 100, 1, 50, 'Organska šargarepa iz sopstvene proizvodnje.',
  ARRAY['https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?w=400'], ARRAY['Preuzimanje na farmi'], 'Čačak, centar', true, true
FROM public.profiles p WHERE p.email = 'prodavac8@test.rs' AND p.role = 'seller'
AND NOT EXISTS (SELECT 1 FROM public.products WHERE seller_id = p.id LIMIT 1)
UNION ALL
SELECT p.id, 'Hleb i pečiva', 'Domaći hleb', 120, 0.5, 20, 'Hleb pečen u tradicionalnoj peći.',
  ARRAY['https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400'], ARRAY['Preuzimanje na farmi'], 'Čačak, centar', true, true
FROM public.profiles p WHERE p.email = 'prodavac8@test.rs' AND p.role = 'seller'
AND NOT EXISTS (SELECT 1 FROM public.products WHERE seller_id = p.id LIMIT 1);

INSERT INTO public.products (seller_id, category, name, price_per_kg, min_order_kg, available_kg, description, image_urls, pickup_options, location, is_domestic, available_now)
SELECT p.id, 'Prirodni sokovi', 'Sok od grožđa', 350, 1, 60, 'Prirodan sok, bez šećera.',
  ARRAY['https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?w=400'], ARRAY['Preuzimanje na farmi'], 'Smederevo, vinogradi', true, true
FROM public.profiles p WHERE p.email = 'prodavac9@test.rs' AND p.role = 'seller'
AND NOT EXISTS (SELECT 1 FROM public.products WHERE seller_id = p.id LIMIT 1)
UNION ALL
SELECT p.id, 'Lekovito bilje', 'Sušeno bilje', 400, 0.1, 25, 'Lekovite biljke za čaj.',
  ARRAY['https://images.unsplash.com/photo-1515694346937-94d85e41e6f0?w=400'], ARRAY['Preuzimanje na farmi'], 'Smederevo, vinogradi', true, true
FROM public.profiles p WHERE p.email = 'prodavac9@test.rs' AND p.role = 'seller'
AND NOT EXISTS (SELECT 1 FROM public.products WHERE seller_id = p.id LIMIT 1);

INSERT INTO public.products (seller_id, category, name, price_per_kg, min_order_kg, available_kg, description, image_urls, pickup_options, location, is_domestic, available_now)
SELECT p.id, 'Kokošija jaja', 'Seloška jaja', 280, 0.5, 80, 'Jaja od kokošaka iz slobodnog uzgoja.',
  ARRAY['https://images.unsplash.com/photo-1582722872445-44dc5f7e3c8f?w=400'], ARRAY['Preuzimanje na farmi'], 'Valjevo, Kolubara', true, true
FROM public.profiles p WHERE p.email = 'prodavac10@test.rs' AND p.role = 'seller'
AND NOT EXISTS (SELECT 1 FROM public.products WHERE seller_id = p.id LIMIT 1)
UNION ALL
SELECT p.id, 'Pavlaka i namazi', 'Pavlaka domaća', 950, 0.2, 35, 'Sveža pavlaka od svežeg mleka.',
  ARRAY['https://images.unsplash.com/photo-1628088062853-00fc69fd4c38?w=400'], ARRAY['Preuzimanje na farmi'], 'Valjevo, Kolubara', true, true
FROM public.profiles p WHERE p.email = 'prodavac10@test.rs' AND p.role = 'seller'
AND NOT EXISTS (SELECT 1 FROM public.products WHERE seller_id = p.id LIMIT 1);

DROP FUNCTION IF EXISTS _seed_create_user(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT);
