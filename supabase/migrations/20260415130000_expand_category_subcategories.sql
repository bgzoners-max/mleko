-- Proširivanje podkategorija
-- Problem 5: "Gotova jela i delikatesi" ima samo 2 podkategorije – dodati granularnost
-- Problem 6: "Poklon paketi" nema generičku podkategoriju za sve što nije vezano za konkretan praznik

-- ─── Problem 5: Proširiti Gotova jela i delikatesi ───────────────────────────
-- Postojeće: Gotova jela (10), Delikatesi (20) – ostaju, samo im prilagodimo order
-- Novo: Supe i čorbe (15), Posna jela (25), Domaći specijaliteti (30)

UPDATE public.categories SET "order" = 10 WHERE slug = 'gotova-jela'
  AND parent_id = (SELECT id FROM public.categories WHERE slug = 'gotova-jela-i-delikates' AND parent_id IS NULL LIMIT 1);

UPDATE public.categories SET "order" = 40 WHERE slug = 'delikates'
  AND parent_id = (SELECT id FROM public.categories WHERE slug = 'gotova-jela-i-delikates' AND parent_id IS NULL LIMIT 1);

INSERT INTO public.categories (id, name, slug, icon, "order", parent_id, section)
SELECT
  gen_random_uuid(),
  c.name,
  c.slug,
  c.icon,
  c.ord,
  (SELECT id FROM public.categories WHERE slug = 'gotova-jela-i-delikates' AND parent_id IS NULL LIMIT 1),
  'specijaliteti'
FROM (VALUES
  ('Supe i čorbe',        'supe-i-corbe',        '🍜', 15),
  ('Posna jela',          'posna-jela',           '🥗', 25),
  ('Domaći specijaliteti','domaci-specijaliteti', '🍽️', 35)
) AS c(name, slug, icon, ord)
ON CONFLICT DO NOTHING;


-- ─── Problem 6: Generička podkategorija za Poklon paketi ─────────────────────
-- Postojeće: Korpe za rođendan (10), Korpe za slavu (20), Korpe za Novu godinu (30),
--            Romantične korpe (40), Korpe za decu (50)
-- Novo: Prigodne korpe (60) – za sve ostale prilike

INSERT INTO public.categories (id, name, slug, icon, "order", parent_id)
SELECT
  gen_random_uuid(),
  'Prigodne korpe',
  'prigodne-korpe',
  '🧺',
  60,
  (SELECT id FROM public.categories WHERE slug = 'poklon-paketi' AND parent_id IS NULL LIMIT 1)
ON CONFLICT DO NOTHING;
