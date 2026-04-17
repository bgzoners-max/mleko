-- Popravljanje kategorija proizvoda koji ne odgovaraju nijednoj kategoriji u tabeli categories
-- Mapiranje:
--   "Mleko"        → "Sveže mleko"      (potkategorija Mlečni proizvodi)
--   "Sir"          → "Sir i kačkavalj"  (potkategorija Mlečni proizvodi)
--   "Svježe meso"  → "Sveže meso"       (potkategorija Meso, ijekavski → ekavski)
--   "Poklon setovi"→ "Korpe za slavu"   (potkategorija Poklon paketi, primer oglasa)

UPDATE public.products SET category = 'Sveže mleko'    WHERE category = 'Mleko';
UPDATE public.products SET category = 'Sir i kačkavalj' WHERE category = 'Sir';
UPDATE public.products SET category = 'Sveže meso'     WHERE category = 'Svježe meso';
UPDATE public.products SET category = 'Korpe za slavu' WHERE category = 'Poklon setovi';
