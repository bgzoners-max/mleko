-- Obogaćena hijerarhija suhomesnatih proizvoda (Suhomesnate proizvode pod Meso)
-- 3 nivoa: Suhomesnate -> Šunke i pršute -> Pršut, Šunka, itd.

-- Šunke i pršute
INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Šunke i pršute', 'restaurant', 1, c.id
FROM public.categories c
WHERE c.name = 'Suhomesnate proizvode' AND c.parent_id IN (SELECT id FROM public.categories WHERE name = 'Meso' AND parent_id IS NULL)
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Šunke i pršute' AND parent_id = c.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Pršut', 'restaurant', 1, sc.id
FROM public.categories sc
WHERE sc.name = 'Šunke i pršute' AND sc.parent_id IN (SELECT id FROM public.categories WHERE name = 'Suhomesnate proizvode')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Pršut' AND parent_id = sc.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Šunka', 'restaurant', 2, sc.id
FROM public.categories sc WHERE sc.name = 'Šunke i pršute' AND sc.parent_id IN (SELECT id FROM public.categories WHERE name = 'Suhomesnate proizvode')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Šunka' AND parent_id = sc.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Vučena šunka', 'restaurant', 3, sc.id
FROM public.categories sc WHERE sc.name = 'Šunke i pršute' AND sc.parent_id IN (SELECT id FROM public.categories WHERE name = 'Suhomesnate proizvode')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Vučena šunka' AND parent_id = sc.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Rolovana šunka', 'restaurant', 4, sc.id
FROM public.categories sc WHERE sc.name = 'Šunke i pršute' AND sc.parent_id IN (SELECT id FROM public.categories WHERE name = 'Suhomesnate proizvode')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Rolovana šunka' AND parent_id = sc.id);

-- Kobasice
INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Kobasice', 'restaurant', 2, c.id
FROM public.categories c
WHERE c.name = 'Suhomesnate proizvode' AND c.parent_id IN (SELECT id FROM public.categories WHERE name = 'Meso' AND parent_id IS NULL)
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Kobasice' AND parent_id = c.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Sveže kobasice', 'restaurant', 1, sc.id
FROM public.categories sc WHERE sc.name = 'Kobasice' AND sc.parent_id IN (SELECT id FROM public.categories WHERE name = 'Suhomesnate proizvode')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Sveže kobasice' AND parent_id = sc.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Suve kobasice', 'restaurant', 2, sc.id
FROM public.categories sc WHERE sc.name = 'Kobasice' AND sc.parent_id IN (SELECT id FROM public.categories WHERE name = 'Suhomesnate proizvode')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Suve kobasice' AND parent_id = sc.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Čajna kobasica', 'restaurant', 3, sc.id
FROM public.categories sc WHERE sc.name = 'Kobasice' AND sc.parent_id IN (SELECT id FROM public.categories WHERE name = 'Suhomesnate proizvode')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Čajna kobasica' AND parent_id = sc.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Pečenica', 'restaurant', 4, sc.id
FROM public.categories sc WHERE sc.name = 'Kobasice' AND sc.parent_id IN (SELECT id FROM public.categories WHERE name = 'Suhomesnate proizvode')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Pečenica' AND parent_id = sc.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Sremska kobasica', 'restaurant', 5, sc.id
FROM public.categories sc WHERE sc.name = 'Kobasice' AND sc.parent_id IN (SELECT id FROM public.categories WHERE name = 'Suhomesnate proizvode')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Sremska kobasica' AND parent_id = sc.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Kulen / Kulenova seka', 'restaurant', 6, sc.id
FROM public.categories sc WHERE sc.name = 'Kobasice' AND sc.parent_id IN (SELECT id FROM public.categories WHERE name = 'Suhomesnate proizvode')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Kulen / Kulenova seka' AND parent_id = sc.id);

-- Slanina i panceta
INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Slanina i panceta', 'restaurant', 3, c.id
FROM public.categories c
WHERE c.name = 'Suhomesnate proizvode' AND c.parent_id IN (SELECT id FROM public.categories WHERE name = 'Meso' AND parent_id IS NULL)
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Slanina i panceta' AND parent_id = c.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Slanina', 'restaurant', 1, sc.id
FROM public.categories sc WHERE sc.name = 'Slanina i panceta' AND sc.parent_id IN (SELECT id FROM public.categories WHERE name = 'Suhomesnate proizvode')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Slanina' AND parent_id = sc.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Panceta', 'restaurant', 2, sc.id
FROM public.categories sc WHERE sc.name = 'Slanina i panceta' AND sc.parent_id IN (SELECT id FROM public.categories WHERE name = 'Suhomesnate proizvode')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Panceta' AND parent_id = sc.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Dimljena slanina', 'restaurant', 3, sc.id
FROM public.categories sc WHERE sc.name = 'Slanina i panceta' AND sc.parent_id IN (SELECT id FROM public.categories WHERE name = 'Suhomesnate proizvode')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Dimljena slanina' AND parent_id = sc.id);

-- Trlić (direktno pod Suhomesnate)
INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Trlić', 'restaurant', 4, c.id
FROM public.categories c
WHERE c.name = 'Suhomesnate proizvode' AND c.parent_id IN (SELECT id FROM public.categories WHERE name = 'Meso' AND parent_id IS NULL)
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Trlić' AND parent_id = c.id);

-- Domaći čvarci
INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Domaći čvarci', 'restaurant', 5, c.id
FROM public.categories c
WHERE c.name = 'Suhomesnate proizvode' AND c.parent_id IN (SELECT id FROM public.categories WHERE name = 'Meso' AND parent_id IS NULL)
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Domaći čvarci' AND parent_id = c.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Čvarci', 'restaurant', 1, sc.id
FROM public.categories sc WHERE sc.name = 'Domaći čvarci' AND sc.parent_id IN (SELECT id FROM public.categories WHERE name = 'Suhomesnate proizvode')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Čvarci' AND parent_id = sc.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Čvarci sa kožom', 'restaurant', 2, sc.id
FROM public.categories sc WHERE sc.name = 'Domaći čvarci' AND sc.parent_id IN (SELECT id FROM public.categories WHERE name = 'Suhomesnate proizvode')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Čvarci sa kožom' AND parent_id = sc.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Čvarci bez kože', 'restaurant', 3, sc.id
FROM public.categories sc WHERE sc.name = 'Domaći čvarci' AND sc.parent_id IN (SELECT id FROM public.categories WHERE name = 'Suhomesnate proizvode')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Čvarci bez kože' AND parent_id = sc.id);

-- Pečenice i vratina
INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Pečenice i vratina', 'restaurant', 6, c.id
FROM public.categories c
WHERE c.name = 'Suhomesnate proizvode' AND c.parent_id IN (SELECT id FROM public.categories WHERE name = 'Meso' AND parent_id IS NULL)
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Pečenice i vratina' AND parent_id = c.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Suva pečenica', 'restaurant', 1, sc.id
FROM public.categories sc WHERE sc.name = 'Pečenice i vratina' AND sc.parent_id IN (SELECT id FROM public.categories WHERE name = 'Suhomesnate proizvode')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Suva pečenica' AND parent_id = sc.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Domaća vratina', 'restaurant', 2, sc.id
FROM public.categories sc WHERE sc.name = 'Pečenice i vratina' AND sc.parent_id IN (SELECT id FROM public.categories WHERE name = 'Suhomesnate proizvode')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Domaća vratina' AND parent_id = sc.id);

-- Specijaliteti i delikatesi
INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Specijaliteti i delikatesi', 'restaurant', 7, c.id
FROM public.categories c
WHERE c.name = 'Suhomesnate proizvode' AND c.parent_id IN (SELECT id FROM public.categories WHERE name = 'Meso' AND parent_id IS NULL)
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Specijaliteti i delikatesi' AND parent_id = c.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Pršut u komadu', 'restaurant', 1, sc.id
FROM public.categories sc WHERE sc.name = 'Specijaliteti i delikatesi' AND sc.parent_id IN (SELECT id FROM public.categories WHERE name = 'Suhomesnate proizvode')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Pršut u komadu' AND parent_id = sc.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Rolovani pršut', 'restaurant', 2, sc.id
FROM public.categories sc WHERE sc.name = 'Specijaliteti i delikatesi' AND sc.parent_id IN (SELECT id FROM public.categories WHERE name = 'Suhomesnate proizvode')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Rolovani pršut' AND parent_id = sc.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Suvi vrat', 'restaurant', 3, sc.id
FROM public.categories sc WHERE sc.name = 'Specijaliteti i delikatesi' AND sc.parent_id IN (SELECT id FROM public.categories WHERE name = 'Suhomesnate proizvode')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Suvi vrat' AND parent_id = sc.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Suve rebarca', 'restaurant', 4, sc.id
FROM public.categories sc WHERE sc.name = 'Specijaliteti i delikatesi' AND sc.parent_id IN (SELECT id FROM public.categories WHERE name = 'Suhomesnate proizvode')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Suve rebarca' AND parent_id = sc.id);

-- Pakovanja
INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Pakovanja', 'restaurant', 8, c.id
FROM public.categories c
WHERE c.name = 'Suhomesnate proizvode' AND c.parent_id IN (SELECT id FROM public.categories WHERE name = 'Meso' AND parent_id IS NULL)
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Pakovanja' AND parent_id = c.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Vakum pakovanje', 'restaurant', 1, sc.id
FROM public.categories sc WHERE sc.name = 'Pakovanja' AND sc.parent_id IN (SELECT id FROM public.categories WHERE name = 'Suhomesnate proizvode')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Vakum pakovanje' AND parent_id = sc.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Na grame (100g, 200g)', 'restaurant', 2, sc.id
FROM public.categories sc WHERE sc.name = 'Pakovanja' AND sc.parent_id IN (SELECT id FROM public.categories WHERE name = 'Suhomesnate proizvode')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Na grame (100g, 200g)' AND parent_id = sc.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Poklon paketi', 'restaurant', 3, sc.id
FROM public.categories sc WHERE sc.name = 'Pakovanja' AND sc.parent_id IN (SELECT id FROM public.categories WHERE name = 'Suhomesnate proizvode')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Poklon paketi' AND parent_id = sc.id);
