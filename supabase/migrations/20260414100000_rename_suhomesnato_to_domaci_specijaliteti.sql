-- Rename category "Suhomesnato" → "Domaći specijaliteti"
-- Also update the slug and child category parent_slug references

-- Update the parent category
UPDATE public.categories
SET
  name = 'Domaći specijaliteti',
  slug = 'domaci-specijaliteti'
WHERE slug = 'suhomesnato'
  AND parent_id IS NULL;

-- Update child categories: parent_id references the UUID so they stay linked automatically.
-- But if any subcategory stores the parent slug as text, update those too.
-- (No such column exists in current schema — parent_id is UUID FK, so no action needed.)

-- Update any products that stored the category name as text
UPDATE public.products
SET category = 'Domaći specijaliteti'
WHERE lower(trim(category)) = 'suhomesnato';
