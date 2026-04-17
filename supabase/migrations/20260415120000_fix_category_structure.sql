-- Čišćenje strukturnih problema u hijerarhiji kategorija
-- Problem 1: Top-level "Suhomesnato" duplikat (isto postoji kao podkategorija unutar "Meso i mesne prerađevine")
-- Problem 2: "Čajevi" postoje u dva mesta (Sokovi i pića + Začini i bilje)
-- Problem 3: "Med i namazi" unutar "Slatko i džemovi" konflikuje sa top-level "Med i pčelarski"
-- Problem 4: "Organsko" i "Sezonsko" su atributi, ne kategorije → zamena konkretnim podkategorijama

-- ─── Problem 1: Ukloni top-level Suhomesnato ─────────────────────────────────
-- Proizvodi iz starih podkategorija su već migrirani u 20260414140000_reorganize_meat_categories.sql
-- Preostali proizvodi s category='Suhomesnato' odgovaraju podkategoriji pod Meso i mesne prerađevine – ok.
-- ON DELETE CASCADE briše i podkategorije automatski.

DELETE FROM public.categories
WHERE slug = 'suhomesnato' AND parent_id IS NULL;


-- ─── Problem 2: Čajevi u Sokovi i pića → premesti u Začini i bilje ───────────
-- Preimenuj podkategoriju u Sokovi i pića na "Topli napitci" da reflektuje
-- gotove/zapakovane napitke, a rasuti/biljni čajevi ostaju u Začini i bilje.

UPDATE public.categories
SET name = 'Topli napitci', slug = 'topli-napitci'
WHERE slug = 'cajevi'
  AND parent_id = (SELECT id FROM public.categories WHERE slug = 'sokovi-i-pica' AND parent_id IS NULL LIMIT 1);

-- Migracija proizvoda: ako prodavac stavio u "Čajevi" (sokovi), prebaci u Čajevi (bilje)
-- Napomena: koristimo ime "Čajevi" koje dijeli oba – ali samo oni koji su doslovno pisali
-- "Čajevi" a imali ih pod sokovi bićeprebačeni; ostali ostaju OK.
-- Pošto su oba imali ime "Čajevi" pre ove migracije, ne možemo ih razlikovati po category tekstu.
-- Novi unosi će koristiti "Topli napitci" za sokovi-i-pica, pa ovo je samo zaštita unapred.


-- ─── Problem 3: Ukloni "Med i namazi" iz Slatko i džemovi ────────────────────
-- Migracija proizvoda: "Med i namazi" → "Med" (podkategorija med-i-pcelarski)

UPDATE public.products
SET category = 'Med'
WHERE category = 'Med i namazi';

DELETE FROM public.categories
WHERE slug = 'med-i-namazi'
  AND parent_id = (SELECT id FROM public.categories WHERE slug = 'slatko-i-dzemovi' AND parent_id IS NULL LIMIT 1);


-- ─── Problem 4: Zamena Organsko i Sezonsko konkretnim podkategorijama ─────────
-- Migracija proizvoda na najpribližnije konkretne podkategorije
UPDATE public.products SET category = 'Sveže voće'   WHERE category = 'Organsko';
UPDATE public.products SET category = 'Sveže voće'   WHERE category = 'Sezonsko';

-- Obriši apstraktne podkategorije
DELETE FROM public.categories
WHERE slug IN ('organsko', 'sezonsko')
  AND parent_id = (SELECT id FROM public.categories WHERE slug = 'voce-i-povrce' AND parent_id IS NULL LIMIT 1);

-- Dodaj konkretne podkategorije umesto njih
INSERT INTO public.categories (id, name, slug, icon, "order", parent_id, section)
SELECT
  gen_random_uuid(),
  c.name,
  c.slug,
  c.icon,
  c.ord,
  (SELECT id FROM public.categories WHERE slug = 'voce-i-povrce' AND parent_id IS NULL LIMIT 1),
  'sveze'
FROM (VALUES
  ('Suvo voće',        'suvo-voce',        '🍇', 30),
  ('Pečurke i gljive', 'pecurke-i-gljive', '🍄', 40)
) AS c(name, slug, icon, ord)
ON CONFLICT DO NOTHING;
