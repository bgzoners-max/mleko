-- Podkategorije za Meso – mesne i suhomesnate proizvode (Naše selo)

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Sveže meso', 'restaurant', 1, c.id
FROM public.categories c
WHERE c.name = 'Meso' AND c.parent_id IS NULL
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Sveže meso' AND parent_id = c.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Suhomesnate proizvode', 'restaurant', 2, c.id
FROM public.categories c
WHERE c.name = 'Meso' AND c.parent_id IS NULL
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Suhomesnate proizvode' AND parent_id = c.id);
