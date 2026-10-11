-- =============================================================================
-- Purge legacy seed test users and dummy data from previous migrations (@test.rs)
--
-- Background:
-- Early development migrations (e.g. 20260227120000_seed_test_users.sql) previously
-- seeded test accounts (@test.rs). While those migrations were later neutered to
-- SELECT 1;, any staging/production environment where they ran may still contain
-- residual test data.
--
-- Test data belongs exclusively in `supabase/seed.sql` (local dev) or staging seed scripts.
-- This migration safely removes residual test data by email pattern.
-- =============================================================================

DO $$
BEGIN
  -- 1. Ukloni eventualne test proizvode vezane za @test.rs naloge
  DELETE FROM public.products
  WHERE seller_id IN (
    SELECT id FROM auth.users WHERE email LIKE '%@test.rs'
  );

  -- 2. Ukloni profile test naloga
  DELETE FROM public.profiles
  WHERE email LIKE '%@test.rs';

  -- 3. Ukloni identitete test naloga
  DELETE FROM auth.identities
  WHERE user_id IN (
    SELECT id FROM auth.users WHERE email LIKE '%@test.rs'
  );

  -- 4. Ukloni same auth korisnike (kaskadno čisti sve preostale reference)
  DELETE FROM auth.users
  WHERE email LIKE '%@test.rs';
END $$;
