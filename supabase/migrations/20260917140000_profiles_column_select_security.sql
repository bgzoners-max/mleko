-- ============================================================================
-- Sigurnost: Zabrana direktnog čitanja email/phone nad tabelom profiles
-- Datum: 2026-09-17
--
-- PROBLEM:
-- REVOKE SELECT (email, phone) u migraciji 20260909190000 nije imao efekta
-- ukoliko je uloga imala table-level SELECT (PostgreSQL pravilo: table privilege
-- nadjačava column revoke). Zbog toga su osetljivi podaci (email, phone)
-- mogli biti pročitani direktno preko 'profiles' tabele.
--
-- REŠENJE:
-- 1. Oduzmi table-level SELECT sa public.profiles od anon i authenticated.
-- 2. Eksplicitno dodeli kolonski SELECT samo za bezbedne (ne-osetljive) kolone.
-- 3. Pristup email-u i broju telefona ide isključivo kroz SECURITY DEFINER
--    view public_profiles (koji štiti podatke kroz CASE WHEN za vlasnika/admina)
--    ili kroz namensku funkciju check_phone_exists.
-- ============================================================================

-- 1. Oduzmi table-level SELECT privilegiju
REVOKE SELECT ON public.profiles FROM anon, authenticated;

-- 2. Dodeli pravo čitanja isključivo nad bezbednim kolonama
GRANT SELECT (
  id, display_name, city, postal_code, role, is_guest, farm_name, location,
  profile_image_url, phone_public, is_verified, seller_story, farm_gallery_urls,
  seller_tags, seller_quick_replies, is_admin, lat, lng, created_at, updated_at
) ON public.profiles TO anon, authenticated;
