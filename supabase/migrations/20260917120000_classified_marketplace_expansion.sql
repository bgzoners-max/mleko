-- ============================================================================
-- Migracija: Veliko tržišno proširenje kategorija za Mali Oglasnik (Marketplace Benchmark)
-- Datum: 2026-09-17
-- Opis: Uvođenje 16. krovnog stuba "Sve za decu i bebe" (deca_bebe) sa podkategorijama
--       (kolica, auto-sedišta, kreveci, hranilice, igračke, edukativne/Montesori, oprema),
--       kao i ključnih tržišnih niša po uzoru na Ananas.rs i KupujemProdajem:
--       - Zdravlje i lepota: parfemi, aparati za negu, medicinska pomagala
--       - Tehnika: štampači/toneri, Wi-Fi/mrežna oprema, eksterni diskovi/USB, gejming oprema
--       - Dom i bašta: kancelarijski nameštaj, kućni tekstil, aparati za kafu, mali kuhinjski aparati (air fryer)
--       - Vozila: auto kozmetika/ulja, multimedije/kamere, krovni koferi, e-trotineti i e-bicikli
--       - Poljoprivreda: ambalaža (burad, kace, tegle, gajbe), pumpe za vodu/hidrofori
--       - Sport: vodeni sportovi/SUP, roleri/trotineti/skejt
--       - Poslovna oprema: profesionalna ugostiteljska i trgovačka oprema
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Nova 16. krovna kategorija: Sve za decu i bebe (deca_bebe)
-- ----------------------------------------------------------------------------
INSERT INTO public.classified_categories (id, name, icon_name, sort_order)
VALUES ('deca_bebe', 'Sve za decu i bebe', 'child_friendly', 95)
ON CONFLICT (id) DO UPDATE
SET name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    sort_order = EXCLUDED.sort_order;

INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order)
VALUES
    ('decija_kolica_nosiljke', 'Dečija kolica i nosiljke', 'child_friendly', 'deca_bebe', 10),
    ('auto_sedista_deca', 'Auto-sedišta za decu i busteri', 'chair', 'deca_bebe', 20),
    ('namestaj_za_bebe', 'Kreveci, kolevke i dušeci', 'bed', 'deca_bebe', 30),
    ('hranilice_stolice', 'Hranilice i dečije stolice', 'table_restaurant', 'deca_bebe', 40),
    ('igracke_za_decu', 'Igračke (kocke, autići, lutke)', 'smart_toy', 'deca_bebe', 50),
    ('edukativne_montesori_igracke', 'Edukativne i Montesori igračke', 'extension', 'deca_bebe', 60),
    ('bebi_oprema_higijena', 'Bebi alarmi, pumpice i oprema', 'child_care', 'deca_bebe', 70),
    ('hodalice_dubci_ogradice', 'Hodalice (dubak) i ogradice', 'stroller', 'deca_bebe', 80)
ON CONFLICT (id) DO UPDATE
SET name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order;

-- ----------------------------------------------------------------------------
-- 2. Dopune za: Zdravlje i lepota (zdravlje_lepota)
-- ----------------------------------------------------------------------------
INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order)
VALUES
    ('parfemi_toaletne_vode', 'Parfemi i toaletne vode', 'local_florist', 'zdravlje_lepota', 70),
    ('aparati_za_negu_lepota', 'Aparati za negu (fenovi, trimeri, epilatori)', 'content_cut', 'zdravlje_lepota', 80),
    ('medicinska_pomagala', 'Medicinski aparati i pomagala', 'healing', 'zdravlje_lepota', 90)
ON CONFLICT (id) DO UPDATE
SET name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order;

-- ----------------------------------------------------------------------------
-- 3. Dopune za: Računari i elektronika (tehnika)
-- ----------------------------------------------------------------------------
INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order)
VALUES
    ('stampaci_skeneri_toneri', 'Štampači, skeneri, toneri i mastila', 'print', 'tehnika', 90),
    ('mrezna_oprema_ruteri', 'Mrežna oprema i Wi-Fi ruteri', 'router', 'tehnika', 100),
    ('memorije_hard_diskovi', 'Eksterni hard diskovi, SSD i USB', 'storage', 'tehnika', 110),
    ('gejming_oprema', 'Gejming oprema (stolice, volani, slušalice)', 'sports_esports', 'tehnika', 120)
ON CONFLICT (id) DO UPDATE
SET name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order;

-- ----------------------------------------------------------------------------
-- 4. Dopune za: Dom, nameštaj i bašta (dom_basta)
-- ----------------------------------------------------------------------------
INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order)
VALUES
    ('kancelarijski_namestaj', 'Kancelarijski stolovi i radne stolice', 'business_center', 'dom_basta', 70),
    ('kucni_tekstil', 'Kućni tekstil (posteljine, peškiri, jastuci)', 'bed', 'dom_basta', 80),
    ('aparati_za_kafu', 'Aparati za espresso i kafu', 'coffee', 'dom_basta', 90),
    ('mali_kuhinjski_aparati', 'Mali kuhinjski aparati (friteze, blenderi)', 'blender', 'dom_basta', 100)
ON CONFLICT (id) DO UPDATE
SET name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order;

-- ----------------------------------------------------------------------------
-- 5. Dopune za: Vozila i auto-moto (vozila)
-- ----------------------------------------------------------------------------
INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order)
VALUES
    ('auto_kozmetika_tecnosti', 'Auto kozmetika, motorna ulja i tečnosti', 'water_drop', 'vozila', 80),
    ('auto_multimedija_navigacija', 'Auto multimedija, kamere i navigacija', 'connected_tv', 'vozila', 90),
    ('krovni_koferi_nosaci', 'Krovni koferi i nosači za skije/bicikle', 'luggage', 'vozila', 100),
    ('elektricni_trotineti_bicikli', 'Električni trotineti i e-bicikli', 'electric_scooter', 'vozila', 110)
ON CONFLICT (id) DO UPDATE
SET name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order;

-- ----------------------------------------------------------------------------
-- 6. Dopune za: Poljoprivreda i mehanizacija (poljoprivreda)
-- ----------------------------------------------------------------------------
INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order)
VALUES
    ('ambalaza_burad_kace', 'Burad, kace za kominu, flaše i gajbe', 'inventory_2', 'poljoprivreda', 100),
    ('pumpe_za_vodu_hidrofori', 'Pumpe za navodnjavanje i hidrofori', 'water', 'poljoprivreda', 110)
ON CONFLICT (id) DO UPDATE
SET name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order;

-- ----------------------------------------------------------------------------
-- 7. Dopune za: Sport, lov, ribolov i hobi (sport_hobi)
-- ----------------------------------------------------------------------------
INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order)
VALUES
    ('vodeni_sportovi_sup', 'Vodeni sportovi, plivanje i SUP daske', 'pool', 'sport_hobi', 180),
    ('roleri_skejtbord_trotineti', 'Roleri, dečiji trotineti i skejtbord', 'skateboarding', 'sport_hobi', 190)
ON CONFLICT (id) DO UPDATE
SET name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order;

-- ----------------------------------------------------------------------------
-- 8. Dopune za: Usluge i poslovna oprema (usluge)
-- ----------------------------------------------------------------------------
INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order, is_condition_applicable)
VALUES
    ('ugostiteljska_trgovacka_oprema', 'Ugostiteljska i trgovačka oprema', 'storefront', 'usluge', 170, false)
ON CONFLICT (id) DO UPDATE
SET name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order,
    is_condition_applicable = false;
