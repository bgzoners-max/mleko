-- ============================================================================
-- Migracija: 20260929100000_security_audit_hardening.sql
-- Bezbednosno očvršćavanje celokupnog sistema (Security Audit Hardening)
--
-- 1. PROFILES (SEC-01 - Kritično):
--    - Sprečava eskalaciju privilegija u administratora (is_admin) i verifikaciju (is_verified)
--      putem direktnog UPDATE ili INSERT upita od strane ne-administratora.
--    - Zaključava primarni ključ 'id' i 'created_at'.
--
-- 2. CLASSIFIED_ADS PRIVATNOST TELEFONA (SEC-02 - Visoko):
--    - Oduzima table-level SELECT privilegiju nad classified_ads za anon i authenticated.
--    - Eksplicitno dodeljuje kolonski SELECT isključivo nad bezbednim kolonama (bez 'phone').
--    - Telefon ostaje dostupan isključivo kroz rate-limitovanu RPC funkciju get_classified_ad_phone
--      ili kroz SECURITY DEFINER view public_classified_ads sa ugrađenim maskiranjem.
--
-- 3. CLASSIFIED_ADS BEDŽEVI I MODERACIJA (SEC-06 - Srednje):
--    - Sprečava samostalno postavljanje promotivnih statusa (is_featured, is_urgent)
--      i resetovanje brojača prijava (reports_count) od strane vlasnika oglasa.
--    - Zaključava kolonu 'user_id' od naknadne izmene.
--
-- 4. ORDERS STATUS I INTEGRITET (SEC-03 & SEC-04 - Visoko):
--    - Forsira status = 'sent' na svim novim porudžbinama (sprečava direktan insert 'delivered').
--    - Proširuje trg_enforce_order_status_transition na sve UPDATE operacije (uklanja 'OF status'),
--      čime se garantuje da učesnici (buyer_id, seller_id) i osnovni parametri porudžbine
--      nikada ne mogu biti izmenjeni.
--
-- 5. REVIEWS INTEGRITET RECENZIJA (SEC-05 - Srednje-visoko):
--    - Zahteva da recenzija kupca (public.reviews) obavezno ima povezan order_id.
--    - Proverava da li je porudžbina u statusu 'delivered' ili 'arhivirano/archived'
--      i da li kupac zaista pripada toj porudžbini pre unosa ocene.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. ZAŠTITA TABELE PROFILES (SEC-01)
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.protect_profile_sensitive_columns()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_is_caller_admin BOOLEAN := false;
BEGIN
  -- Identifikuj da li je pozivalac admin ili service_role
  IF auth.uid() IS NOT NULL THEN
    v_is_caller_admin := public.is_admin();
  ELSE
    -- Sistemski / service_role kontekst (npr. background trigger ili CLI)
    v_is_caller_admin := true;
  END IF;

  IF TG_OP = 'INSERT' THEN
    -- Običan korisnik ne sme sam sebi postaviti is_admin niti is_verified pri registraciji
    IF NOT v_is_caller_admin THEN
      NEW.is_admin := false;
      NEW.is_verified := false;
    ELSE
      NEW.is_admin := COALESCE(NEW.is_admin, false);
      NEW.is_verified := COALESCE(NEW.is_verified, false);
    END IF;
    NEW.created_at := COALESCE(NEW.created_at, now());
    NEW.updated_at := COALESCE(NEW.updated_at, now());
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' THEN
    -- ID i created_at su strogo nepromenjivi
    NEW.id := OLD.id;
    NEW.created_at := OLD.created_at;
    NEW.updated_at := now();

    -- Zaštita kolone is_admin: samo administrator sme menjati admin status
    IF NEW.is_admin IS DISTINCT FROM OLD.is_admin THEN
      IF NOT v_is_caller_admin THEN
        RAISE EXCEPTION USING
          ERRCODE = '42501',
          MESSAGE = 'Nemate administratorska ovlašćenja za promenu admin statusa.';
      END IF;
    END IF;

    -- Zaštita kolone is_verified: samo administrator sme verifikovati prodavca
    IF NEW.is_verified IS DISTINCT FROM OLD.is_verified THEN
      IF NOT v_is_caller_admin THEN
        RAISE EXCEPTION USING
          ERRCODE = '42501',
          MESSAGE = 'Nemate administratorska ovlašćenja za promenu statusa verifikacije.';
      END IF;
    END IF;

    RETURN NEW;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_profile_sensitive_columns ON public.profiles;
CREATE TRIGGER trg_protect_profile_sensitive_columns
  BEFORE INSERT OR UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_profile_sensitive_columns();


-- ----------------------------------------------------------------------------
-- 2. ZAŠTITA PRIVATNOSTI TELEFONA NA CLASSIFIED_ADS (SEC-02)
-- ----------------------------------------------------------------------------

-- Oduzmi table-level SELECT privilegiju koja je zaobilazila kolonski REVOKE
REVOKE SELECT ON public.classified_ads FROM anon, authenticated;

-- Dodeljuj eksplicitno SELECT pravo isključivo nad bezbednim kolonama (bez 'phone')
GRANT SELECT (
  id,
  user_id,
  category_id,
  title,
  description,
  price,
  currency,
  price_type,
  city,
  condition,
  status,
  images,
  phone_public,
  views_count,
  last_view_at,
  created_at,
  updated_at,
  is_featured,
  featured_until,
  is_urgent,
  reports_count,
  call_clicks_count,
  attributes
) ON public.classified_ads TO anon, authenticated;


-- ----------------------------------------------------------------------------
-- 3. ZAŠTITA BEDŽEVA I MODERACIJE NA CLASSIFIED_ADS (SEC-06)
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.protect_classified_ad_administrative_columns()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_is_caller_admin BOOLEAN := false;
BEGIN
  IF auth.uid() IS NOT NULL THEN
    v_is_caller_admin := public.is_admin();
  ELSE
    v_is_caller_admin := true;
  END IF;

  IF TG_OP = 'INSERT' THEN
    -- Novi oglas koji postavlja običan korisnik ne može imati promo bedževe niti lažiranu analitiku
    IF NOT v_is_caller_admin THEN
      NEW.is_featured := false;
      NEW.featured_until := NULL;
      NEW.is_urgent := false;
      NEW.reports_count := 0;
      NEW.call_clicks_count := 0;
      NEW.views_count := 0;
    END IF;
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' THEN
    -- Spreči otimanje oglasa (user_id se nikada ne menja)
    NEW.user_id := OLD.user_id;

    -- Samo administrator može menjati istaknutost ili resetovati prijave
    IF NOT v_is_caller_admin THEN
      NEW.is_featured := OLD.is_featured;
      NEW.featured_until := OLD.featured_until;
      NEW.is_urgent := OLD.is_urgent;
      NEW.reports_count := OLD.reports_count;
      NEW.call_clicks_count := OLD.call_clicks_count;
      NEW.views_count := OLD.views_count;
    END IF;
    RETURN NEW;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_classified_ad_administrative_columns ON public.classified_ads;
CREATE TRIGGER trg_protect_classified_ad_administrative_columns
  BEFORE INSERT OR UPDATE ON public.classified_ads
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_classified_ad_administrative_columns();


-- ----------------------------------------------------------------------------
-- 4. ORDERS STATUS I INTEGRITET PODATAKA (SEC-03 & SEC-04)
-- ----------------------------------------------------------------------------

-- 4.1 Forsiranje statusa 'sent' na novim porudžbinama
CREATE OR REPLACE FUNCTION public.enforce_new_order_defaults()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Svaka nova porudžbina uneta preko klijentskog API-ja mora početi u stanju 'sent'
  NEW.status := 'sent';
  NEW.created_at := COALESCE(NEW.created_at, now());
  NEW.status_changed_at := now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_new_order_defaults ON public.orders;
CREATE TRIGGER trg_enforce_new_order_defaults
  BEFORE INSERT ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_new_order_defaults();

-- 4.2 Proširenje trg_enforce_order_status_transition na SVE izmene porudžbine
-- (Uklanja se restrikcija "OF status" kako bi triger branio kupca, prodavca i detalje porudžbine)
DROP TRIGGER IF EXISTS trg_enforce_order_status_transition ON public.orders;
CREATE TRIGGER trg_enforce_order_status_transition
  BEFORE UPDATE ON public.orders
  FOR EACH ROW
  EXECUTE PROCEDURE public.enforce_order_status_transition();


-- ----------------------------------------------------------------------------
-- 5. REVIEWS INTEGRITET RECENZIJA (SEC-05)
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.validate_buyer_review_submission()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_order_status TEXT;
  v_order_buyer UUID;
  v_order_seller UUID;
BEGIN
  -- Recenzija mora biti vezana za stvarnu porudžbinu
  IF NEW.order_id IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = '23502',
      MESSAGE = 'Recenzija mora biti vezana za realizovanu porudžbinu.';
  END IF;

  -- Proveri postojanje porudžbine i verifikuj učesnike i status
  SELECT status, buyer_id, seller_id
    INTO v_order_status, v_order_buyer, v_order_seller
  FROM public.orders
  WHERE id = NEW.order_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = '23503',
      MESSAGE = 'Navedena porudžbina ne postoji u sistemu.';
  END IF;

  -- Samo kupac iz te konkretne porudžbine može ostaviti recenziju
  IF v_uid IS NOT NULL AND v_order_buyer <> v_uid THEN
    RAISE EXCEPTION USING
      ERRCODE = '42501',
      MESSAGE = 'Možete ostaviti recenziju isključivo za sopstvenu porudžbinu.';
  END IF;

  -- Recenzirani prodavac mora odgovarati prodavcu iz porudžbine
  IF NEW.seller_id <> v_order_seller THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'Prodavac u recenziji se ne poklapa sa prodavcem iz porudžbine.';
  END IF;

  -- Porudžbina mora biti uspešno isporučena ili arhivirana
  IF v_order_status NOT IN ('delivered', 'arhivirano', 'archived') THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'Recenziju možete ostaviti tek nakon što je porudžbina isporučena.',
      DETAIL = format('order_status=%s', v_order_status);
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_buyer_review_submission ON public.reviews;
CREATE TRIGGER trg_validate_buyer_review_submission
  BEFORE INSERT ON public.reviews
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_buyer_review_submission();
