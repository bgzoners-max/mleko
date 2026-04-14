-- Replace subcategories of "Poklon paketi" with new gift basket types

-- 1. Delete old subcategories
DELETE FROM public.categories
WHERE parent_id = (SELECT id FROM public.categories WHERE slug = 'poklon-paketi' AND parent_id IS NULL);

-- 2. Insert new subcategories
INSERT INTO public.categories (id, name, slug, icon, "order", parent_id)
SELECT
  gen_random_uuid(),
  c.name,
  c.slug,
  c.icon,
  c.ord,
  p.id
FROM (SELECT id FROM public.categories WHERE slug = 'poklon-paketi' AND parent_id IS NULL) p
CROSS JOIN (VALUES
  ('Korpe za rođendan',             'korpe-za-rodjendan',    '🎂', 10),
  ('Korpe za slavu',                'korpe-za-slavu',        '🕯️', 20),
  ('Korpe za Novu godinu / praznike','korpe-za-novu-godinu', '🎄', 30),
  ('Romantične korpe',              'romanticne-korpe',      '❤️', 40),
  ('Korpe za decu',                 'korpe-za-decu',         '🧸', 50)
) AS c(name, slug, icon, ord);
