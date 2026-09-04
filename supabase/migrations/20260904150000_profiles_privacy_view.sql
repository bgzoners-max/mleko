-- ============================================================================
-- Migracija 20260904150000: Privacy — javni prikaz profila bez osetljivih podataka
--
-- RLS na `profiles` dozvoljava svakom prijavljenom da čita SVE kolone svih
-- korisnika (uključujući `email` i `phone`). Ovaj view maskira osetljive
-- kolone i služi kao jedini javni izvor profila sa klijenta:
--   - `email`  vidí samo vlasnik ili admin
--   - `phone`  vidí vlasnik, admin, ili bilo ko ako je `phone_public = true`
-- ============================================================================

-- Osiguraj da kolona postal_code postoji na profiles tabeli
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS postal_code TEXT;

CREATE OR REPLACE VIEW public.public_profiles
WITH (security_invoker = on)
AS
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

-- Performanse: bezbedan indeks za auth subquery (auth.uid() = profile id)
CREATE INDEX IF NOT EXISTS idx_profiles_is_admin ON public.profiles(id, is_admin);