-- Osvežavanje podkategorija za "Mlečni proizvodi" prema novoj strukturi

-- Pronađi ID roditeljske kategorije "Mlečni proizvodi"
WITH mlecni_parent AS (
  SELECT id FROM public.categories
  WHERE slug = 'mlecni-proizvodi' AND parent_id IS NULL
  LIMIT 1
)

-- Obriši stare podkategorije
DELETE FROM public.categories
WHERE parent_id = (
  SELECT id FROM public.categories
  WHERE slug = 'mlecni-proizvodi' AND parent_id IS NULL
  LIMIT 1
);

-- Dodaj nove podkategorije
INSERT INTO public.categories (id, name, slug, icon, "order", parent_id, section)
SELECT
  gen_random_uuid(),
  name,
  slug,
  icon,
  "order",
  (SELECT id FROM public.categories WHERE slug = 'mlecni-proizvodi' AND parent_id IS NULL LIMIT 1),
  'hrana'
FROM (VALUES
  ('Sveže mleko', 'sveze-mleko', '🥛', 10),
  ('Jogurt i kiselo mleko', 'kiselo-mleko-jogurt-kefir', '🥣', 20),
  ('Sir i kačkavalj', 'sir', '🧀', 30),
  ('Kajmak', 'kajmak', '🧈', 40),
  ('Pavlaka i maslac', 'pavlaka-maslac-kisela-pavlaka', '🥄', 50),
  ('Ostali mlečni proizvodi', 'ostali-mlecni-proizvodi', '🍶', 60)
) AS t(name, slug, icon, "order")
ON CONFLICT DO NOTHING;
