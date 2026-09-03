-- ============================================================================
-- GIN trigram indeksi za full-text pretragu klasifikovanih oglasa
-- Migracija: 20260903130000_classified_ads_search_index.sql
-- ============================================================================

-- Omoguci pg_trgm ekstenziju (neophodna za GIN trigram indekse)
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- GIN indeks na naslovu oglasa (za ILIKE '%tekst%' pretrage)
CREATE INDEX IF NOT EXISTS idx_classified_ads_title_trgm
    ON public.classified_ads USING GIN (title gin_trgm_ops);

-- GIN indeks na opisu oglasa (pretrage pokrivaju i opis)
CREATE INDEX IF NOT EXISTS idx_classified_ads_description_trgm
    ON public.classified_ads USING GIN (description gin_trgm_ops);

-- Kompozitni full-text search indeks (tsvector za naprednu pretragu)
CREATE INDEX IF NOT EXISTS idx_classified_ads_fts
    ON public.classified_ads USING GIN (
        to_tsvector('simple', title || ' ' || description)
    );
