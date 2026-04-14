UPDATE public.categories
SET name = 'Jagnjetina i teletina',
    slug = 'jagnjetina-teletina'
WHERE slug = 'janjetina-teletina'
   OR name IN (
     'Janjetina i teletina',
     'janjetina i teletina'
   );
