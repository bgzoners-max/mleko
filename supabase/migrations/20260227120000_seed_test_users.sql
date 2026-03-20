-- =============================================================================
-- Legacy migration (version kept for history).
-- Test korisnici i proizvodi više NE primenjuju se ovde — `supabase db push` ne
-- sme da kreira @test.rs naloge na produkcijskoj bazi.
-- Lokalno: `supabase db reset` učitava supabase/seed.sql posle migracija.
-- =============================================================================
SELECT 1;
