-- Rename parent category "Meso i prerađevine" → "Meso"
UPDATE public.categories
SET
  name = 'Meso',
  slug = 'meso'
WHERE slug = 'meso-i-preradjevine'
  AND parent_id IS NULL;

-- Update any products that stored the old parent category name as text (safety net)
UPDATE public.products
SET category = 'Meso'
WHERE lower(trim(category)) = 'meso i prerađevine'
   OR lower(trim(category)) = 'meso i preradjevine';
