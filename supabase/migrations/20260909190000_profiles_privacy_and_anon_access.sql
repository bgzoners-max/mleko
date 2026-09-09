-- ============================================================================
-- Migracija 20260909190000: Privatnost tabele profiles i javni pristup za posetioce
--
-- 1. Ažuriranje RLS na public.profiles:
--    Dozvoljava čitanje javnih kolona i neulogovanim korisnicima (anon),
--    čime se rešava problem `profiles: null` (ime/avatar prodavca) u oglasima.
-- 2. Kolonska zaštita (REVOKE SELECT):
--    Oduzimanje SELECT prava nad kolonama email i phone na public.profiles
--    za uloge anon i authenticated.
-- 3. Rekonstrukcija public_profiles view-a sa definer pravima (security_invoker = off)
--    kako bi kroz CASE bezbedno servirao email i phone isključivo vlasniku/adminu.
-- 4. SECURITY DEFINER funkcija check_phone_exists za bezbednu proveru postojanja
--    broja bez izlaganja profila.
-- ============================================================================

-- 1. RLS na public.profiles: dozvoli čitanje svim posetiocima (anon i authenticated)
DROP POLICY IF EXISTS "Profiles are viewable by authenticated users" ON public.profiles;
DROP POLICY IF EXISTS "Profiles are viewable by all users" ON public.profiles;
CREATE POLICY "Profiles are viewable by all users"
  ON public.profiles FOR SELECT
  USING (true);

-- 2. Kolonska zaštita osetljivih podataka na osnovnoj tabeli profiles
REVOKE SELECT (email, phone) ON public.profiles FROM anon, authenticated;

-- Osiguraj da ulogovani korisnici mogu unositi i ažurirati svoj email i telefon
GRANT INSERT (email, phone), UPDATE (email, phone) ON public.profiles TO authenticated;

-- 3. Rekonstrukcija public_profiles view-a
-- View se izvršava sa pravima vlasnika (postgres) kako bi mogao pristupiti kolonama email i phone
-- i bezbedno primeniti logiku maskiranja (CASE WHEN).
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
  p.created_at
FROM public.profiles p;

GRANT SELECT ON public.public_profiles TO anon, authenticated;

-- 4. RPC funkcija za proveru postojanja broja telefona pri registraciji
CREATE OR REPLACE FUNCTION public.check_phone_exists(p_phone TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_phone IS NULL OR trim(p_phone) = '' THEN
    RETURN false;
  END IF;

  RETURN EXISTS (
    SELECT 1 FROM public.profiles WHERE phone = trim(p_phone)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.check_phone_exists(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.check_phone_exists(TEXT) TO anon, authenticated;
