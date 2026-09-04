-- ============================================================================
-- Migracija 20260904140000: Uklanjanje duplikata podkategorija oglasnika
--
-- Početna migracija (20260903120000) ubacila je podkategorije:
--   traktori, prikljucci, elektro_alati, motocikli
-- Nova migracija (20260904100000/110000) dodaje smislenije ID-jeve:
--   traktori_kombajni, prikljucne_masine, elektro_aku_alati, motocikli_atv
--
-- Ova migracija prebacuje postojeće oglase na nove kategorije i briše stare
-- duplikate da se ne pojavljuju isti nazivi dva puta u UI.
-- ============================================================================

-- Prebaci oglase sa starih na nove kategorije
UPDATE public.classified_ads
SET category_id = 'traktori_kombajni'
WHERE category_id = 'traktori';

UPDATE public.classified_ads
SET category_id = 'prikljucne_masine'
WHERE category_id = 'prikljucci';

UPDATE public.classified_ads
SET category_id = 'elektro_aku_alati'
WHERE category_id = 'elektro_alati';

UPDATE public.classified_ads
SET category_id = 'motocikli_atv'
WHERE category_id = 'motocikli';

-- Obriši stare (sada neupotrebljene) duplikate
DELETE FROM public.classified_categories
WHERE id IN ('traktori', 'prikljucci', 'elektro_alati', 'motocikli');