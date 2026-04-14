-- Add "Ostalo" subcategory to "Prirodna kozmetika"

INSERT INTO public.categories (id, name, slug, icon, "order", parent_id)
SELECT
  gen_random_uuid(),
  'Ostalo',
  'prirodna-kozmetika-ostalo',
  '🧴',
  40,
  id
FROM public.categories
WHERE slug = 'prirodna-kozmetika' AND parent_id IS NULL;
