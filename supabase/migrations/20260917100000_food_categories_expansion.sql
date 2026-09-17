-- ============================================================================
-- Migracija: Sveobuhvatno proširenje, prečišćavanje i uređenje sekcija za Domaće proizvode
-- Datum: 2026-09-17
-- Opis: Dodavanje podkategorija za Meso, Povrće i voće, Med, Mlečne proizvode,
--       Pekaru i Slatku zimnicu, uz kompletno mapiranje sekcija i redosleda
-- ============================================================================

-- ============================================================================
-- 1. Podkategorije za Meso
-- ============================================================================

DO $$
DECLARE
  meat_category_id UUID;
BEGIN
  SELECT id INTO meat_category_id 
  FROM public.categories 
  WHERE (slug IN ('meso', 'meso-i-mesne-preradjevine', 'meso-i-preradjevine', 'suvomesnati-proizvodi-i-delikates')
         OR name ILIKE 'Meso%' OR name ILIKE 'Suvomesnat%')
    AND parent_id IS NULL 
  ORDER BY "order" ASC 
  LIMIT 1;

  IF meat_category_id IS NOT NULL THEN
    -- Ažuriraj postojeće ako već postoje po slug-u
    UPDATE public.categories cat
    SET name = c.name,
        icon = c.icon,
        "order" = c.ord,
        parent_id = meat_category_id,
        section = 'meso'
    FROM (VALUES
      ('Svinjsko meso', 'svinjsko-meso', '🐖', 10),
      ('Juneće i goveđe meso', 'junece-govedje-meso', '🐄', 20),
      ('Pileće i ćureće meso', 'pilece-curece-meso', '🐔', 30),
      ('Jagnjeće i jareće meso', 'jagnjece-jarece-meso', '🐑', 40),
      ('Zečetina i divljač', 'zecetina-i-divljac', '🐇', 50),
      ('Ribe i riblji proizvodi', 'ribe-riblji-proizvodi', '🐟', 60),
      ('Sveža rečna riba', 'sveza-recna-riba', '🐟', 62),
      ('Dimljena riba', 'dimljena-riba', '🐟', 64),
      ('Sušeno i prerađeno meso', 'suseno-preradjeno-meso', '🥓', 70)
    ) AS c(name, slug, icon, ord)
    WHERE cat.slug = c.slug;

    -- Ubaci one koje još ne postoje
    INSERT INTO public.categories (id, name, slug, icon, "order", parent_id, section)
    SELECT gen_random_uuid(), c.name, c.slug, c.icon, c.ord, meat_category_id, 'meso'
    FROM (VALUES
      ('Svinjsko meso', 'svinjsko-meso', '🐖', 10),
      ('Juneće i goveđe meso', 'junece-govedje-meso', '🐄', 20),
      ('Pileće i ćureće meso', 'pilece-curece-meso', '🐔', 30),
      ('Jagnjeće i jareće meso', 'jagnjece-jarece-meso', '🐑', 40),
      ('Zečetina i divljač', 'zecetina-i-divljac', '🐇', 50),
      ('Ribe i riblji proizvodi', 'ribe-riblji-proizvodi', '🐟', 60),
      ('Sveža rečna riba', 'sveza-recna-riba', '🐟', 62),
      ('Dimljena riba', 'dimljena-riba', '🐟', 64),
      ('Sušeno i prerađeno meso', 'suseno-preradjeno-meso', '🥓', 70)
    ) AS c(name, slug, icon, ord)
    WHERE NOT EXISTS (
      SELECT 1 FROM public.categories WHERE slug = c.slug
    );
  END IF;
END $$;

-- ============================================================================
-- 2. Podkategorije za Povrće i voće (fokusirano na sveže proizvode bez preklapanja)
-- ============================================================================

DO $$
DECLARE
  veggie_category_id UUID;
BEGIN
  SELECT id INTO veggie_category_id 
  FROM public.categories 
  WHERE (slug IN ('voce-i-povrce', 'povrce-i-voce')
         OR name ILIKE '%voće%' OR name ILIKE '%povrće%')
    AND parent_id IS NULL 
  ORDER BY "order" ASC 
  LIMIT 1;

  IF veggie_category_id IS NOT NULL THEN
    UPDATE public.categories cat
    SET name = c.name,
        icon = c.icon,
        "order" = c.ord,
        parent_id = veggie_category_id,
        section = 'povrce'
    FROM (VALUES
      ('Sezonsko povrće', 'sezonsko-povrce', '🥕', 10),
      ('Korenasto povrće', 'korenasto-povrce', '🥔', 20),
      ('Lisnato povrće', 'lisnato-povrce', '🥬', 30),
      ('Sezonsko voće', 'sezonsko-voce', '🍎', 40),
      ('Bobičasto voće', 'bobicasto-voce', '🫐', 50),
      ('Citrusi i južno voće', 'citrusi-i-juzno-voce', '🍊', 60),
      ('Sveže začinsko bilje', 'sveze-zacinsko-bilje', '🌿', 70)
    ) AS c(name, slug, icon, ord)
    WHERE cat.slug = c.slug;

    INSERT INTO public.categories (id, name, slug, icon, "order", parent_id, section)
    SELECT gen_random_uuid(), c.name, c.slug, c.icon, c.ord, veggie_category_id, 'povrce'
    FROM (VALUES
      ('Sezonsko povrće', 'sezonsko-povrce', '🥕', 10),
      ('Korenasto povrće', 'korenasto-povrce', '🥔', 20),
      ('Lisnato povrće', 'lisnato-povrce', '🥬', 30),
      ('Sezonsko voće', 'sezonsko-voce', '🍎', 40),
      ('Bobičasto voće', 'bobicasto-voce', '🫐', 50),
      ('Citrusi i južno voće', 'citrusi-i-juzno-voce', '🍊', 60),
      ('Sveže začinsko bilje', 'sveze-zacinsko-bilje', '🌿', 70)
    ) AS c(name, slug, icon, ord)
    WHERE NOT EXISTS (
      SELECT 1 FROM public.categories WHERE slug = c.slug
    );
  END IF;
END $$;

-- ============================================================================
-- 3. Podkategorije za Med i pčelinji proizvodi
-- ============================================================================

DO $$
DECLARE
  honey_category_id UUID;
BEGIN
  SELECT id INTO honey_category_id 
  FROM public.categories 
  WHERE (slug IN ('med-i-pcelinji-proizvodi', 'med-i-pcelarski', 'med')
         OR name ILIKE 'Med%')
    AND parent_id IS NULL 
  ORDER BY "order" ASC 
  LIMIT 1;

  IF honey_category_id IS NOT NULL THEN
    UPDATE public.categories cat
    SET name = c.name,
        icon = c.icon,
        "order" = c.ord,
        parent_id = honey_category_id,
        section = 'pcelinji'
    FROM (VALUES
      ('Vrste meda', 'vrste-meda', '🍯', 10),
      ('Specijalni medovi', 'specijalni-medovi', '🍯', 20),
      ('Propolis', 'propolis', '🧪', 30),
      ('Matični mleč', 'maticni-mlec', '💊', 40),
      ('Polen i perga', 'polen-perga', '🌾', 50),
      ('Pčelinji vosak', 'pcelinji-vosak', '🕯️', 60),
      ('Medovina i medni likeri', 'medovina-likere', '🥃', 70)
    ) AS c(name, slug, icon, ord)
    WHERE cat.slug = c.slug;

    INSERT INTO public.categories (id, name, slug, icon, "order", parent_id, section)
    SELECT gen_random_uuid(), c.name, c.slug, c.icon, c.ord, honey_category_id, 'pcelinji'
    FROM (VALUES
      ('Vrste meda', 'vrste-meda', '🍯', 10),
      ('Specijalni medovi', 'specijalni-medovi', '🍯', 20),
      ('Propolis', 'propolis', '🧪', 30),
      ('Matični mleč', 'maticni-mlec', '💊', 40),
      ('Polen i perga', 'polen-perga', '🌾', 50),
      ('Pčelinji vosak', 'pcelinji-vosak', '🕯️', 60),
      ('Medovina i medni likeri', 'medovina-likere', '🥃', 70)
    ) AS c(name, slug, icon, ord)
    WHERE NOT EXISTS (
      SELECT 1 FROM public.categories WHERE slug = c.slug
    );
  END IF;
END $$;

-- ============================================================================
-- 4. Dopuna za Mlečne proizvode (Kozji/ovčiji program i Surutka/kefir)
-- ============================================================================

DO $$
DECLARE
  dairy_category_id UUID;
BEGIN
  SELECT id INTO dairy_category_id 
  FROM public.categories 
  WHERE slug = 'mlecni-proizvodi' AND parent_id IS NULL 
  LIMIT 1;

  IF dairy_category_id IS NOT NULL THEN
    UPDATE public.categories cat
    SET name = c.name,
        icon = c.icon,
        "order" = c.ord,
        parent_id = dairy_category_id,
        section = 'hrana'
    FROM (VALUES
      ('Kozji i ovčiji proizvodi', 'kozji-i-ovciji-proizvodi', '🐐', 35),
      ('Surutka i kefir', 'surutka-i-kefir', '🥛', 45)
    ) AS c(name, slug, icon, ord)
    WHERE cat.slug = c.slug;

    INSERT INTO public.categories (id, name, slug, icon, "order", parent_id, section)
    SELECT gen_random_uuid(), c.name, c.slug, c.icon, c.ord, dairy_category_id, 'hrana'
    FROM (VALUES
      ('Kozji i ovčiji proizvodi', 'kozji-i-ovciji-proizvodi', '🐐', 35),
      ('Surutka i kefir', 'surutka-i-kefir', '🥛', 45)
    ) AS c(name, slug, icon, ord)
    WHERE NOT EXISTS (
      SELECT 1 FROM public.categories WHERE slug = c.slug
    );
  END IF;
END $$;

-- ============================================================================
-- 5. Dopuna za Pekaru i žitarice (Kore za pitu, Domaća testenina, Vodeničarsko brašno)
-- ============================================================================

DO $$
DECLARE
  bakery_category_id UUID;
BEGIN
  SELECT id INTO bakery_category_id 
  FROM public.categories 
  WHERE slug IN ('pekara-i-zitarice', 'brasno-testenine-i-zitarice') AND parent_id IS NULL 
  LIMIT 1;

  IF bakery_category_id IS NOT NULL THEN
    UPDATE public.categories cat
    SET name = c.name,
        icon = c.icon,
        "order" = c.ord,
        parent_id = bakery_category_id,
        section = 'osnove'
    FROM (VALUES
      ('Domaće kore za pitu i gibanicu', 'kore-za-pitu-i-gibanicu', '🥟', 15),
      ('Domaći rezanci i testenine', 'domaci-rezanci-i-testenine', '🍝', 25),
      ('Vodeničarsko brašno i proja', 'vodenicarsko-brasno', '🌾', 35)
    ) AS c(name, slug, icon, ord)
    WHERE cat.slug = c.slug;

    INSERT INTO public.categories (id, name, slug, icon, "order", parent_id, section)
    SELECT gen_random_uuid(), c.name, c.slug, c.icon, c.ord, bakery_category_id, 'osnove'
    FROM (VALUES
      ('Domaće kore za pitu i gibanicu', 'kore-za-pitu-i-gibanicu', '🥟', 15),
      ('Domaći rezanci i testenine', 'domaci-rezanci-i-testenine', '🍝', 25),
      ('Vodeničarsko brašno i proja', 'vodenicarsko-brasno', '🌾', 35)
    ) AS c(name, slug, icon, ord)
    WHERE NOT EXISTS (
      SELECT 1 FROM public.categories WHERE slug = c.slug
    );
  END IF;
END $$;

-- ============================================================================
-- 6. Dopuna za Slatku zimnicu (Sitni kolači i vanilice)
-- ============================================================================

DO $$
DECLARE
  sweets_category_id UUID;
BEGIN
  SELECT id INTO sweets_category_id 
  FROM public.categories 
  WHERE slug IN ('slatka-zimnica-i-dzemovi', 'slatko-i-dzemovi') AND parent_id IS NULL 
  LIMIT 1;

  IF sweets_category_id IS NOT NULL THEN
    UPDATE public.categories cat
    SET name = c.name,
        icon = c.icon,
        "order" = c.ord,
        parent_id = sweets_category_id,
        section = 'domace'
    FROM (VALUES
      ('Sitni kolači i vanilice', 'tradicionalni-sitni-kolaci', '🍪', 60)
    ) AS c(name, slug, icon, ord)
    WHERE cat.slug = c.slug;

    INSERT INTO public.categories (id, name, slug, icon, "order", parent_id, section)
    SELECT gen_random_uuid(), c.name, c.slug, c.icon, c.ord, sweets_category_id, 'domace'
    FROM (VALUES
      ('Sitni kolači i vanilice', 'tradicionalni-sitni-kolaci', '🍪', 60)
    ) AS c(name, slug, icon, ord)
    WHERE NOT EXISTS (
      SELECT 1 FROM public.categories WHERE slug = c.slug
    );
  END IF;
END $$;

-- ============================================================================
-- 7. Kompletno mapiranje sekcija i optimalnog redosleda za Home Grid i All Categories
-- ============================================================================

-- Sekcija: Hrana (Top 1, 2 i 7 na Home)
UPDATE public.categories SET "order" = 10, section = 'hrana' WHERE slug = 'mlecni-proizvodi' AND parent_id IS NULL;
UPDATE public.categories SET "order" = 20, section = 'hrana' WHERE slug IN ('suvomesnati-proizvodi-i-delikates', 'meso', 'meso-i-mesne-preradjevine') AND parent_id IS NULL;
UPDATE public.categories SET "order" = 70, section = 'hrana' WHERE slug = 'jaja' AND parent_id IS NULL;

-- Sekcija: Sveže i prirodno (Top 3 na Home)
UPDATE public.categories SET "order" = 30, section = 'sveze' WHERE slug IN ('voce-i-povrce', 'povrce-i-voce') AND parent_id IS NULL;
UPDATE public.categories SET "order" = 130, section = 'sveze' WHERE slug = 'orasasti-plodovi-semenke-i-suvo-voce' AND parent_id IS NULL;
UPDATE public.categories SET "order" = 140, section = 'sveze' WHERE slug = 'gljive-i-tartufi' AND parent_id IS NULL;

-- Sekcija: Domaći proizvodi (Top 4, 5, 6 na Home)
UPDATE public.categories SET "order" = 40, section = 'domace' WHERE slug IN ('med-i-pcelinji-proizvodi', 'med-i-pcelarski') AND parent_id IS NULL;
UPDATE public.categories SET "order" = 50, section = 'domace' WHERE slug IN ('slana-zimnica', 'zimnica-i-namazi') AND parent_id IS NULL;
UPDATE public.categories SET "order" = 60, section = 'domace' WHERE slug IN ('slatka-zimnica-i-dzemovi', 'slatko-i-dzemovi') AND parent_id IS NULL;

-- Sekcija: Pića (Top 8 na Home)
UPDATE public.categories SET "order" = 80, section = 'pica' WHERE slug = 'vina-i-domace-rakije' AND parent_id IS NULL;
UPDATE public.categories SET "order" = 90, section = 'pica' WHERE slug IN ('sokovi-i-domaci-sirupi', 'sokovi-i-pica') AND parent_id IS NULL;

-- Sekcija: Osnove za kuhinju
UPDATE public.categories SET "order" = 100, section = 'osnove' WHERE slug IN ('brasno-testenine-i-zitarice', 'pekara-i-zitarice', 'pekarsko-i-testa', 'brasno-i-zitarice') AND parent_id IS NULL;
UPDATE public.categories SET "order" = 110, section = 'osnove' WHERE slug = 'hladno-cedjena-ulja-i-sirceta' AND parent_id IS NULL;
UPDATE public.categories SET "order" = 120, section = 'osnove' WHERE slug IN ('cajevi-zacini-i-lekovito-bilje', 'zacini-i-bilje') AND parent_id IS NULL;

-- Sekcija: Specijaliteti
UPDATE public.categories SET "order" = 150, section = 'specijaliteti' WHERE slug = 'gotova-jela-i-delikates' AND parent_id IS NULL;
UPDATE public.categories SET "order" = 160, section = 'specijaliteti' WHERE slug = 'smrznuti-proizvodi' AND parent_id IS NULL;
UPDATE public.categories SET "order" = 170, section = 'specijaliteti' WHERE slug = 'posno-vegansko-i-bez-glutena' AND parent_id IS NULL;

-- Sekcija: Ostalo
UPDATE public.categories SET "order" = 180, section = 'ostalo' WHERE slug = 'prirodna-kozmetika' AND parent_id IS NULL;
UPDATE public.categories SET "order" = 190, section = 'ostalo' WHERE slug = 'zanatski-proizvodi-i-rukotvorine' AND parent_id IS NULL;
UPDATE public.categories SET "order" = 200, section = 'ostalo' WHERE slug = 'poklon-paketi' AND parent_id IS NULL;

-- ============================================================================
-- 8. Ispravka istorijskih slug-ova
-- ============================================================================
UPDATE public.categories 
SET slug = 'tartufi-i-proizvodi' 
WHERE slug = 'tartufi-i-proizvosdi';