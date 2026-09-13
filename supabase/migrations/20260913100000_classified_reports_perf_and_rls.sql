-- Migracija za performanse i optimizaciju RLS politika nad classified_ad_reports
-- Datum: 2026-09-13
-- Referenca: Supabase Postgres Best Practices (security-rls-performance & schema-foreign-key-indexes)

-- 1. Dodavanje indeksa na spoljni ključ resolved_by
CREATE INDEX IF NOT EXISTS idx_classified_ad_reports_resolved_by
ON public.classified_ad_reports(resolved_by);

-- 2. Optimizacija RLS politika na classified_ad_reports (keširanje (SELECT auth.uid()))
DROP POLICY IF EXISTS "classified_ad_reports_insert_own" ON public.classified_ad_reports;
CREATE POLICY "classified_ad_reports_insert_own"
ON public.classified_ad_reports
FOR INSERT
TO authenticated
WITH CHECK ((SELECT auth.uid()) = reporter_id);

DROP POLICY IF EXISTS "classified_ad_reports_select_own" ON public.classified_ad_reports;
CREATE POLICY "classified_ad_reports_select_own"
ON public.classified_ad_reports
FOR SELECT
TO authenticated
USING ((SELECT auth.uid()) = reporter_id);
