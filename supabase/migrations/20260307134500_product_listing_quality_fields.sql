-- Listing quality fields for mandatory publish checklist.

ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS origin text;

ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS shelf_life_days integer;

UPDATE public.products
SET origin = COALESCE(NULLIF(origin, ''), 'Nepoznato poreklo')
WHERE origin IS NULL OR origin = '';

UPDATE public.products
SET shelf_life_days = COALESCE(shelf_life_days, 30)
WHERE shelf_life_days IS NULL OR shelf_life_days <= 0;

ALTER TABLE public.products
  ALTER COLUMN origin SET DEFAULT 'Nepoznato poreklo',
  ALTER COLUMN origin SET NOT NULL;

ALTER TABLE public.products
  ALTER COLUMN shelf_life_days SET DEFAULT 30,
  ALTER COLUMN shelf_life_days SET NOT NULL;

ALTER TABLE public.products
  DROP CONSTRAINT IF EXISTS products_shelf_life_days_positive;

ALTER TABLE public.products
  ADD CONSTRAINT products_shelf_life_days_positive
  CHECK (shelf_life_days > 0);
