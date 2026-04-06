-- Poveži nepovezane proizvode sa ispravnim kategorijama

-- "Domaće mleko masnoće 4%" nema kategoriju → Mleko
UPDATE public.products
SET category = 'Mleko'
WHERE (category IS NULL OR category = '')
  AND name ILIKE '%mleko%';

-- Kačkavalj je vrsta sira → Sir
UPDATE public.products
SET category = 'Sir'
WHERE category = 'Kačkavalj';

-- Ulje bundeve → dodaj kategoriju "Ulje i sirće" pod Zimnica i namazi
INSERT INTO public.categories (id, name, slug, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Ulje i sirće', 'ulje-i-sirce', '🫙', 60, p.id
FROM public.categories p
WHERE p.slug = 'zimnica-i-namazi' AND p.parent_id IS NULL
ON CONFLICT DO NOTHING;
