-- ============================================================================
-- Migracija 20261007084500: Auth & Profil hardening
-- 1. Razdvajanje kolona `address` (kupac) i `location` (prodavac) u public.profiles
-- 2. Sinhronizacija postojećih kupaca (prepis adrese iz location u address)
-- 3. Ažuriranje public_profiles view-a sa podrškom za `address`
-- 4. Očvršćavanje check_email_exists RPC: sprečavanje orakla za enumeraciju naloga
-- ============================================================================

-- 1. Dodavanje kolone `address` na public.profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS address TEXT;

-- 2. Sinhronizacija kupaca: ako kupac ima podatke u location, prebaci u address
UPDATE public.profiles
SET address = location
WHERE role = 'buyer' AND address IS NULL AND location IS NOT NULL;

-- 3. Rekonstrukcija public_profiles view-a
CREATE OR REPLACE VIEW public.public_profiles AS
SELECT
  p.id,
  CASE WHEN (auth.uid() = p.id OR EXISTS (
        SELECT 1 FROM public.profiles v WHERE v.id = auth.uid() AND v.is_admin
      )) THEN p.email ELSE NULL END AS email,
  CASE WHEN (p.phone_public OR auth.uid() = p.id OR EXISTS (
        SELECT 1 FROM public.profiles v WHERE v.id = auth.uid() AND v.is_admin
      )) THEN p.phone ELSE NULL END AS phone,
  p.display_name,
  p.city,
  p.postal_code,
  p.role,
  p.is_guest,
  p.farm_name,
  p.location,
  p.profile_image_url,
  p.phone_public,
  p.is_verified,
  p.seller_story,
  p.farm_gallery_urls,
  p.seller_tags,
  p.seller_quick_replies,
  p.is_admin,
  p.lat,
  p.lng,
  p.created_at,
  p.address
FROM public.profiles p;

GRANT SELECT ON public.public_profiles TO anon, authenticated;

-- 4. Očvršćena check_email_exists funkcija protiv enumeracije
CREATE OR REPLACE FUNCTION public.check_email_exists(p_email TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_trimmed TEXT;
  v_allowed BOOLEAN;
BEGIN
  IF p_email IS NULL THEN
    RETURN false;
  END IF;

  v_trimmed := lower(trim(p_email));

  -- Format provera
  IF length(v_trimmed) < 5 OR v_trimmed NOT LIKE '%@%.%' THEN
    RETURN false;
  END IF;

  -- Rate limit: maks 10 provera u 5 minuta (300s) po IP adresi
  v_allowed := public.check_and_record_auth_rate_limit('check_email_exists', 10, 300);
  IF NOT v_allowed THEN
    RAISE EXCEPTION 'Prekoračen dozvoljeni broj provera. Molimo sačekajte nekoliko minuta.'
      USING ERRCODE = 'P0001';
  END IF;

  -- Anti-enumeration zaštita:
  -- Samo administrator ima pravo da direktno proverava postojanje emaila preko ove RPC funkcije.
  -- Za posetioce (anon) i obične korisnike uvek se vraća false kako napadači ne bi mogli
  -- da skeniraju bazu registrovanih korisnika.
  IF public.is_admin() THEN
    RETURN EXISTS (
      SELECT 1 FROM public.profiles WHERE lower(email) = v_trimmed
    );
  END IF;

  RETURN false;
END;
$$;

REVOKE ALL ON FUNCTION public.check_email_exists(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.check_email_exists(TEXT) TO anon, authenticated;
