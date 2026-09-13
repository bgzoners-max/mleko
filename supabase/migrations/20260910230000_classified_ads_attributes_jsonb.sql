-- ============================================================================
-- Migracija: Dodavanje JSONB kolone `attributes` i GIN indeksa na `classified_ads`
-- Omogućava fleksibilno čuvanje specifikacija po kategorijama
-- (npr. kilometraža, godište, gorivo, kvadratura, radni sati, memorija itd.)
-- ============================================================================

-- 1. Dodavanje JSONB kolone attributes ako ne postoji
ALTER TABLE public.classified_ads
ADD COLUMN IF NOT EXISTS attributes JSONB NOT NULL DEFAULT '{}'::jsonb;

-- 2. GIN indeks za munjevite upite i filtriranje po JSONB poljima
CREATE INDEX IF NOT EXISTS idx_classified_ads_attributes
ON public.classified_ads USING gin (attributes);
