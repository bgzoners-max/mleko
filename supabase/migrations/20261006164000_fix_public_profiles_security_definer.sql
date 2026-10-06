-- ============================================================================
-- Fix: public_profiles i public_classified_ads moraju biti SECURITY DEFINER
-- Datum: 2026-10-06
--
-- PROBLEM:
-- Tabela public.profiles ima REVOKE SELECT za anon i authenticated kako bi se
-- sprečilo curenje privatnih kolona (email, telefon).
-- View-ovi public_profiles i public_classified_ads su imali uključen
-- security_invoker = true, zbog čega je PostgreSQL proveravao privilegije
-- pozivaoca nad osnovnom tabelom profiles i vraćao grešku 42501:
-- "permission denied for table profiles".
--
-- REŠENJE:
-- 1. Postavi security_invoker = false na public_profiles i public_classified_ads.
-- 2. View se izvršava sa pravima vlasnika (postgres), a interna CASE WHEN logika
--    view-a bezbedno maskira email i telefon ako korisnik nije vlasnik ili admin.
-- 3. Zadrži eksplicitni REVOKE za pisanje (INSERT/UPDATE/DELETE/TRUNCATE).
-- 4. Osiguraj GRANT SELECT za anon i authenticated.
-- ============================================================================

ALTER VIEW public.public_profiles SET (security_invoker = false);
ALTER VIEW public.public_classified_ads SET (security_invoker = false);

REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.public_profiles FROM PUBLIC, anon, authenticated;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.public_classified_ads FROM PUBLIC, anon, authenticated;

GRANT SELECT ON public.public_profiles TO anon, authenticated;
GRANT SELECT ON public.public_classified_ads TO anon, authenticated;
