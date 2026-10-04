-- ============================================================================
-- Migration: Podrška za Google / OAuth korisničke profile
-- ============================================================================
-- Kada se korisnik prijavi preko Google OAuth-a:
-- 1. Ime se preuzima iz full_name ili name (ako display_name nije prosleđen)
-- 2. Profilna slika se preuzima iz avatar_url ili picture
-- 3. Zadržavaju se postojeće korisničke izmene ako korisnik već postoji

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (
    id, email, display_name, phone, city, role, farm_name, location, is_guest, profile_image_url
  )
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(
      NEW.raw_user_meta_data->>'display_name',
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'name'
    ),
    NEW.raw_user_meta_data->>'phone',
    NEW.raw_user_meta_data->>'city',
    COALESCE(NEW.raw_user_meta_data->>'role', 'buyer'),
    NEW.raw_user_meta_data->>'farm_name',
    NEW.raw_user_meta_data->>'location',
    COALESCE((NEW.raw_app_meta_data->>'is_anonymous')::boolean, false),
    COALESCE(
      NEW.raw_user_meta_data->>'avatar_url',
      NEW.raw_user_meta_data->>'picture'
    )
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    display_name = COALESCE(profiles.display_name, EXCLUDED.display_name),
    phone = COALESCE(profiles.phone, EXCLUDED.phone),
    city = COALESCE(profiles.city, EXCLUDED.city),
    role = profiles.role,
    farm_name = COALESCE(profiles.farm_name, EXCLUDED.farm_name),
    location = COALESCE(profiles.location, EXCLUDED.location),
    profile_image_url = COALESCE(profiles.profile_image_url, EXCLUDED.profile_image_url),
    updated_at = NOW();
  RETURN NEW;
END;
$$;
