-- ============================================================================
-- Migracija: Čišćenje i konsolidacija kategorija za Pijacu domaće hrane
-- Datum: 2026-10-20
-- Sadržaj:
--   1. Krovna kategorija: Preimenovanje 'suvomesnati-proizvodi-i-delikates' u 'Meso, riba i delikatesi' (slug: 'meso')
--   2. Čišćenje i konsolidacija podkategorija za Meso i ribu
--   3. Uklanjanje preklapanja na više mesta (gljive, suvo voće, ulja, topli napici, posna jela)
--   4. Konsolidacija podkategorija u 'Brašno, testenine i žitarice' (spajanje duplikata)
--   5. Dopuna kategorije 'Jaja' sa 'Pačija, guščija i ostala jaja'
--   6. Migracija postojećih proizvoda u public.products radi očuvanja integriteta
-- ============================================================================

DO $$
DECLARE
  meat_parent_id TEXT;
  veggie_parent_id TEXT;
  spices_parent_id TEXT;
  juice_parent_id TEXT;
  ready_parent_id TEXT;
  bakery_parent_id TEXT;
  eggs_parent_id TEXT;
BEGIN
  -- --------------------------------------------------------------------------
  -- 1. Krovna kategorija za meso, ribu i delikatese
  -- --------------------------------------------------------------------------
  SELECT id INTO meat_parent_id
  FROM public.categories
  WHERE (slug IN ('suvomesnati-proizvodi-i-delikates', 'meso-i-mesne-preradjevine', 'meso')
         OR name ILIKE 'Suvomesnat%' OR name ILIKE 'Meso%')
    AND parent_id IS NULL
  ORDER BY "order" ASC
  LIMIT 1;

  IF meat_parent_id IS NOT NULL THEN
    UPDATE public.categories
    SET name = 'Meso, riba i delikatesi',
        slug = 'meso',
        icon = '🥩',
        "order" = 20,
        section = 'hrana'
    WHERE id = meat_parent_id;

    -- Ažuriraj public.products za stare nazive krovne kategorije
    UPDATE public.products
    SET category = 'Meso, riba i delikatesi'
    WHERE category IN ('Suvomesnati proizvodi i delikates', 'Meso i mesne prerađevine', 'Meso');

    -- 2. Čišćenje i konsolidacija podkategorija mesa i ribe
    -- A) Spoji perad u pilece-curece-meso
    UPDATE public.products
    SET category = 'Pileće i ćureće meso'
    WHERE category IN ('Perad', 'perad');

    DELETE FROM public.categories
    WHERE slug = 'perad' AND parent_id = meat_parent_id;

    -- B) Ukloni generičko sveze-meso (imamo svinjsko, juneće, pileće, jagnjeće)
    UPDATE public.products
    SET category = 'Meso, riba i delikatesi'
    WHERE category IN ('Sveže meso', 'sveze-meso');

    DELETE FROM public.categories
    WHERE slug = 'sveze-meso' AND parent_id = meat_parent_id;

    -- C) Spoji suseno-preradjeno-meso u suhomesnato
    UPDATE public.products
    SET category = 'Suhomesnato i pršute'
    WHERE category IN ('Sušeno i prerađeno meso', 'suseno-preradjeno-meso', 'Suhomesnato');

    DELETE FROM public.categories
    WHERE slug = 'suseno-preradjeno-meso' AND parent_id = meat_parent_id;

    UPDATE public.categories
    SET name = 'Suhomesnato i pršute',
        icon = '🥓',
        "order" = 70
    WHERE slug = 'suhomesnato' AND parent_id = meat_parent_id;

    -- D) Riba: ukloni zbirni duplikat ribe-riblji-proizvodi, zadrži svežu i dimljenu ribu
    UPDATE public.products
    SET category = 'Sveža rečna riba'
    WHERE category IN ('Ribe i riblji proizvodi', 'ribe-riblji-proizvodi');

    DELETE FROM public.categories
    WHERE slug = 'ribe-riblji-proizvodi' AND parent_id = meat_parent_id;

    UPDATE public.categories
    SET name = 'Dimljena i prerađena riba',
        icon = '🐟',
        "order" = 65
    WHERE slug = 'dimljena-riba' AND parent_id = meat_parent_id;

    -- E) Usklađivanje ostalog mesa
    UPDATE public.categories
    SET name = 'Ostalo meso i mesni proizvodi',
        "order" = 90
    WHERE slug = 'ostalo-meso' AND parent_id = meat_parent_id;
  END IF;

  -- --------------------------------------------------------------------------
  -- 3. Uklanjanje preklapanja na dva različita mesta
  -- --------------------------------------------------------------------------

  -- A) Gljive i pečurke: ukloni iz Voća i povrća (već postoji krovna 'gljive-i-tartufi')
  SELECT id INTO veggie_parent_id
  FROM public.categories
  WHERE slug IN ('voce-i-povrce', 'povrce-i-voce') AND parent_id IS NULL
  LIMIT 1;

  IF veggie_parent_id IS NOT NULL THEN
    UPDATE public.products
    SET category = 'Sveže i sušene gljive'
    WHERE category IN ('Pečurke i gljive', 'pecurke-i-gljive');

    DELETE FROM public.categories
    WHERE slug = 'pecurke-i-gljive' AND parent_id = veggie_parent_id;

    -- B) Suvo voće: ukloni iz Voća i povrća (već postoji krovna 'orasasti-plodovi-semenke-i-suvo-voce')
    UPDATE public.products
    SET category = 'Suvo voće'
    WHERE category IN ('Suvo voće', 'suvo-voce')
      AND EXISTS (
        SELECT 1 FROM public.categories
        WHERE slug = 'suvo-voce-kategorija'
      );

    DELETE FROM public.categories
    WHERE slug = 'suvo-voce' AND parent_id = veggie_parent_id;
  END IF;

  -- C) Ulje i sirće: ukloni iz Začina i lekovitog bilja (već postoji krovna 'hladno-cedjena-ulja-i-sirceta')
  SELECT id INTO spices_parent_id
  FROM public.categories
  WHERE slug IN ('cajevi-zacini-i-lekovito-bilje', 'zacini-i-bilje') AND parent_id IS NULL
  LIMIT 1;

  IF spices_parent_id IS NOT NULL THEN
    UPDATE public.products
    SET category = 'Hladno ceđena ulja'
    WHERE category IN ('Ulje i sirće', 'ulje-i-sirce');

    DELETE FROM public.categories
    WHERE slug = 'ulje-i-sirce' AND parent_id = spices_parent_id;
  END IF;

  -- D) Topli napitci: ukloni iz Sokova i sirupa
  SELECT id INTO juice_parent_id
  FROM public.categories
  WHERE slug IN ('sokovi-i-domaci-sirupi', 'sokovi-i-pica') AND parent_id IS NULL
  LIMIT 1;

  IF juice_parent_id IS NOT NULL THEN
    UPDATE public.products
    SET category = 'Domaći napitci'
    WHERE category IN ('Topli napitci', 'topli-napitci');

    DELETE FROM public.categories
    WHERE slug = 'topli-napitci' AND parent_id = juice_parent_id;
  END IF;

  -- E) Posna jela: ukloni iz Gotovih jela (već postoji krovna 'posno-vegansko-i-bez-glutena')
  SELECT id INTO ready_parent_id
  FROM public.categories
  WHERE slug = 'gotova-jela-i-delikates' AND parent_id IS NULL
  LIMIT 1;

  IF ready_parent_id IS NOT NULL THEN
    UPDATE public.products
    SET category = 'Posno'
    WHERE category IN ('Posna jela', 'posna-jela');

    DELETE FROM public.categories
    WHERE slug = 'posna-jela' AND parent_id = ready_parent_id;
  END IF;

  -- --------------------------------------------------------------------------
  -- 4. Konsolidacija podkategorija u 'Brašno, testenine i žitarice'
  -- --------------------------------------------------------------------------
  SELECT id INTO bakery_parent_id
  FROM public.categories
  WHERE slug IN ('brasno-testenine-i-zitarice', 'pekara-i-zitarice') AND parent_id IS NULL
  LIMIT 1;

  IF bakery_parent_id IS NOT NULL THEN
    -- Spoji testa-i-testenine u domaci-rezanci-i-testenine
    UPDATE public.products
    SET category = 'Domaći rezanci i testenine'
    WHERE category IN ('Testa i testenine', 'testa-i-testenine');

    DELETE FROM public.categories
    WHERE slug = 'testa-i-testenine' AND parent_id = bakery_parent_id;

    -- Spoji brasna u vodenicarsko-brasno
    UPDATE public.products
    SET category = 'Vodeničarsko brašno i proja'
    WHERE category IN ('Brašna', 'brasna');

    DELETE FROM public.categories
    WHERE slug = 'brasna' AND parent_id = bakery_parent_id;

    -- Ažuriraj redosled
    UPDATE public.categories SET "order" = 10 WHERE slug = 'hleb-i-peciva' AND parent_id = bakery_parent_id;
    UPDATE public.categories SET "order" = 20 WHERE slug = 'kore-za-pitu-i-gibanicu' AND parent_id = bakery_parent_id;
    UPDATE public.categories SET "order" = 30 WHERE slug = 'domaci-rezanci-i-testenine' AND parent_id = bakery_parent_id;
    UPDATE public.categories SET "order" = 40 WHERE slug = 'vodenicarsko-brasno' AND parent_id = bakery_parent_id;
    UPDATE public.categories SET "order" = 50 WHERE slug = 'zitarice-i-pahuljice' AND parent_id = bakery_parent_id;
    UPDATE public.categories SET "order" = 60 WHERE slug = 'pekara-ostalo' AND parent_id = bakery_parent_id;
  END IF;

  -- --------------------------------------------------------------------------
  -- 5. Dopuna kategorije Jaja
  -- --------------------------------------------------------------------------
  SELECT id INTO eggs_parent_id
  FROM public.categories
  WHERE slug = 'jaja' AND parent_id IS NULL
  LIMIT 1;

  IF eggs_parent_id IS NOT NULL THEN
    IF NOT EXISTS (SELECT 1 FROM public.categories WHERE slug = 'ostala-domaca-jaja') THEN
      INSERT INTO public.categories (id, name, slug, icon, "order", parent_id, section)
      VALUES (
        gen_random_uuid()::text,
        'Pačija, guščija i ostala jaja',
        'ostala-domaca-jaja',
        '🥚',
        30,
        eggs_parent_id,
        'hrana'
      );
    ELSE
      UPDATE public.categories
      SET name = 'Pačija, guščija i ostala jaja',
          icon = '🥚',
          "order" = 30,
          parent_id = eggs_parent_id,
          section = 'hrana'
      WHERE slug = 'ostala-domaca-jaja';
    END IF;
  END IF;

END $$;
