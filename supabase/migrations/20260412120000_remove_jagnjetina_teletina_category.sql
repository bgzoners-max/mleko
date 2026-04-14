UPDATE public.products
SET category = 'Sveže meso'
WHERE lower(trim(category)) IN (
  'jagnjetina i teletina',
  'janjetina i teletina'
);

DELETE FROM public.categories
WHERE slug IN ('jagnjetina-teletina', 'janjetina-teletina')
   OR lower(trim(name)) IN (
     'jagnjetina i teletina',
     'janjetina i teletina'
   );
