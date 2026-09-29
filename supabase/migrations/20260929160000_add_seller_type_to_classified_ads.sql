-- ============================================================================
-- Migracija 20260929160000: Dodavanje seller_type u classified_ads
--
-- Zakonska usklađenost (Zakon o zaštiti potrošača / e-trgovini):
-- Oglašivač mora definisati status prodavca:
--   'individual' => Fizičko lice
--   'business'   => Pravno lice / Trgovac
-- ============================================================================

ALTER TABLE public.classified_ads
  ADD COLUMN IF NOT EXISTS seller_type text NOT NULL DEFAULT 'individual';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'classified_ads_seller_type_check'
  ) THEN
    ALTER TABLE public.classified_ads
      ADD CONSTRAINT classified_ads_seller_type_check
      CHECK (seller_type IN ('individual', 'business'));
  END IF;
END $$;

-- Dozvoli čitanje kolone seller_type za anon i authenticated
GRANT SELECT (seller_type) ON public.classified_ads TO anon, authenticated;
