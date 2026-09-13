-- Migracija za prijavljivanje oglasa i moderaciju (Classified Ad Reports)
-- Datum: 2026-09-10

-- 1. Dodavanje brojača prijava u classified_ads tabelu
ALTER TABLE public.classified_ads
ADD COLUMN IF NOT EXISTS reports_count INT NOT NULL DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_classified_ads_reports_count
ON public.classified_ads(reports_count)
WHERE reports_count > 0;

-- 2. Tabela prijava za oglase
CREATE TABLE IF NOT EXISTS public.classified_ad_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ad_id UUID NOT NULL REFERENCES public.classified_ads(id) ON DELETE CASCADE,
  reporter_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reason TEXT NOT NULL CHECK (reason IN (
    'fraud_scam',
    'spam_duplicate',
    'inappropriate',
    'wrong_category',
    'sold_unavailable',
    'other'
  )),
  details TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
    'pending',
    'reviewed',
    'dismissed',
    'ad_removed'
  )),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  resolved_at TIMESTAMPTZ,
  resolved_by UUID REFERENCES auth.users(id),
  CONSTRAINT uq_classified_ad_reporter UNIQUE (ad_id, reporter_id)
);

-- Indeksi za brzo pretraživanje prijava
CREATE INDEX IF NOT EXISTS idx_classified_ad_reports_ad_id
ON public.classified_ad_reports(ad_id);

CREATE INDEX IF NOT EXISTS idx_classified_ad_reports_reporter_id
ON public.classified_ad_reports(reporter_id);

CREATE INDEX IF NOT EXISTS idx_classified_ad_reports_status
ON public.classified_ad_reports(status);

-- 3. Automatski triger za uvećanje reports_count na oglasu
CREATE OR REPLACE FUNCTION public.increment_classified_ad_reports_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.classified_ads
  SET reports_count = reports_count + 1
  WHERE id = NEW.ad_id;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_increment_classified_ad_reports_count ON public.classified_ad_reports;
CREATE TRIGGER trg_increment_classified_ad_reports_count
AFTER INSERT ON public.classified_ad_reports
FOR EACH ROW
EXECUTE FUNCTION public.increment_classified_ad_reports_count();

-- 4. RLS sigurnosne politike
ALTER TABLE public.classified_ad_reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "classified_ad_reports_insert_own" ON public.classified_ad_reports;
CREATE POLICY "classified_ad_reports_insert_own"
ON public.classified_ad_reports
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = reporter_id);

DROP POLICY IF EXISTS "classified_ad_reports_select_own" ON public.classified_ad_reports;
CREATE POLICY "classified_ad_reports_select_own"
ON public.classified_ad_reports
FOR SELECT
TO authenticated
USING (auth.uid() = reporter_id);
