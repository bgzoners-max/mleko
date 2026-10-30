-- ============================================================================
-- Migracija: 20261030170000_seller_bpg_pib_and_liability.sql
-- Naziv: BPG (12 cifara) / PIB (9 cifara) identifikacija proizvođača hrane i pravna odgovornost
-- ============================================================================

-- 1. Dodavanje kolona za pravni status proizvođača hrane na tabelu `public.profiles`
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS legal_type TEXT,
  ADD COLUMN IF NOT EXISTS bpg TEXT,
  ADD COLUMN IF NOT EXISTS pib TEXT,
  ADD COLUMN IF NOT EXISTS legal_liability_accepted_at TIMESTAMPTZ;

-- 2. CHECK ograničenja za format BPG (tačno 12 cifara, ne sve iste cifre) i PIB (tačno 9 cifara, prva nije 0)
ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_legal_type_check,
  ADD CONSTRAINT profiles_legal_type_check
    CHECK (legal_type IS NULL OR legal_type IN ('rpg', 'company'));

ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_bpg_format_check,
  ADD CONSTRAINT profiles_bpg_format_check
    CHECK (bpg IS NULL OR (bpg ~ '^\d{12}$' AND bpg !~ '^(\d)\1{11}$'));

ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_pib_format_check,
  ADD CONSTRAINT profiles_pib_format_check
    CHECK (pib IS NULL OR pib ~ '^[1-9]\d{8}$');

-- 3. Funkcija za proveru kontrolne cifre PIB-a po standardu ISO 7064, MOD (11, 10)
CREATE OR REPLACE FUNCTION public.is_valid_serbian_pib(p_pib TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
IMMUTABLE
SET search_path = public
AS $$
DECLARE
  v_rem INT := 10;
  v_digit INT;
  v_check INT;
  i INT;
BEGIN
  IF p_pib IS NULL THEN
    RETURN TRUE;
  END IF;
  IF p_pib !~ '^[1-9]\d{8}$' THEN
    RETURN FALSE;
  END IF;

  FOR i IN 1..8 LOOP
    v_digit := CAST(SUBSTRING(p_pib FROM i FOR 1) AS INT);
    v_rem := (v_rem + v_digit) % 10;
    IF v_rem = 0 THEN
      v_rem := 10;
    END IF;
    v_rem := (v_rem * 2) % 11;
  END LOOP;

  v_check := (11 - v_rem) % 10;
  RETURN v_check = CAST(SUBSTRING(p_pib FROM 9 FOR 1) AS INT);
END;
$$;

ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_pib_checksum_check,
  ADD CONSTRAINT profiles_pib_checksum_check
    CHECK (public.is_valid_serbian_pib(pib));

-- 4. Ažuriranje pogleda `public.public_profiles`
--    BPG (pun broj) vide samo vlasnik profila i administrator (ZZPL/GDPR zaštita),
--    dok svi posetioci vide maskirani BPG (`••••••••1234`), `legal_type`, `pib` (javni podatak APR-a)
--    i izvedeno polje `has_registered_entity` za prikaz bedža „Verifikovano gazdinstvo (BPG) / Registrovani proizvođač”.
CREATE OR REPLACE VIEW public.public_profiles AS
SELECT
  p.id,
  CASE WHEN ((SELECT auth.uid()) = p.id OR (SELECT public.is_admin())) THEN p.email ELSE NULL END AS email,
  CASE WHEN (p.phone_public OR (SELECT auth.uid()) = p.id OR (SELECT public.is_admin())) THEN p.phone ELSE NULL END AS phone,
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
  CASE WHEN ((SELECT auth.uid()) = p.id OR (SELECT public.is_admin())) THEN p.address ELSE NULL END AS address,
  p.legal_type,
  CASE WHEN ((SELECT auth.uid()) = p.id OR (SELECT public.is_admin())) THEN p.bpg ELSE NULL END AS bpg,
  CASE WHEN (p.bpg IS NOT NULL AND length(p.bpg) = 12) THEN ('••••••••' || right(p.bpg, 4)) ELSE NULL END AS bpg_masked,
  p.pib,
  ((p.bpg IS NOT NULL AND length(p.bpg) = 12) OR (p.pib IS NOT NULL AND length(p.pib) = 9)) AS has_registered_entity,
  p.legal_liability_accepted_at
FROM public.profiles p
WHERE (
  (SELECT auth.uid()) = p.id
  OR (SELECT public.is_admin())
  OR (p.role = 'seller' OR p.farm_name IS NOT NULL)
  OR EXISTS (
    SELECT 1 FROM public.classified_ads ca
    WHERE ca.user_id = p.id AND ca.status = 'active'
  )
  OR EXISTS (
    SELECT 1 FROM public.reviews r
    WHERE r.buyer_id = p.id
  )
  OR EXISTS (
    SELECT 1 FROM public.orders o
    WHERE o.buyer_id = p.id AND o.seller_id = (SELECT auth.uid())
  )
  OR EXISTS (
    SELECT 1 FROM public.conversations c
    WHERE (c.buyer_id = p.id AND c.seller_id = (SELECT auth.uid()))
       OR (c.seller_id = p.id AND c.buyer_id = (SELECT auth.uid()))
  )
);

ALTER VIEW public.public_profiles SET (security_invoker = false);
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.public_profiles FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.public_profiles TO anon, authenticated;

