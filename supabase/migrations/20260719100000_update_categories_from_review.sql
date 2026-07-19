-- 1. Rename existing categories
UPDATE public.categories SET name = 'Slana zimnica', slug = 'slana-zimnica' WHERE slug = 'zimnica-i-namazi' AND parent_id IS NULL;
UPDATE public.categories SET name = 'Slatka zimnica i džemovi', slug = 'slatka-zimnica-i-dzemovi' WHERE slug = 'slatko-i-dzemovi' AND parent_id IS NULL;
UPDATE public.categories SET name = 'Med i pčelinji proizvodi', slug = 'med-i-pcelinji-proizvodi' WHERE slug = 'med-i-pcelarski' AND parent_id IS NULL;
UPDATE public.categories SET name = 'Sokovi i domaći sirupi', slug = 'sokovi-i-domaci-sirupi' WHERE slug = 'sokovi-i-pica' AND parent_id IS NULL;
UPDATE public.categories SET name = 'Brašno, testenine i žitarice', slug = 'brasno-testenine-i-zitarice' WHERE slug = 'pekara-i-zitarice' AND parent_id IS NULL;
UPDATE public.categories SET name = 'Čajevi, začini i lekovito bilje', slug = 'cajevi-zacini-i-lekovito-bilje' WHERE slug = 'zacini-i-bilje' AND parent_id IS NULL;
UPDATE public.categories SET name = 'Suvomesnati proizvodi i delikates', slug = 'suvomesnati-proizvodi-i-delikates' WHERE slug IN ('meso', 'meso-i-mesne-preradjevine', 'meso-i-preradjevine') AND parent_id IS NULL;

-- 2. Insert new categories
WITH new_parents AS (
  INSERT INTO public.categories (id, name, slug, icon, "order", parent_id)
  VALUES
    (gen_random_uuid(), 'Vina i domaće rakije',            'vina-i-domace-rakije',            '🍷', 60, NULL),
    (gen_random_uuid(), 'Hladno ceđena ulja i sirćeta',      'hladno-cedjena-ulja-i-sirceta',      '🫒', 115, NULL),
    (gen_random_uuid(), 'Orašasti plodovi, semenke i suvo voće', 'orasasti-plodovi-semenke-i-suvo-voce', '🥜', 125, NULL),
    (gen_random_uuid(), 'Gljive i tartufi',                'gljive-i-tartufi',                '🍄', 127, NULL),
    (gen_random_uuid(), 'Posno, vegansko i bez glutena',   'posno-vegansko-i-bez-glutena',   '🌱', 140, NULL),
    (gen_random_uuid(), 'Zanatski proizvodi i rukotvorine', 'zanatski-proizvodi-i-rukotvorine', '🧵', 150, NULL)
  RETURNING id, slug
)
INSERT INTO public.categories (id, name, slug, icon, "order", parent_id)
SELECT gen_random_uuid(), c.name, c.slug, c.icon, c.ord, p.id
FROM new_parents p
JOIN (VALUES
  ('vina-i-domace-rakije', 'Vina', 'vina', '🍷', 10),
  ('vina-i-domace-rakije', 'Domaće rakije', 'domace-rakije', '🥃', 20),
  ('vina-i-domace-rakije', 'Piva i likeri', 'piva-i-likeri', '🍺', 30),
  
  ('hladno-cedjena-ulja-i-sirceta', 'Hladno ceđena ulja', 'hladno-cedjena-ulja', '🫒', 10),
  ('hladno-cedjena-ulja-i-sirceta', 'Domaće sirće', 'domace-sirce', '🍶', 20),

  ('orasasti-plodovi-semenke-i-suvo-voce', 'Orašasti plodovi', 'orasasti-plodovi', '🌰', 10),
  ('orasasti-plodovi-semenke-i-suvo-voce', 'Semenke', 'semenke', '🌻', 20),
  ('orasasti-plodovi-semenke-i-suvo-voce', 'Suvo voće', 'suvo-voce-kategorija', '🍇', 30),

  ('gljive-i-tartufi', 'Sveže i sušene gljive', 'sveze-i-susene-gljive', '🍄', 10),
  ('gljive-i-tartufi', 'Tartufi i proizvodi', 'tartufi-i-proizvosdi', '🧆', 20),

  ('posno-vegansko-i-bez-glutena', 'Posno', 'posno', '🥗', 10),
  ('posno-vegansko-i-bez-glutena', 'Vegansko', 'vegansko', '🥑', 20),
  ('posno-vegansko-i-bez-glutena', 'Bez glutena', 'bez-glutena', '🍞', 30),

  ('zanatski-proizvodi-i-rukotvorine', 'Drvenarija i daske', 'drvenarija-i-daske', '🪵', 10),
  ('zanatski-proizvodi-i-rukotvorine', 'Pleteno i tekstil', 'pleteno-i-tekstil', '🧶', 20),
  ('zanatski-proizvodi-i-rukotvorine', 'Ostale rukotvorine', 'ostale-rukotvorine', '🏺', 30)
) AS c(parent_slug, name, slug, icon, ord)
ON p.slug = c.parent_slug;

-- Update product categories safely
UPDATE public.products SET category = 'Slana zimnica' WHERE category = 'Zimnica i namazi';
UPDATE public.products SET category = 'Slatka zimnica i džemovi' WHERE category = 'Slatko i džemovi';
UPDATE public.products SET category = 'Med i pčelinji proizvodi' WHERE category = 'Med i pčelarski';
UPDATE public.products SET category = 'Sokovi i domaći sirupi' WHERE category = 'Sokovi i pića';
UPDATE public.products SET category = 'Brašno, testenine i žitarice' WHERE category = 'Pekara i žitarice';
UPDATE public.products SET category = 'Čajevi, začini i lekovito bilje' WHERE category = 'Začini i bilje';
UPDATE public.products SET category = 'Suvomesnati proizvodi i delikates' WHERE category IN ('Meso', 'Meso i mesne prerađevine', 'Meso i prerađevine');

-- 3. Update orders to put most popular first
UPDATE public.categories SET "order" = 10 WHERE slug = 'mlecni-proizvodi' AND parent_id IS NULL;
UPDATE public.categories SET "order" = 20 WHERE slug IN ('suvomesnato-i-delikates', 'suvomesnati-proizvodi-i-delikates', 'meso') AND parent_id IS NULL;
UPDATE public.categories SET "order" = 30 WHERE slug = 'voce-i-povrce' AND parent_id IS NULL;
UPDATE public.categories SET "order" = 40 WHERE slug = 'slana-zimnica' AND parent_id IS NULL;
UPDATE public.categories SET "order" = 50 WHERE slug = 'slatka-zimnica-i-dzemovi' AND parent_id IS NULL;
-- Vina = 60
-- Sokovi = 70
UPDATE public.categories SET "order" = 70 WHERE slug = 'sokovi-i-domaci-sirupi' AND parent_id IS NULL;
UPDATE public.categories SET "order" = 80 WHERE slug = 'brasno-testenine-i-zitarice' AND parent_id IS NULL;
UPDATE public.categories SET "order" = 90 WHERE slug = 'jaja' AND parent_id IS NULL;
UPDATE public.categories SET "order" = 100 WHERE slug = 'med-i-pcelinji-proizvodi' AND parent_id IS NULL;
UPDATE public.categories SET "order" = 110 WHERE slug = 'cajevi-zacini-i-lekovito-bilje' AND parent_id IS NULL;
-- Ulja = 115
UPDATE public.categories SET "order" = 120 WHERE slug = 'prirodna-kozmetika' AND parent_id IS NULL;
-- Orasasti = 125
-- Gljive = 127
UPDATE public.categories SET "order" = 130 WHERE slug = 'gotova-jela-i-delikates' AND parent_id IS NULL;
-- Posno = 140
-- Zanatski = 150
UPDATE public.categories SET "order" = 160 WHERE slug = 'poklon-paketi' AND parent_id IS NULL;
