-- Podijeli "Jogurt i kiselo mleko" na dvije posebne podkategorije
-- i preimenuj "Pavlaka i namazi" u "Namazi"

-- 1. Preimenuj "Jogurt i kiselo mleko" -> "Jogurt"
UPDATE public.categories
SET name = 'Jogurt', slug = 'jogurt'
WHERE slug = 'jogurt-i-kiselo-mleko'
  AND parent_id = (SELECT id FROM public.categories WHERE slug = 'mlecni-proizvodi' AND parent_id IS NULL LIMIT 1);

-- 2. Dodaj "Kiselo mleko" kao novu podkategoriju odmah nakon Jogurta (order 25)
INSERT INTO public.categories (id, name, slug, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Kiselo mleko', 'kiselo-mleko', '🥛', 25, p.id
FROM public.categories p
WHERE p.slug = 'mlecni-proizvodi' AND p.parent_id IS NULL
ON CONFLICT DO NOTHING;

-- 3. Preimenuj "Pavlaka i namazi" -> "Namazi"
UPDATE public.categories
SET name = 'Namazi', slug = 'namazi'
WHERE slug = 'pavlaka-i-namazi'
  AND parent_id = (SELECT id FROM public.categories WHERE slug = 'mlecni-proizvodi' AND parent_id IS NULL LIMIT 1);
