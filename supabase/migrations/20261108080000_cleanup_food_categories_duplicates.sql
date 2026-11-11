-- ============================================================================
-- Migracija: 20261108080000_cleanup_food_categories_duplicates.sql
-- Naziv: Čišćenje i konsolidacija dupliranih i preklapajućih kategorija
--        u Pijaci hrane (Med i pčelinji proizvodi, Voće i povrće)
-- ============================================================================

DO $$
DECLARE
  v_honey_parent_id UUID;
  v_veggie_parent_id UUID;
BEGIN
  -- --------------------------------------------------------------------------
  -- 1. Med i pčelinji proizvodi
  -- --------------------------------------------------------------------------
  SELECT id INTO v_honey_parent_id
  FROM public.categories
  WHERE slug = 'med-i-pcelinji-proizvodi' AND parent_id IS NULL
  LIMIT 1;

  IF v_honey_parent_id IS NOT NULL THEN
    -- Ažuriraj public.products ako postoje proizvodi vezani za kategorije koje se spajaju
    UPDATE public.products
    SET category = 'Med'
    WHERE category IN ('Vrste meda', 'vrste-meda', 'Specijalni medovi', 'specijalni-medovi');

    UPDATE public.products
    SET category = 'Propolis i tinkture'
    WHERE category IN ('Propolis', 'propolis');

    UPDATE public.products
    SET category = 'Pčelinji vosak'
    WHERE category IN ('Vosak i sveće', 'vosak-i-svece');

    -- Ukloni doslovni duplikat Polen i perga (slug: polen-perga)
    DELETE FROM public.categories
    WHERE slug = 'polen-perga' AND parent_id = v_honey_parent_id;

    -- Ukloni suvišne i preklapajuće kategorije
    DELETE FROM public.categories
    WHERE slug IN ('vrste-meda', 'specijalni-medovi', 'propolis', 'vosak-i-svece')
      AND parent_id = v_honey_parent_id;

    -- Usklađivanje redosleda i naziva preostalih kategorija
    UPDATE public.categories
    SET name = 'Med', icon = '🍯', "order" = 10, section = 'hrana'
    WHERE slug = 'med' AND parent_id = v_honey_parent_id;

    UPDATE public.categories
    SET name = 'Propolis i tinkture', icon = '💧', "order" = 20, section = 'hrana'
    WHERE slug = 'propolis-i-tinkture' AND parent_id = v_honey_parent_id;

    UPDATE public.categories
    SET name = 'Polen i perga', icon = '🌼', "order" = 30, section = 'hrana'
    WHERE slug = 'polen-i-perga' AND parent_id = v_honey_parent_id;

    UPDATE public.categories
    SET name = 'Matični mleč', icon = '💊', "order" = 40, section = 'hrana'
    WHERE slug = 'maticni-mlec' AND parent_id = v_honey_parent_id;

    UPDATE public.categories
    SET name = 'Pčelinji vosak', icon = '🕯️', "order" = 50, section = 'hrana'
    WHERE slug = 'pcelinji-vosak' AND parent_id = v_honey_parent_id;

    UPDATE public.categories
    SET name = 'Medovina i medni likeri', icon = '🥃', "order" = 60, section = 'hrana'
    WHERE slug = 'medovina-likere' AND parent_id = v_honey_parent_id;

    UPDATE public.categories
    SET name = 'Ostalo', icon = '🍶', "order" = 70, section = 'hrana'
    WHERE slug = 'ostalo-med' AND parent_id = v_honey_parent_id;
  END IF;

  -- --------------------------------------------------------------------------
  -- 2. Voće i povrće
  -- --------------------------------------------------------------------------
  SELECT id INTO v_veggie_parent_id
  FROM public.categories
  WHERE slug = 'voce-i-povrce' AND parent_id IS NULL
  LIMIT 1;

  IF v_veggie_parent_id IS NOT NULL THEN
    -- Ažuriraj public.products za sezonsko voće i povrće
    UPDATE public.products
    SET category = 'Sveže voće'
    WHERE category IN ('Sezonsko voće', 'sezonsko-voce');

    UPDATE public.products
    SET category = 'Sveže povrće'
    WHERE category IN ('Sezonsko povrće', 'sezonsko-povrce');

    -- Ukloni duple / preklapajuće kategorije
    DELETE FROM public.categories
    WHERE slug IN ('sezonsko-voce', 'sezonsko-povrce')
      AND parent_id = v_veggie_parent_id;

    -- Usklađivanje redosleda i naziva preostalih kategorija
    UPDATE public.categories
    SET name = 'Sveže voće', icon = '🍎', "order" = 10, section = 'hrana'
    WHERE slug = 'sveze-voce' AND parent_id = v_veggie_parent_id;

    UPDATE public.categories
    SET name = 'Bobičasto voće', icon = '🫐', "order" = 20, section = 'hrana'
    WHERE slug = 'bobicasto-voce' AND parent_id = v_veggie_parent_id;

    UPDATE public.categories
    SET name = 'Citrusi i južno voće', icon = '🍊', "order" = 30, section = 'hrana'
    WHERE slug = 'citrusi-i-juzno-voce' AND parent_id = v_veggie_parent_id;

    UPDATE public.categories
    SET name = 'Sveže povrće', icon = '🥦', "order" = 40, section = 'hrana'
    WHERE slug = 'sveze-povrce' AND parent_id = v_veggie_parent_id;

    UPDATE public.categories
    SET name = 'Korenasto povrće', icon = '🥔', "order" = 50, section = 'hrana'
    WHERE slug = 'korenasto-povrce' AND parent_id = v_veggie_parent_id;

    UPDATE public.categories
    SET name = 'Lisnato povrće', icon = '🥬', "order" = 60, section = 'hrana'
    WHERE slug = 'lisnato-povrce' AND parent_id = v_veggie_parent_id;

    UPDATE public.categories
    SET name = 'Sveže začinsko bilje', icon = '🌿', "order" = 70, section = 'hrana'
    WHERE slug = 'sveze-zacinsko-bilje' AND parent_id = v_veggie_parent_id;
  END IF;

END $$;
