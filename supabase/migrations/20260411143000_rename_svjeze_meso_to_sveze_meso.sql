UPDATE public.categories
SET name = 'Sveže meso'
WHERE slug = 'sveze-meso'
   OR name IN ('Svježe meso', 'svježe meso', 'Svjeze meso', 'svjeze meso');
