-- Još 5 prodavaca i 5 kupaca sa profilnim slikama (Unsplash)
-- Lozinka: password123

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE OR REPLACE FUNCTION _seed_test_user(
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
      UPDATE public.profiles SET profile_image_url = p_profile_image_url, updated_at = NOW() WHERE id = v_user_id;
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

-- 5 novih prodavaca sa slikama
SELECT _seed_test_user('prodavac6@test.rs', 'password123', 'Dragana Todorović', '0636666666', 'Kraljevo', 'seller', 'Farma Dragana', 'Kraljevo, centar',
  'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400');
SELECT _seed_test_user('prodavac7@test.rs', 'password123', 'Nenad Popović', '0637777777', 'Leskovac', 'seller', 'Seosko Nenad', 'Leskovac, okolina',
  'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400');
SELECT _seed_test_user('prodavac8@test.rs', 'password123', 'Snežana Milosavljević', '0638888888', 'Čačak', 'seller', 'Gazdinstvo Snežana', 'Čačak, centar',
  'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400');
SELECT _seed_test_user('prodavac9@test.rs', 'password123', 'Vladimir Stojanović', '0639999999', 'Smederevo', 'seller', 'Vladimirova farma', 'Smederevo, vinogradi',
  'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400');
SELECT _seed_test_user('prodavac10@test.rs', 'password123', 'Milica Radovanović', '0630000000', 'Valjevo', 'seller', 'Domaće od Milice', 'Valjevo, Kolubara',
  'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400');

-- 5 novih kupaca sa slikama
SELECT _seed_test_user('kupac6@test.rs', 'password123', 'Petar Simić', '0646666666', 'Kraljevo', 'buyer', NULL, NULL,
  'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400');
SELECT _seed_test_user('kupac7@test.rs', 'password123', 'Jovana Đurić', '0647777777', 'Leskovac', 'buyer', NULL, NULL,
  'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400');
SELECT _seed_test_user('kupac8@test.rs', 'password123', 'Dušan Antić', '0648888888', 'Čačak', 'buyer', NULL, NULL,
  'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=400');
SELECT _seed_test_user('kupac9@test.rs', 'password123', 'Tamara Babić', '0649999999', 'Smederevo', 'buyer', NULL, NULL,
  'https://images.unsplash.com/photo-1547425260-acbc9398fd21?w=400');
SELECT _seed_test_user('kupac10@test.rs', 'password123', 'Marko Đorđević', '0640000000', 'Valjevo', 'buyer', NULL, NULL,
  'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400');

DROP FUNCTION IF EXISTS _seed_test_user(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS _seed_test_user(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT);

-- Proizvodi za nove prodavce
INSERT INTO public.products (seller_id, category, name, price_per_kg, min_order_kg, available_kg, description, image_urls, pickup_options, location, is_domestic, available_now)
SELECT p.id, 'Brašno', 'Organsko brašno', 180, 1, 40, 'Mleveno na kamenu, puno vrednosti.',
  ARRAY['https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=400'], ARRAY['Preuzimanje na farmi'], 'Kraljevo, centar', true, true
FROM public.profiles p WHERE p.email = 'prodavac6@test.rs' AND p.role = 'seller'
AND NOT EXISTS (SELECT 1 FROM public.products WHERE seller_id = p.id LIMIT 1)
UNION ALL
SELECT p.id, 'Ajvar i ljutenica', 'Domaci ajvar', 800, 0.5, 30, 'Prženi ajvar, bez boja.',
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
