-- Dodaj section kolonu za UI grupisanje kategorija
ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS section TEXT;

-- Dodaj nove top-level kategorije
INSERT INTO public.categories (id, name, slug, icon, "order", parent_id, section)
VALUES
  (gen_random_uuid(), 'Meso i prerađevine', 'meso-i-preradjevine', '🥩', 15, NULL, 'hrana'),
  (gen_random_uuid(), 'Smrznuti proizvodi',  'smrznuti-proizvodi',  '❄️', 135, NULL, 'specijaliteti')
ON CONFLICT DO NOTHING;

-- Dodaj podkategorije za Meso i prerađevine
WITH meso AS (SELECT id FROM public.categories WHERE slug = 'meso-i-preradjevine' LIMIT 1)
INSERT INTO public.categories (id, name, slug, icon, "order", parent_id)
SELECT gen_random_uuid(), c.name, c.slug, c.icon, c.ord, meso.id
FROM meso, (VALUES
  ('Sveže meso',        'sveze-meso',         '🥩', 10),
  ('Perad',             'perad',              '🍗', 20),
  ('Jagnjetina i teletina', 'jagnjetina-teletina', '🐑', 30)
) AS c(name, slug, icon, ord)
ON CONFLICT DO NOTHING;

-- Dodaj podkategorije za Smrznuti proizvodi
WITH smrz AS (SELECT id FROM public.categories WHERE slug = 'smrznuti-proizvodi' LIMIT 1)
INSERT INTO public.categories (id, name, slug, icon, "order", parent_id)
SELECT gen_random_uuid(), c.name, c.slug, c.icon, c.ord, smrz.id
FROM smrz, (VALUES
  ('Smrznuto voće',    'smrznuto-voce',    '🍓', 10),
  ('Smrznuto povrće',  'smrznuto-povrce',  '🥦', 20),
  ('Smrznuta jela',    'smrznuta-jela',    '🍲', 30)
) AS c(name, slug, icon, ord)
ON CONFLICT DO NOTHING;

-- Ažuriraj order za top-level kategorije (TOP 8 su: order 10-80)
-- Redoslijed za home screen take(8):
-- 10: Mlečni, 15: Meso, 20: Suhomesnato, 30: Zimnica, 40: Med, 50: Voće, 60: Sokovi, 70: Jaja
-- Ostalo: 80+
UPDATE public.categories SET "order" = 10  WHERE slug = 'mlecni-proizvodi'       AND parent_id IS NULL;
UPDATE public.categories SET "order" = 15  WHERE slug = 'meso-i-preradjevine'    AND parent_id IS NULL;
UPDATE public.categories SET "order" = 20  WHERE slug = 'suhomesnato'            AND parent_id IS NULL;
UPDATE public.categories SET "order" = 30  WHERE slug = 'zimnica-i-namazi'       AND parent_id IS NULL;
UPDATE public.categories SET "order" = 40  WHERE slug = 'med-i-pcelarski'        AND parent_id IS NULL;
UPDATE public.categories SET "order" = 50  WHERE slug = 'voce-i-povrce'          AND parent_id IS NULL;
UPDATE public.categories SET "order" = 60  WHERE slug = 'sokovi-i-pica'          AND parent_id IS NULL;
UPDATE public.categories SET "order" = 70  WHERE slug = 'jaja'                   AND parent_id IS NULL;
UPDATE public.categories SET "order" = 80  WHERE slug = 'slatko-i-dzemovi'       AND parent_id IS NULL;
UPDATE public.categories SET "order" = 90  WHERE slug = 'zacini-i-bilje'         AND parent_id IS NULL;
UPDATE public.categories SET "order" = 100 WHERE slug = 'pekarsko-i-testa'       AND parent_id IS NULL;
UPDATE public.categories SET "order" = 110 WHERE slug = 'brasno-i-zitarice'      AND parent_id IS NULL;
UPDATE public.categories SET "order" = 120 WHERE slug = 'prirodna-kozmetika'     AND parent_id IS NULL;
UPDATE public.categories SET "order" = 130 WHERE slug = 'gotova-jela-i-delikates' AND parent_id IS NULL;
UPDATE public.categories SET "order" = 135 WHERE slug = 'smrznuti-proizvodi'     AND parent_id IS NULL;
UPDATE public.categories SET "order" = 140 WHERE slug = 'poklon-paketi'          AND parent_id IS NULL;

-- Postavi section za sve top-level kategorije
UPDATE public.categories SET section = 'hrana'       WHERE slug IN ('mlecni-proizvodi','meso-i-preradjevine','suhomesnato','jaja') AND parent_id IS NULL;
UPDATE public.categories SET section = 'osnove'      WHERE slug IN ('brasno-i-zitarice','pekarsko-i-testa','zacini-i-bilje') AND parent_id IS NULL;
UPDATE public.categories SET section = 'domace'      WHERE slug IN ('zimnica-i-namazi','slatko-i-dzemovi','med-i-pcelarski') AND parent_id IS NULL;
UPDATE public.categories SET section = 'sveze'       WHERE slug IN ('voce-i-povrce') AND parent_id IS NULL;
UPDATE public.categories SET section = 'pica'        WHERE slug IN ('sokovi-i-pica') AND parent_id IS NULL;
UPDATE public.categories SET section = 'specijaliteti' WHERE slug IN ('gotova-jela-i-delikates','smrznuti-proizvodi') AND parent_id IS NULL;
UPDATE public.categories SET section = 'ostalo'      WHERE slug IN ('prirodna-kozmetika','poklon-paketi') AND parent_id IS NULL;
