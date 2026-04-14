UPDATE public.categories
SET icon = '🍖'
WHERE slug = 'suhomesnato'
  AND parent_id IS NULL;
