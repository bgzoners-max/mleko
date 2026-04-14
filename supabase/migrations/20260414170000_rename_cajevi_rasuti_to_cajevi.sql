-- Rename subcategory "Čajevi rasuti" → "Čajevi" under Začini i bilje

UPDATE public.categories
SET name = 'Čajevi', slug = 'cajevi-bilje'
WHERE slug = 'cajevi-rasuti';
