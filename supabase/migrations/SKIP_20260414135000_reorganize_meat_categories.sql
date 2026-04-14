-- Reorganizacija kategorija Meso i mesne prerađevine

-- 1. Preimenovaj "Meso" -> "Meso i mesne prerađevine"
UPDATE public.categories
SET name = 'Meso i mesne prerađevine', slug = 'meso-i-mesne-preradjevine'
WHERE slug = 'meso' AND parent_id IS NULL;

-- 2. Obriši sve stare podkategorije od "Meso"
DELETE FROM public.categories
WHERE parent_id = (SELECT id FROM public.categories WHERE slug = 'meso-i-mesne-preradjevine' AND parent_id IS NULL LIMIT 1);

-- 3. Dodaj nove podkategorije
INSERT INTO public.categories (id, name, slug, icon, "order", parent_id, section)
SELECT
  gen_random_uuid(),
  name,
  slug,
  icon,
  "order",
  (SELECT id FROM public.categories WHERE slug = 'meso-i-mesne-preradjevine' AND parent_id IS NULL LIMIT 1),
  'hrana'
FROM (VALUES
  ('Sveže meso', 'sveze-meso', '🥩', 10),
  ('Perad', 'perad', '🍗', 20),
  ('Suhomesnato', 'suhomesnato', '🍖', 30),
  ('Kobasice i čvarci', 'kobasice-i-cvarci', '🌭', 40),
  ('Ostalo', 'ostalo-meso', '🍲', 50)
) AS t(name, slug, icon, "order")
ON CONFLICT DO NOTHING;

-- 4. Prebaciš proizvode iz "Domaći specijaliteti" na nove podkategorije
-- Prvo pronađi sve proizvode koji su bili pod "Domaći specijaliteti"
-- i prebaci ih na odgovarajuće nove kategorije

-- Šunke i pršute -> Suhomesnato
UPDATE public.products
SET category = 'Suhomesnato'
WHERE category IN ('Šunke i pršute', 'sunke-i-prsute');

-- Kobasice -> Kobasice i čvarci
UPDATE public.products
SET category = 'Kobasice i čvarci'
WHERE category IN ('Kobasice', 'kobasice');

-- Slanina i pančeta -> Suhomesnato
UPDATE public.products
SET category = 'Suhomesnato'
WHERE category IN ('Slanina i pančeta', 'slanina-i-panceta');

-- Čvarci -> Kobasice i čvarci
UPDATE public.products
SET category = 'Kobasice i čvarci'
WHERE category IN ('Cvarci', 'cvarci');

-- Pečenice i vrat -> Suhomesnato
UPDATE public.products
SET category = 'Suhomesnato'
WHERE category IN ('Pečenice i vrat', 'pecenice-i-vrat');

-- 5. Obriši "Domaći specijaliteti" jer je sve sada pod "Meso i mesne prerađevine"
DELETE FROM public.categories
WHERE slug = 'domaci-specijaliteti' AND parent_id IS NULL;
