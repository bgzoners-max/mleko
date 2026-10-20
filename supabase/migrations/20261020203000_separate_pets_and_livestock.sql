-- ============================================================================
-- Migracija: Razdvajanje Kućnih ljubimaca i Stoke, i čišćenje anomalija kategorija
-- Datum: 2026-10-20
-- Sadržaj:
--   1. Kućni ljubimci: preimenovanje 'ljubimci' u 'Kućni ljubimci'
--   2. Poljoprivreda: premeštanje 'domace_zivotinje' (stoka) i 'pcelarstvo' pod 'poljoprivreda'
--   3. Živinarstvo: kreiranje 'zivinarstvo' pod 'poljoprivreda' i premeštanje kokosaka, curaka, pataka
--   4. Stočarska oprema i premiksi: kreiranje 'stocarska_oprema' pod 'poljoprivreda', premeštanje muzilica i premiksa
--   5. Ažuriranje 'zivina_ptice' u 'Ptice i ostali kućni ljubimci' i 'oprema_za_zivotinje' u 'Hrana i oprema za kućne ljubimce'
--   6. Čišćenje duplikata u nekretninama (prodaja_kuca -> kuce_prodaja, industrijski_placevi -> industrijske_zone)
--   7. Čišćenje zaostalih duplikata u vozilima, tehnici i domu
-- ============================================================================

DO $$
BEGIN
  -- 1. Preimenuj korensku kategoriju 'ljubimci'
  UPDATE public.classified_categories
  SET name = 'Kućni ljubimci'
  WHERE id = 'ljubimci';

  -- 2. Prebaci 'domace_zivotinje' pod 'poljoprivreda' sa ikonicom svinje
  UPDATE public.classified_categories
  SET parent_id = 'poljoprivreda',
      name = 'Domaće životinje i stoka',
      icon_name = 'pig',
      sort_order = 50
  WHERE id = 'domace_zivotinje';

  -- 3. Prebaci 'pcelarstvo' pod 'poljoprivreda'
  UPDATE public.classified_categories
  SET parent_id = 'poljoprivreda',
      sort_order = 60
  WHERE id = 'pcelarstvo';

  -- 4. Kreiraj 'zivinarstvo' (Živinarstvo i peradarstvo) pod 'poljoprivreda'
  INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order, is_condition_applicable)
  VALUES ('zivinarstvo', 'Živinarstvo i peradarstvo', 'egg', 'poljoprivreda', 52, false)
  ON CONFLICT (id) DO UPDATE SET
      name = EXCLUDED.name,
      icon_name = EXCLUDED.icon_name,
      parent_id = EXCLUDED.parent_id,
      sort_order = EXCLUDED.sort_order,
      is_condition_applicable = EXCLUDED.is_condition_applicable;

  -- Prebaci kokoške, ćurke i patke/guske pod 'zivinarstvo'
  UPDATE public.classified_categories
  SET parent_id = 'zivinarstvo'
  WHERE id IN ('kokoske_pilici', 'curke', 'patke_guske');

  -- 5. Kreiraj 'stocarska_oprema' (Stočarska oprema i muzilice) pod 'poljoprivreda'
  INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order, is_condition_applicable)
  VALUES ('stocarska_oprema', 'Stočarska oprema i muzilice', 'precision_manufacturing', 'poljoprivreda', 54, true)
  ON CONFLICT (id) DO UPDATE SET
      name = EXCLUDED.name,
      icon_name = EXCLUDED.icon_name,
      parent_id = EXCLUDED.parent_id,
      sort_order = EXCLUDED.sort_order,
      is_condition_applicable = EXCLUDED.is_condition_applicable;

  -- Prebaci muzilice i hranilice pod 'stocarska_oprema'
  UPDATE public.classified_categories
  SET parent_id = 'stocarska_oprema'
  WHERE id = 'hranilice_pojilice_muzilice';

  -- Prebaci stočne koncentrate i premikse pod 'stocna_hrana' u poljoprivredi
  UPDATE public.classified_categories
  SET parent_id = 'stocna_hrana'
  WHERE id = 'koncentrati_premiksi';

  -- 6. Ažuriraj nazive podkategorija u Kućnim ljubimcima
  UPDATE public.classified_categories
  SET name = 'Ptice i ostali kućni ljubimci',
      icon_name = 'bird'
  WHERE id = 'zivina_ptice';

  UPDATE public.classified_categories
  SET name = 'Hrana i oprema za kućne ljubimce'
  WHERE id = 'oprema_za_zivotinje';

  -- Dodaj opštu opremu za ljubimce pod oprema_za_zivotinje
  INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order, is_condition_applicable)
  VALUES ('oprema_igracke_ljubimci', 'Povodci, higijena i oprema za ljubimce', 'shopping_bag', 'oprema_za_zivotinje', 30, true)
  ON CONFLICT (id) DO NOTHING;

END;
$$;

-- 7. Bezbedno spajanje (merge) duplikata i preusmeravanje referenci
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN (
    SELECT * FROM (VALUES
      -- Stari/dupli ID -> Novi kanonski ID
      ('stocarstvo_zivotinje', 'domace_zivotinje'),
      ('prodaja_kuca', 'kuce_prodaja'),
      ('industrijski_placevi', 'industrijske_zone'),
      ('gume_felne', 'auto_gume_felne'),
      ('auto_multimedija_navigacija', 'auto_multimedija'),
      ('stampaci_skeneri_toneri', 'stampaci_toneri'),
      ('mrezna_oprema_ruteri', 'ruteri_svicevi'),
      ('memorije_hard_diskovi', 'ssd_hard_diskovi'),
      ('mali_kuhinjski_aparati', 'mali_kucni_aparati'),
      ('aparati_za_kafu', 'mali_kucni_aparati')
    ) AS t(old_id, new_id)
  ) LOOP
    IF EXISTS (SELECT 1 FROM public.classified_categories WHERE id = r.old_id) THEN
      IF EXISTS (SELECT 1 FROM public.classified_categories WHERE id = r.new_id) THEN
        -- 1. Preusmeri oglase
        UPDATE public.classified_ads
        SET category_id = r.new_id
        WHERE category_id = r.old_id;

        -- 2. Preusmeri pretplate
        INSERT INTO public.classified_category_subscriptions (user_id, category_id, search_query, max_price, currency)
        SELECT user_id, r.new_id, search_query, max_price, currency
        FROM public.classified_category_subscriptions
        WHERE category_id = r.old_id
        ON CONFLICT (user_id, category_id, search_query) DO NOTHING;

        DELETE FROM public.classified_category_subscriptions
        WHERE category_id = r.old_id;

        -- 3. Preusmeri decu
        UPDATE public.classified_categories
        SET parent_id = r.new_id
        WHERE parent_id = r.old_id;

        -- 4. Obriši stari duplikat
        DELETE FROM public.classified_categories
        WHERE id = r.old_id;
      END IF;
    END IF;
  END LOOP;
END;
$$;
