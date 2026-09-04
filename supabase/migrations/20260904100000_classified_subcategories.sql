-- ============================================================================
-- Migracija: Kompletne smislene podkategorije za svih 12 kategorija oglasa
-- ============================================================================

INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order)
VALUES
    -- 1. Dom, nameštaj i bašta (dom_basta)
    ('namestaj', 'Nameštaj za dnevnu i spavaću sobu', 'chair', 'dom_basta', 10),
    ('kuhinje_trpezarije', 'Kuhinje i trpezarije', 'table_restaurant', 'dom_basta', 20),
    ('bela_tehnika', 'Bela tehnika i kućni aparati', 'kitchen', 'dom_basta', 30),
    ('basta_dvoriste', 'Dvorište, bašta i terase', 'yard', 'dom_basta', 40),
    ('grejanje_klima', 'Grejanje, peći i klimatizacija', 'fireplace', 'dom_basta', 50),
    ('rasveta_dekoracija', 'Rasveta, tepisi i dekoracija', 'lightbulb', 'dom_basta', 60),

    -- 2. Građevinarstvo i materijali (gradjevinarstvo)
    ('gradjevinski_materijal', 'Građevinski materijali', 'foundation', 'gradjevinarstvo', 10),
    ('krovni_pokrivaci', 'Krovni pokrivači i limarija', 'roofing', 'gradjevinarstvo', 20),
    ('stolarija', 'Stolarija (PVC, ALU, drvo)', 'door_front', 'gradjevinarstvo', 30),
    ('izolacija_fasade', 'Izolacija i fasade', 'layers', 'gradjevinarstvo', 40),
    ('vodovod_sanitarije', 'Vodovod, kanalizacija i sanitarije', 'plumbing', 'gradjevinarstvo', 50),
    ('elektroinstalacije', 'Elektroinstalacije', 'electrical_services', 'gradjevinarstvo', 60),
    ('montazni_objekti', 'Montažni objekti, ograde i kapije', 'fence', 'gradjevinarstvo', 70),

    -- 3. Kućni ljubimci i domaće životinje (ljubimci)
    ('psi', 'Psi i štenci', 'pets', 'ljubimci', 10),
    ('macke', 'Mačke i mačići', 'pets', 'ljubimci', 20),
    ('domace_zivotinje', 'Domaće životinje i stoka', 'pets', 'ljubimci', 30),
    ('zivina_ptice', 'Živina i ptice', 'egg', 'ljubimci', 40),
    ('pcelarstvo', 'Pčelarstvo', 'hive', 'ljubimci', 50),
    ('oprema_za_zivotinje', 'Hrana i oprema za životinje', 'shopping_bag', 'ljubimci', 60),

    -- 4. Mašine, alati i zanatstvo (masine_alati)
    ('elektro_aku_alati', 'Električni i aku alati', 'handyman', 'masine_alati', 10),
    ('rucni_alati', 'Ručni alati i setovi', 'build', 'masine_alati', 20),
    ('radionicke_masine', 'Radioničke mašine i strugovi', 'precision_manufacturing', 'masine_alati', 30),
    ('zavarivanje', 'Aparati za varenje i lemljenje', 'hardware', 'masine_alati', 40),
    ('kompresori_pneumatika', 'Kompresori i pneumatski alati', 'air', 'masine_alati', 50),
    ('zastitna_oprema', 'Zaštitna i radna oprema', 'shield', 'masine_alati', 60),

    -- 5. Mobilni telefoni i oprema (telefoni)
    ('smartfoni', 'Mobilni telefoni (Smartfoni)', 'smartphone', 'telefoni', 10),
    ('maske_futrole', 'Maske, futrole i zaštitna stakla', 'screen_lock_portrait', 'telefoni', 20),
    ('punjaci_baterije', 'Punjači, kablovi i powerbank', 'battery_charging_full', 'telefoni', 30),
    ('slusalice_audio', 'Slušalice i prenosivi zvučnici', 'headphones', 'telefoni', 40),
    ('pametni_satovi', 'Pametni satovi i fitnes narukvice', 'watch', 'telefoni', 50),
    ('delovi_telefoni', 'Rezervni delovi za telefone', 'memory', 'telefoni', 60),

    -- 6. Nekretnine (nekretnine)
    ('stanovi', 'Stanovi', 'apartment', 'nekretnine', 10),
    ('kuce_domacinstva', 'Kuće i seoska domaćinstva', 'house', 'nekretnine', 20),
    ('vikendice', 'Vikendice i brvnare', 'cabin', 'nekretnine', 30),
    ('poljoprivredno_zemljiste', 'Poljoprivredno zemljište', 'terrain', 'nekretnine', 40),
    ('gradjevinski_placevi', 'Građevinski placevi', 'landscape', 'nekretnine', 50),
    ('poslovni_prostori', 'Poslovni prostori, hale i lokali', 'storefront', 'nekretnine', 60),
    ('garaze_parking', 'Garaže i parking mesta', 'garage', 'nekretnine', 70),

    -- 7. Odeća, obuća i aksesoari (odeca_obuca)
    ('muska_odeca', 'Muška odeća', 'checkroom', 'odeca_obuca', 10),
    ('zenska_odeca', 'Ženska odeća', 'checkroom', 'odeca_obuca', 20),
    ('obuca', 'Muška i ženska obuća', 'hiking', 'odeca_obuca', 30),
    ('decija_garderoba', 'Dečija odeća i obuća', 'child_care', 'odeca_obuca', 40),
    ('torbe_rancevi', 'Torbe, rančevi i novčanici', 'backpack', 'odeca_obuca', 50),
    ('nakit_satovi', 'Nakit, ručni satovi i naočare', 'diamond', 'odeca_obuca', 60),

    -- 8. Poljoprivreda i mehanizacija (poljoprivreda)
    ('traktori_kombajni', 'Traktori i kombajni', 'agriculture', 'poljoprivreda', 10),
    ('prikljucne_masine', 'Priključne mašine', 'handyman', 'poljoprivreda', 20),
    ('delovi_za_traktore', 'Rezervni delovi za traktore i mehanizaciju', 'settings', 'poljoprivreda', 30),
    ('stocna_hrana', 'Stočna hrana, seno i žitarice', 'grass', 'poljoprivreda', 40),
    ('sadnice_semena', 'Sadnice, semena i rasad', 'yard', 'poljoprivreda', 50),
    ('navodnjavanje_plastenici', 'Navodnjavanje i plastenici', 'water_drop', 'poljoprivreda', 60),
    ('prerada_voca_oprema', 'Oprema za preradu voća i pića', 'liquor', 'poljoprivreda', 70),

    -- 9. Računari i elektronika (tehnika)
    ('laptopovi', 'Laptopovi i prenosni računari', 'laptop', 'tehnika', 10),
    ('desktop_komponente', 'Desktop računari i komponente', 'computer', 'tehnika', 20),
    ('monitori_periferije', 'Monitori, tastature i miševi', 'monitor', 'tehnika', 30),
    ('televizori_video', 'Televizori i video oprema', 'tv', 'tehnika', 40),
    ('konzole_igrice', 'Konzole i igrice', 'sports_esports', 'tehnika', 50),
    ('video_nadzor_mreze', 'Video nadzor i mrežna oprema', 'videocam', 'tehnika', 60),

    -- 10. Sport, lov, ribolov i hobi (sport_hobi)
    ('lov_oprema', 'Lov i lovačka oprema', 'forest', 'sport_hobi', 10),
    ('ribolov_pecanje', 'Ribolov i pecanje', 'phishing', 'sport_hobi', 20),
    ('bicikli_oprema', 'Bicikli i oprema za bicikle', 'pedal_bike', 'sport_hobi', 30),
    ('fitnes_treninzi', 'Fitnes i sprave za vežbanje', 'fitness_center', 'sport_hobi', 40),
    ('muzicki_instrumenti', 'Muzički instrumenti', 'music_note', 'sport_hobi', 50),
    ('kolekcionarstvo', 'Kolekcionarstvo i antikviteti', 'auto_awesome', 'sport_hobi', 60),

    -- 11. Usluge i poslovi (usluge)
    ('poljoprivredne_usluge', 'Poljoprivredne i terenske usluge', 'agriculture', 'usluge', 10),
    ('majstori_zanatlije', 'Majstorske i zanatske usluge', 'handyman', 'usluge', 20),
    ('gradjevinske_usluge', 'Građevinski radovi i iskop', 'construction', 'usluge', 30),
    ('prevoz_selidbe', 'Prevoz tereta, selidbe i šlep služba', 'local_shipping', 'usluge', 40),
    ('servis_mehanike', 'Servis mehanizacije i vozila', 'car_repair', 'usluge', 50),
    ('poslovi_zaposlenje', 'Poslovi i ponuda zaposlenja', 'work', 'usluge', 60),

    -- 12. Vozila i auto-moto (vozila)
    ('automobili', 'Automobili', 'directions_car', 'vozila', 10),
    ('auto_delovi', 'Auto delovi i oprema', 'build', 'vozila', 20),
    ('teretna_vozila', 'Dostavna i teretna vozila', 'local_shipping', 'vozila', 30),
    ('prikolice', 'Prikolice', 'rv_hookup', 'vozila', 40),
    ('motocikli_atv', 'Motocikli, skuteri i kvadovi (ATV)', 'two_wheeler', 'vozila', 50),
    ('plovila_camci', 'Plovila i čamci', 'sailing', 'vozila', 60)
ON CONFLICT (id) DO UPDATE
SET
    name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order;
