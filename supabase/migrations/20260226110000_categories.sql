-- Tabela kategorija – hijerarhija (parent_id za podkategorije)

CREATE TABLE IF NOT EXISTS public.categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  icon TEXT,
  "order" INTEGER DEFAULT 0,
  parent_id UUID REFERENCES public.categories(id) ON DELETE CASCADE
);

ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Categories are viewable by everyone" ON public.categories;
CREATE POLICY "Categories are viewable by everyone"
  ON public.categories FOR SELECT
  TO public
  USING (true);

-- Seed podataka – idempotent (bez duplikata pri ponovnom pokretanju)
INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Mleko i sirevi', 'egg', 1, NULL
WHERE NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Mleko i sirevi' AND parent_id IS NULL);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Meso', 'restaurant', 2, NULL
WHERE NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Meso' AND parent_id IS NULL);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Povrće i voće', 'eco', 3, NULL
WHERE NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Povrće i voće' AND parent_id IS NULL);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Med i pčelinji proizvodi', 'water_drop', 4, NULL
WHERE NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Med i pčelinji proizvodi' AND parent_id IS NULL);

-- Podkategorije za Mleko i sirevi
INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Sir', 'egg', 1, c.id
FROM public.categories c
WHERE c.name = 'Mleko i sirevi' AND c.parent_id IS NULL
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Sir' AND parent_id = c.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Kačkavalj', 'egg', 2, c.id
FROM public.categories c
WHERE c.name = 'Mleko i sirevi' AND c.parent_id IS NULL
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Kačkavalj' AND parent_id = c.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Kajmak', 'bakery_dining', 3, c.id
FROM public.categories c
WHERE c.name = 'Mleko i sirevi' AND c.parent_id IS NULL
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Kajmak' AND parent_id = c.id);
