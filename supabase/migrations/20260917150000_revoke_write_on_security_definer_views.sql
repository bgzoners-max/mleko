-- ============================================================================
-- Sigurnost: Zabrana operacija pisanja nad SECURITY DEFINER view-ovima
-- Datum: 2026-09-17
--
-- PROBLEM:
-- View-ovi public.public_profiles i public.public_classified_ads se izvršavaju
-- kao vlasnik (postgres / definer) radi bezbednog maskiranja osetljivih podataka
-- (email, phone). Ukoliko na njima postoji default write grant, INSERT/UPDATE/DELETE
-- bi se izvršavao sa pravima vlasnika i mogao bi zaobići RLS osnovnih tabela.
--
-- REŠENJE:
-- Eksplicitno oduzmi INSERT, UPDATE, DELETE, TRUNCATE nad ovim view-ovima
-- za uloge PUBLIC, anon i authenticated. View-ovi služe isključivo za čitanje.
-- ============================================================================

REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.public_profiles FROM PUBLIC, anon, authenticated;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.public_classified_ads FROM PUBLIC, anon, authenticated;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.products_with_ratings FROM PUBLIC, anon, authenticated;
