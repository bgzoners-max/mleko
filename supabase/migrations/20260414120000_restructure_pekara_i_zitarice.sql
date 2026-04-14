-- Merge "Pekarsko i testa" + "Brašno i žitarice" into single "Pekara i žitarice"
-- New subcategories: Hleb i peciva, Testa i testenine, Brašna, Žitarice i pahuljice, Ostalo

-- 1. Rename the existing "Pekarsko i testa" parent to "Pekara i žitarice"
UPDATE public.categories
SET name = 'Pekara i žitarice',
    slug = 'pekara-i-zitarice'
WHERE slug = 'pekarsko-i-testa'
  AND parent_id IS NULL;

-- 2. Delete old subcategories of the renamed parent
DELETE FROM public.categories
WHERE parent_id = (SELECT id FROM public.categories WHERE slug = 'pekara-i-zitarice' AND parent_id IS NULL)
;

-- 3. Delete old "Brašno i žitarice" subcategories then the parent itself
DELETE FROM public.categories
WHERE parent_id = (SELECT id FROM public.categories WHERE slug = 'brasno-i-zitarice' AND parent_id IS NULL)
;
DELETE FROM public.categories
WHERE slug = 'brasno-i-zitarice'
  AND parent_id IS NULL;

-- 4. Insert new subcategories under "Pekara i žitarice"
INSERT INTO public.categories (id, name, slug, icon, "order", parent_id)
SELECT
  gen_random_uuid(),
  c.name,
  c.slug,
  c.icon,
  c.ord,
  p.id
FROM (SELECT id FROM public.categories WHERE slug = 'pekara-i-zitarice' AND parent_id IS NULL) p
CROSS JOIN (VALUES
  ('Hleb i peciva',        'hleb-i-peciva',        '🥖', 10),
  ('Testa i testenine',    'testa-i-testenine',     '🍝', 20),
  ('Brašna',               'brasna',                '🌾', 30),
  ('Žitarice i pahuljice', 'zitarice-i-pahuljice',  '🥣', 40),
  ('Ostalo',               'pekara-ostalo',         '🍞', 50)
) AS c(name, slug, icon, ord);

-- 5. Migrate products.category from old subcategory names to new ones (best-effort)
UPDATE public.products SET category = 'Hleb i peciva'        WHERE lower(trim(category)) IN ('hleb i pečiva', 'hleb i peciva');
UPDATE public.products SET category = 'Testa i testenine'    WHERE lower(trim(category)) IN ('pite i gibanice', 'kolači domaći', 'kolaci domaci', 'testenina domaća', 'testenina domaca');
UPDATE public.products SET category = 'Brašna'               WHERE lower(trim(category)) IN ('brašno', 'brasno');
UPDATE public.products SET category = 'Žitarice i pahuljice' WHERE lower(trim(category)) IN ('žitarice', 'zitarice', 'mleveno i pahuljice', 'seme i orašasti', 'seme i orasasti');
