-- ============================================================================
-- Migracija: Čišćenje duplikata, konsolidacija i veliko tržišno proširenje kategorija
-- Datum: 2026-09-17
-- Sadržaj:
--   1. Transakciono bezbedno spajanje (merge) duplikata i uklanjanje zaostalih praznih listova
--   2. Premeštanje ugostiteljske i trgovačke opreme iz 'usluge' u 'masine_alati' sa stanjem
--   3. Uvođenje solarnih sistema, toplotnih pumpi i šumarstva
--   4. Razrada Nivoa 3 za novije krovne stubove (deca_bebe, zdravlje_lepota, knjige_edukacija, umetnost_rukotvorine)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Transakciono bezbedno spajanje duplikata i preusmeravanje referenci
-- ----------------------------------------------------------------------------
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN (
    SELECT * FROM (VALUES
      -- Nekretnine (stari ID -> novi kanonski ID)
      ('prodaja_stanova', 'stanovi_prodaja'),
      ('izdavanje_stanova', 'stanovi_izdavanje'),
      ('kuce_na_prodaju', 'kuce_prodaja'),
      ('izdavanje_kuca', 'kuce_izdavanje'),
      ('placevi_za_kuce', 'placevi_gradnja'),
      ('industrijske_placevi', 'industrijske_zone'),

      -- Poljoprivreda (stari prazni listovi iz početnog seed-a -> razvijene grane)
      ('traktori', 'traktori_kombajni'),
      ('prikljucci', 'prikljucne_masine'),

      -- Vozila (zaostali prazni listovi -> razvijene grane)
      ('motocikli', 'motocikli_atv'),
      ('plovila_nautika', 'plovila_camci'),

      -- Zaostale zbirne kategorije automobila (premeštene na države porekla)
      ('automobili_nemacki', 'auto_nemacka'),
      ('automobili_francuski', 'auto_francuska'),
      ('automobili_italijanski', 'auto_italija'),
      ('automobili_azijski', 'auto_japan'),

      -- Mašine i alati (zaostao prazan list)
      ('elektro_alati', 'elektro_aku_alati'),

      -- Telefoni (zbirne/stare stavke -> zvanični kanonski brendovi)
      ('iphone', 'apple'),
      ('honor_huawei', 'huawei'),
      ('ostali_smartfoni', 'smartfoni')
    ) AS t(old_id, new_id)
  ) LOOP
    IF EXISTS (SELECT 1 FROM public.classified_categories WHERE id = r.old_id) THEN
      IF EXISTS (SELECT 1 FROM public.classified_categories WHERE id = r.new_id) THEN
        -- 1. Preusmeri sve postojeće oglase na novu kanonsku kategoriju
        UPDATE public.classified_ads
        SET category_id = r.new_id
        WHERE category_id = r.old_id;

        -- 2. Preusmeri pretplate korisnika (sprečavajući UNIQUE constraint grešku)
        INSERT INTO public.classified_category_subscriptions (user_id, category_id, search_query, max_price, currency)
        SELECT user_id, r.new_id, search_query, max_price, currency
        FROM public.classified_category_subscriptions
        WHERE category_id = r.old_id
        ON CONFLICT (user_id, category_id, search_query) DO NOTHING;

        DELETE FROM public.classified_category_subscriptions
        WHERE category_id = r.old_id;

        -- 3. Preusmeri decu na novog roditelja
        UPDATE public.classified_categories
        SET parent_id = r.new_id
        WHERE parent_id = r.old_id;

        -- 4. Bezbedno obriši zastareli dupli zapis
        DELETE FROM public.classified_categories
        WHERE id = r.old_id;
      END IF;
    END IF;
  END LOOP;
END;
$$;

-- ----------------------------------------------------------------------------
-- 2. Premeštanje ugostiteljske i trgovačke opreme iz 'usluge' u 'masine_alati'
--    Fizička profesionalna oprema ima stanje (novo/polovno)
-- ----------------------------------------------------------------------------
UPDATE public.classified_categories
SET parent_id = 'masine_alati',
    is_condition_applicable = true,
    sort_order = 65
WHERE id = 'ugostiteljska_trgovacka_oprema';

INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order, is_condition_applicable)
VALUES
    ('ugostiteljska_oprema', 'Ugostiteljska oprema (peći, roštilji, vitrine, ledomati)', 'restaurant', 'ugostiteljska_trgovacka_oprema', 10, true),
    ('pekarska_mesarska_oprema', 'Pekarska i mesarska oprema (mešalice, kuter mašine, mesoreznice)', 'bakery_dining', 'ugostiteljska_trgovacka_oprema', 20, true),
    ('trgovacka_oprema', 'Trgovačka oprema (police, vage, rashladni stolovi, kase)', 'storefront', 'ugostiteljska_trgovacka_oprema', 30, true)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order,
    is_condition_applicable = true;

-- ----------------------------------------------------------------------------
-- 3. Nova strateška tržišna proširenja: Solarni sistemi, toplotne pumpe i šumarstvo
-- ----------------------------------------------------------------------------

-- A) Solarni sistemi i oprema (pod Građevinarstvo)
INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order, is_condition_applicable)
VALUES
    ('solarni_sistemi', 'Solarni sistemi i oprema', 'solar_power', 'gradjevinarstvo', 75, true)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order,
    is_condition_applicable = true;

INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order, is_condition_applicable)
VALUES
    ('solarni_paneli', 'Solarni paneli i fotonaponske ćelije', 'solar_power', 'solarni_sistemi', 10, true),
    ('solarni_invertori', 'Solarni invertori i regulatori punjenja', 'electrical_services', 'solarni_sistemi', 20, true),
    ('solarne_baterije', 'Solarne baterije i sistemi za skladištenje', 'battery_charging_full', 'solarni_sistemi', 30, true),
    ('solarni_kolektori', 'Solarni kolektori za sanitarnu toplu vodu', 'water_heater', 'solarni_sistemi', 40, true)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order,
    is_condition_applicable = true;

-- B) Toplotne pumpe (pod Grejanje, peći i klimatizacija)
INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order, is_condition_applicable)
VALUES
    ('toplotne_pumpe', 'Toplotne pumpe (vazduh-voda, voda-voda)', 'heat_pump', 'grejanje_klima', 25, true)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order,
    is_condition_applicable = true;

-- C) Šumarstvo, ogrev i drvna mehanizacija (pod Šumarstvo i ogrev)
INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order, is_condition_applicable)
VALUES
    ('cepaci_za_drva', 'Cepači za drva (hidraulični i traktorski)', 'hardware', 'sumarstvo_ogrev', 10, true),
    ('sumska_vitla_sajle', 'Šumska vitla, sajle i šumska oprema', 'settings', 'sumarstvo_ogrev', 20, true),
    ('ogrevno_drvo_pelet', 'Ogrevno drvo, pelet i briket', 'forest', 'sumarstvo_ogrev', 30, false),
    ('strugare_brente', 'Brente, strugare i sekači drva', 'precision_manufacturing', 'sumarstvo_ogrev', 40, true)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order,
    is_condition_applicable = EXCLUDED.is_condition_applicable;

-- ----------------------------------------------------------------------------
-- 4. Razrada Nivoa 3 za novije krovne stubove
-- ----------------------------------------------------------------------------

-- A) Sve za decu i bebe (deca_bebe)
INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order, is_condition_applicable)
VALUES
    -- Kolica i nosiljke
    ('kolica_3u1_2u1', 'Kolica 3u1 i 2u1 sistem', 'child_friendly', 'decija_kolica_nosiljke', 10, true),
    ('kisobran_sportska_kolica', 'Kišobran i laka sportska kolica', 'stroller', 'decija_kolica_nosiljke', 20, true),
    ('kenguri_marame_nosiljke', 'Kengur nosiljke, marame i busteri', 'child_care', 'decija_kolica_nosiljke', 30, true),

    -- Auto-sedišta
    ('auto_sedista_0_13', 'Auto-sedišta 0–13 kg (jaje nosiljka)', 'chair', 'auto_sedista_deca', 10, true),
    ('auto_sedista_9_36', 'Auto-sedišta 9–36 kg (grupe 1, 2, 3)', 'chair', 'auto_sedista_deca', 20, true),
    ('busteri_za_decu', 'Buster sedišta i podmetači za pojas', 'chair', 'auto_sedista_deca', 30, true),

    -- Nameštaj za bebe
    ('kreveci_kolevke', 'Drveni kreveci, kolevke i ogradice', 'bed', 'namestaj_za_bebe', 10, true),
    ('prenosivi_kreveci', 'Prenosivi sklopivi kreveci za putovanja', 'bed', 'namestaj_za_bebe', 20, true),
    ('duseci_posteljina_bebe', 'Dušeci, posteljina i ogradice za krevetac', 'bed', 'namestaj_za_bebe', 30, true),

    -- Igračke za decu
    ('lego_kocke_konstruktori', 'Lego i kocke za slaganje', 'extension', 'igracke_za_decu', 10, true),
    ('autici_vozovi_staze', 'Autići, vozovi, staze i garaže', 'smart_toy', 'igracke_za_decu', 20, true),
    ('lutke_barbike_oprema', 'Lutke, barbike, bebe i kućice za lutke', 'child_care', 'igracke_za_decu', 30, true),
    ('plisane_igracke', 'Plišane igračke i figure', 'pets', 'igracke_za_decu', 40, true)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order,
    is_condition_applicable = true;

-- B) Zdravlje i lepota (zdravlje_lepota)
INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order, is_condition_applicable)
VALUES
    -- Parfemi
    ('muski_parfemi', 'Muški parfemi i toaletne vode', 'local_florist', 'parfemi_toaletne_vode', 10, true),
    ('zenski_parfemi', 'Ženski parfemi i toaletne vode', 'local_florist', 'parfemi_toaletne_vode', 20, true),
    ('unisex_parfemi_testeri', 'Unisex parfemi i dekanti/testeri', 'local_florist', 'parfemi_toaletne_vode', 30, true),

    -- Medicinska pomagala
    ('invalidska_kolica_stake', 'Invalidska kolica, štake i hodalice', 'accessible', 'medicinska_pomagala', 10, true),
    ('meraci_pritiska_inhalatori', 'Merači pritiska, inhalatori i aparati', 'healing', 'medicinska_pomagala', 20, true),
    ('ortopedska_pomagala_pojasevi', 'Ortopedski ulošci, mideri i steznici', 'health_and_safety', 'medicinska_pomagala', 30, true),

    -- Aparati za negu
    ('fenovi_prese_stajleri', 'Fenovi za kosu, prese i stajleri', 'content_cut', 'aparati_za_negu_lepota', 10, true),
    ('trimeri_masinice_za_sisanje', 'Trimeri za bradu i mašinice za šišanje', 'content_cut', 'aparati_za_negu_lepota', 20, true),
    ('epilatori_brijaci', 'Epilatori i električni brijači', 'spa', 'aparati_za_negu_lepota', 30, true)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order,
    is_condition_applicable = true;

-- C) Knjige i edukacija (knjige_edukacija)
INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order, is_condition_applicable)
VALUES
    -- Beletristika
    ('domaci_autori_klasici', 'Domaći autori i književni klasici', 'menu_book', 'beletristika_romani', 10, true),
    ('svetski_romani_bestseleri', 'Svetski romani i bestseleri', 'menu_book', 'beletristika_romani', 20, true),
    ('trileri_krimi_misterije', 'Trileri, krimi romani i misterije', 'menu_book', 'beletristika_romani', 30, true),
    ('fantastika_scifi', 'Epska fantastika i naučna fantastika', 'auto_awesome', 'beletristika_romani', 40, true),

    -- Stripovi
    ('boneli_stripovi', 'Boneli stripovi (Zagor, Dilan Dog, Mister No)', 'menu_book', 'stripovi', 10, true),
    ('alan_ford', 'Alan Ford stripovi i specijali', 'menu_book', 'stripovi', 20, true),
    ('mange_stripovi', 'Japanske mange i stripovi', 'menu_book', 'stripovi', 30, true),
    ('americki_evropski_stripovi', 'Marvel, DC, Asteriks i Talični Tom', 'menu_book', 'stripovi', 40, true)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order,
    is_condition_applicable = true;

-- D) Umetnost i rukotvorine (umetnost_rukotvorine)
INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order, is_condition_applicable)
VALUES
    -- Slike i dela
    ('ulje_na_platnu_akril', 'Ulje na platnu i akrilne slike', 'palette', 'slike_umetnicka_dela', 10, true),
    ('grafike_crtezi_akvarel', 'Grafike, crteži i akvareli', 'palette', 'slike_umetnicka_dela', 20, true),
    ('ikone_pravoslavlje', 'Pravoslavne ikone (ručni rad na drvetu)', 'palette', 'slike_umetnicka_dela', 30, true),

    -- Drvenarija
    ('etno_drvenarija', 'Etno posuđe, daske za sečenje i suveniri', 'carpenter', 'drvenarija_rezbarije', 10, true),
    ('duborez_rezbarije', 'Duborez i unikatne rezbarije', 'carpenter', 'drvenarija_rezbarije', 20, true)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order,
    is_condition_applicable = true;
