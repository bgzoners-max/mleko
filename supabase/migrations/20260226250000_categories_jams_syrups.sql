-- Džemovi, slatka, sirupi i prirodni sokovi (Naše selo)

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Džemovi, slatka i sokovi', 'eco', 5, NULL
WHERE NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Džemovi, slatka i sokovi' AND parent_id IS NULL);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Džemovi i pekmez', 'eco', 1, c.id
FROM public.categories c
WHERE c.name = 'Džemovi, slatka i sokovi' AND c.parent_id IS NULL
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Džemovi i pekmez' AND parent_id = c.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Slatko od voća', 'eco', 2, c.id
FROM public.categories c
WHERE c.name = 'Džemovi, slatka i sokovi' AND c.parent_id IS NULL
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Slatko od voća' AND parent_id = c.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Sirupi', 'eco', 3, c.id
FROM public.categories c
WHERE c.name = 'Džemovi, slatka i sokovi' AND c.parent_id IS NULL
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Sirupi' AND parent_id = c.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Prirodni sokovi', 'eco', 4, c.id
FROM public.categories c
WHERE c.name = 'Džemovi, slatka i sokovi' AND c.parent_id IS NULL
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Prirodni sokovi' AND parent_id = c.id);
