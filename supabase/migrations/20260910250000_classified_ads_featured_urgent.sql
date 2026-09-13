-- ============================================================================
-- Migracija za Istaknute i Promovisane oglase (Featured & Urgent Listings)
-- ============================================================================

-- 1. Dodavanje kolona za isticanje i hitnost u tabelu classified_ads
ALTER TABLE public.classified_ads
    ADD COLUMN IF NOT EXISTS is_featured BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS featured_until TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS is_urgent BOOLEAN NOT NULL DEFAULT false;

-- 2. Parcijalni indeksi za maksimalne performanse sortiranja i filtriranja aktivnih oglasa
-- Brza pretraga i rangiranje istaknutih oglasa
CREATE INDEX IF NOT EXISTS idx_classified_ads_featured
    ON public.classified_ads (is_featured DESC, created_at DESC)
    WHERE status = 'active';

-- Brza pretraga hitnih oglasa
CREATE INDEX IF NOT EXISTS idx_classified_ads_urgent
    ON public.classified_ads (is_urgent, created_at DESC)
    WHERE status = 'active';

-- Optimizovano rangiranje istaknutih oglasa unutar određene kategorije
CREATE INDEX IF NOT EXISTS idx_classified_ads_cat_featured
    ON public.classified_ads (category_id, is_featured DESC, created_at DESC)
    WHERE status = 'active';
