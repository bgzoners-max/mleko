UPDATE public.products
SET category = 'Sveže meso'
WHERE category = 'Mleveno meso';

DELETE FROM public.categories
WHERE slug = 'mleveno-meso'
   OR name = 'Mleveno meso';
