-- ============================================================================
-- Migracija: Prioritetni redosled država za automobile prema skici
-- 1. Nemačka, 2. Italija, 3. Francuska, 4. Japan, 5. SAD, itd.
-- ============================================================================

UPDATE public.classified_categories SET sort_order = 10 WHERE id = 'auto_nemacka';
UPDATE public.classified_categories SET sort_order = 20 WHERE id = 'auto_italija';
UPDATE public.classified_categories SET sort_order = 30 WHERE id = 'auto_francuska';
UPDATE public.classified_categories SET sort_order = 40 WHERE id = 'auto_japan';
UPDATE public.classified_categories SET sort_order = 50 WHERE id = 'auto_sad';
UPDATE public.classified_categories SET sort_order = 60 WHERE id = 'auto_juzna_koreja';
UPDATE public.classified_categories SET sort_order = 70 WHERE id = 'auto_ceska';
UPDATE public.classified_categories SET sort_order = 80 WHERE id = 'auto_velika_britanija';
UPDATE public.classified_categories SET sort_order = 90 WHERE id = 'auto_svedska';
UPDATE public.classified_categories SET sort_order = 100 WHERE id = 'auto_spanija';
UPDATE public.classified_categories SET sort_order = 110 WHERE id = 'auto_rumunija';
UPDATE public.classified_categories SET sort_order = 120 WHERE id = 'auto_rusija';
UPDATE public.classified_categories SET sort_order = 130 WHERE id = 'auto_kina';
UPDATE public.classified_categories SET sort_order = 200 WHERE id = 'dzipovi_suv';
UPDATE public.classified_categories SET sort_order = 210 WHERE id = 'oldtajmeri_havarisani';
UPDATE public.classified_categories SET sort_order = 220 WHERE id = 'auto_ostalo';
