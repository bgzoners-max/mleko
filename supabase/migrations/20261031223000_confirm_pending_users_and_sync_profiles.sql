-- ============================================================================
-- Migracija: 20261031223000_confirm_pending_users_and_sync_profiles.sql
-- Naziv: Potvrda čekanih email registracija (uključujući korisnike kojima SPA ruta /auth/confirm nije otvorila ekran potvrde) i sinhronizacija profila
-- ============================================================================

-- 1. Potvrdi sve registrovane korisnike u auth.users kojima email_confirmed_at još nije postavljen
UPDATE auth.users
SET
  email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
  updated_at = NOW()
WHERE email_confirmed_at IS NULL
  AND email IS NOT NULL
  AND COALESCE((raw_app_meta_data->>'is_anonymous')::boolean, false) = false;

-- 2. Osiguraj da svaki potvrđeni korisnik iz auth.users ima svoj red u public.profiles
INSERT INTO public.profiles (
  id,
  email,
  display_name,
  phone,
  city,
  role,
  farm_name,
  location,
  is_guest,
  created_at,
  updated_at
)
SELECT
  u.id,
  u.email,
  u.raw_user_meta_data->>'display_name',
  u.raw_user_meta_data->>'phone',
  u.raw_user_meta_data->>'city',
  COALESCE(u.raw_user_meta_data->>'role', 'buyer'),
  u.raw_user_meta_data->>'farm_name',
  u.raw_user_meta_data->>'location',
  false,
  COALESCE(u.created_at, NOW()),
  NOW()
FROM auth.users u
WHERE u.email IS NOT NULL
  AND COALESCE((u.raw_app_meta_data->>'is_anonymous')::boolean, false) = false
  AND NOT EXISTS (
    SELECT 1 FROM public.profiles p WHERE p.id = u.id
  )
ON CONFLICT (id) DO NOTHING;
