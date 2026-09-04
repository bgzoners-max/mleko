-- ============================================================================
-- Migracija: Logične podkategorije 3. nivoa za sve podkategorije oglasnika
-- ============================================================================

INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order)
VALUES
    -- ========================================================================
    -- 1. Dom, nameštaj i bašta (dom_basta)
    -- ========================================================================
    -- Podkategorija: Nameštaj za dnevnu i spavaću sobu (namestaj)
    ('garniture_fotelje', 'Garniture, trosedi i fotelje', 'chair', 'namestaj', 10),
    ('kreveti_duseci', 'Kreveti i dušeci', 'bed', 'namestaj', 20),
    ('ormari_garderoberi', 'Ormari, garderoberi i plakari', 'door_sliding', 'namestaj', 30),
    ('stolovi_stolice_dnevna', 'Stolovi i stolice za dnevnu sobu', 'table_restaurant', 'namestaj', 40),
    ('regali_komode', 'Regali, komode i TV police', 'shelves', 'namestaj', 50),

    -- Podkategorija: Kuhinje i trpezarije (kuhinje_trpezarije)
    ('kuhinjski_elementi', 'Kuhinje i kuhinjski elementi', 'countertops', 'kuhinje_trpezarije', 10),
    ('trpezarijski_stolovi_stolice', 'Trpezarijski stolovi i stolice', 'table_restaurant', 'kuhinje_trpezarije', 20),
    ('sudopere_slavine', 'Sudopere i kuhinjske slavine', 'faucet', 'kuhinje_trpezarije', 30),
    ('posudje_pribor', 'Posuđe i kuhinjski pribor', 'soup_kitchen', 'kuhinje_trpezarije', 40),

    -- Podkategorija: Bela tehnika i kućni aparati (bela_tehnika)
    ('frizideri_zamrzivaci', 'Frižideri i zamrzivači', 'kitchen', 'bela_tehnika', 10),
    ('sporeti_rerne', 'Šporeti, rerne i ugradne ploče', 'microwave', 'bela_tehnika', 20),
    ('ves_masine_susare', 'Veš mašine i sušare za veš', 'local_laundry_service', 'bela_tehnika', 30),
    ('masine_za_sudove', 'Mašine za pranje sudova', 'dishwasher', 'bela_tehnika', 40),
    ('mikrotalasne_aspiratori', 'Mikrotalasne i aspiratori', 'oven_gen', 'bela_tehnika', 50),
    ('mali_kucni_aparati', 'Mali kućni aparati (usisivači, pegle, blenderi)', 'blender', 'bela_tehnika', 60),

    -- Podkategorija: Dvorište, bašta i terase (basta_dvoriste)
    ('bastenski_namestaj', 'Baštenske garniture, stolovi i ljuljaške', 'deck', 'basta_dvoriste', 10),
    ('kosilice_trimeri', 'Kosilice, trimeri i aeratori', 'grass', 'basta_dvoriste', 20),
    ('rostilji_kotlici', 'Roštilji, pečenjare i kotlići', 'outdoor_grill', 'basta_dvoriste', 30),
    ('bazeni_oprema', 'Bazeni i oprema za bazene', 'pool', 'basta_dvoriste', 40),
    ('saksije_dekoracija', 'Saksije, žardinjere i baštenska dekoracija', 'yard', 'basta_dvoriste', 50),

    -- Podkategorija: Grejanje, peći i klimatizacija (grejanje_klima)
    ('peci_kamini_drva', 'Peći i kamini na drva i ugalj', 'fireplace', 'grejanje_klima', 10),
    ('kotlovi_pelet', 'Kotlovi i peći na pelet', 'heat_pump', 'grejanje_klima', 20),
    ('radijatori_grejanje', 'Radijatori, sušači i podno grejanje', 'radiator', 'grejanje_klima', 30),
    ('klima_uredjaji', 'Klima uređaji i ventilatori', 'mode_fan', 'grejanje_klima', 40),
    ('grejalice_radijatori', 'Električne grejalice i paneli', 'hvac', 'grejanje_klima', 50),

    -- Podkategorija: Rasveta, tepisi i dekoracija (rasveta_dekoracija)
    ('lusteri_lampe', 'Lusteri, plafonjere i zidne lampe', 'lightbulb', 'rasveta_dekoracija', 10),
    ('tepisi_staze', 'Tepisi, staze i etisoni', 'texture', 'rasveta_dekoracija', 20),
    ('zavese_posteljina', 'Zavese, draperije i posteljina', 'curtains', 'rasveta_dekoracija', 30),
    ('slike_ogledala', 'Zidni satovi, slike i ogledala', 'image', 'rasveta_dekoracija', 40),

    -- ========================================================================
    -- 2. Građevinarstvo i materijali (gradjevinarstvo)
    -- ========================================================================
    -- Podkategorija: Građevinski materijali (gradjevinski_materijal)
    ('cement_pesak_sljunak', 'Cement, kreč, pesak i šljunak', 'foundation', 'gradjevinski_materijal', 10),
    ('blokovi_cigla', 'Blokovi, cigla i siporeks', 'square', 'gradjevinski_materijal', 20),
    ('armatura_gvozde', 'Armaturne mreže i gvožđe', 'reorder', 'gradjevinski_materijal', 30),
    ('gips_karton', 'Gips-karton ploče i profili', 'view_quilt', 'gradjevinski_materijal', 40),
    ('drvena_gradja', 'Drvena građa, grede i daske', 'forest', 'gradjevinski_materijal', 50),

    -- Podkategorija: Krovni pokrivači i limarija (krovni_pokrivaci)
    ('crep', 'Crep i betonski pokrivači', 'roofing', 'krovni_pokrivaci', 10),
    ('krovni_lim_paneli', 'Krovni lim i sendvič paneli', 'view_agenda', 'krovni_pokrivaci', 20),
    ('tegola_bitumen', 'Tegola i bitumen', 'layers', 'krovni_pokrivaci', 30),
    ('oluci_limarija', 'Oluci, snegobrani i limarija', 'water', 'krovni_pokrivaci', 40),

    -- Podkategorija: Stolarija (stolarija)
    ('pvc_stolarija', 'PVC prozori i vrata', 'door_front', 'stolarija', 10),
    ('alu_stolarija', 'ALU prozori i vrata', 'sensor_window', 'stolarija', 20),
    ('sobna_vrata', 'Sobna i unutrašnja vrata', 'meeting_room', 'stolarija', 30),
    ('ulazna_sigurnosna_vrata', 'Sigurnosna i ulazna vrata', 'lock', 'stolarija', 40),
    ('roletne_komarnici', 'Roletne, komarnici i venecijaneri', 'blinds', 'stolarija', 50),

    -- Podkategorija: Izolacija i fasade (izolacija_fasade)
    ('stiropor_stirodur', 'Stiropor i stirodur', 'layers', 'izolacija_fasade', 10),
    ('mineralna_vuna', 'Kamena i mineralna vuna', 'wb_shade', 'izolacija_fasade', 20),
    ('fasade_malteri', 'Fasadni malteri, lepkovi i mrežice', 'format_paint', 'izolacija_fasade', 30),
    ('hidroizolacija_folije', 'Hidroizolacija i paropropusne folije', 'water_damage', 'izolacija_fasade', 40),

    -- Podkategorija: Vodovod, kanalizacija i sanitarije (vodovod_sanitarije)
    ('cevi_fitingzi', 'Vodovodne i kanalizacione cevi i fitingzi', 'plumbing', 'vodovod_sanitarije', 10),
    ('keramicke_plocice', 'Keramičke pločice i lepak', 'grid_view', 'vodovod_sanitarije', 20),
    ('sanitarna_keramika', 'Sanitarije (WC šolje, lavaboi)', 'clean_hands', 'vodovod_sanitarije', 30),
    ('slavine_tus_kabine', 'Baterije, slavine i tuš kabine', 'shower', 'vodovod_sanitarije', 40),
    ('bojleri', 'Bojleri', 'water_heater', 'vodovod_sanitarije', 50),

    -- Podkategorija: Elektroinstalacije (elektroinstalacije)
    ('kablovi_buziri', 'Instalacioni kablovi i bužiri', 'cable', 'elektroinstalacije', 10),
    ('table_osiguraci', 'Razvodne table i automatski osigurači', 'power', 'elektroinstalacije', 20),
    ('prekidaci_uticnice', 'Prekidači, utičnice i produžni kablovi', 'outlet', 'elektroinstalacije', 30),
    ('industrijska_rasveta', 'Industrijska i fasadna rasveta', 'highlight', 'elektroinstalacije', 40),

    -- Podkategorija: Montažni objekti, ograde i kapije (montazni_objekti)
    ('montazni_kontejneri', 'Montažni kontejneri i kućice', 'home_work', 'montazni_objekti', 10),
    ('panelne_ograde_zica', 'Panelne ograde i pletena žica', 'fence', 'montazni_objekti', 20),
    ('kovano_gvozdje_kapije', 'Kovano gvožđe i metalne kapije', 'door_sliding', 'montazni_objekti', 30),
    ('nadstresnice_tende', 'Nadstrešnice i tende', 'roofing', 'montazni_objekti', 40),

    -- ========================================================================
    -- 3. Kućni ljubimci i domaće životinje (ljubimci)
    -- ========================================================================
    -- Podkategorija: Psi i štenci (psi)
    ('lovacki_psi', 'Lovački psi', 'pets', 'psi', 10),
    ('cuvari_ovcari', 'Čuvari, ovčari i šarplaninci', 'pets', 'psi', 20),
    ('mali_kucni_psi', 'Mali i patuljasti psi', 'pets', 'psi', 30),
    ('terijeri_gonici', 'Terijeri i goniči', 'pets', 'psi', 40),
    ('udomljavanje_pasa', 'Udomljavanje i mešanci', 'volunteer_activism', 'psi', 50),

    -- Podkategorija: Mačke i mačići (macke)
    ('rasne_macke', 'Rasne mačke', 'pets', 'macke', 10),
    ('domace_macke', 'Domaće mačke i udomljavanje', 'pets', 'macke', 20),

    -- Podkategorija: Domaće životinje i stoka (domace_zivotinje)
    ('krave_telad', 'Krave, junad i telad', 'pets', 'domace_zivotinje', 10),
    ('ovce_jagnjad', 'Ovce, jagnjad i ovnovi', 'pets', 'domace_zivotinje', 20),
    ('koze_jarici', 'Koze i jarići', 'pets', 'domace_zivotinje', 30),
    ('svinje_prasad', 'Svinje, prasad i tovljenici', 'pets', 'domace_zivotinje', 40),
    ('konji_magarci', 'Konji i magarci', 'pets', 'domace_zivotinje', 50),

    -- Podkategorija: Živina i ptice (zivina_ptice)
    ('kokoske_pilici', 'Kokoške, pilići i petlovi', 'egg', 'zivina_ptice', 10),
    ('curke', 'Ćurke i ćurići', 'egg', 'zivina_ptice', 20),
    ('patke_guske', 'Patke, guske i morke', 'egg', 'zivina_ptice', 30),
    ('papagaji_ptice', 'Papagaji i kanarinci', 'cruelty_free', 'zivina_ptice', 40),
    ('golubovi', 'Golubovi', 'cruelty_free', 'zivina_ptice', 50),

    -- Podkategorija: Pčelarstvo (pcelarstvo)
    ('pcelinja_drustva_matice', 'Pčelinja društva, rojevi i matice', 'hive', 'pcelarstvo', 10),
    ('kosnice_ramovi', 'Košnice i ramovi', 'view_module', 'pcelarstvo', 20),
    ('vrcajke_za_med', 'Vrcajke (centrifuge) za med', 'cyclone', 'pcelarstvo', 30),
    ('pcelarski_pribor', 'Pčelarska odela, dimilice i pribor', 'shield', 'pcelarstvo', 40),

    -- Podkategorija: Hrana i oprema za životinje (oprema_za_zivotinje)
    ('hrana_psi_macke', 'Hrana za pse i mačke (granule, konzerve)', 'shopping_bag', 'oprema_za_zivotinje', 10),
    ('koncentrati_premiksi', 'Koncentrati i premiksi za stoku', 'inventory_2', 'oprema_za_zivotinje', 20),
    ('boksevi_kucice_kavezi', 'Kavezi, boksevi i kućice', 'home', 'oprema_za_zivotinje', 30),
    ('hranilice_pojilice_muzilice', 'Pojilice, hranilice i muzilice', 'water_drop', 'oprema_za_zivotinje', 40),

    -- ========================================================================
    -- 4. Mašine, alati i zanatstvo (masine_alati)
    -- ========================================================================
    -- Podkategorija: Električni i aku alati (elektro_aku_alati)
    ('busilice_stemarice', 'Bušilice i štemarice', 'handyman', 'elektro_aku_alati', 10),
    ('brusilice', 'Ugaone i vibracione brusilice', 'hardware', 'elektro_aku_alati', 20),
    ('aku_odvijaci', 'Aku bušilice i odvijači', 'handyman', 'elektro_aku_alati', 30),
    ('testere_elektricne', 'Ubodne, kružne i motorne testere', 'carpenter', 'elektro_aku_alati', 40),
    ('rende_glodalice', 'Rende i glodalice za drvo', 'carpenter', 'elektro_aku_alati', 50),

    -- Podkategorija: Ručni alati i setovi (rucni_alati)
    ('gedore_setovi', 'Gedore i setovi nasadnih ključeva', 'build', 'rucni_alati', 10),
    ('kljucevi_rucni', 'Viljuškasto-okasti i univerzalni ključevi', 'build', 'rucni_alati', 20),
    ('klesta_stege', 'Klešta, sečice i stolarske stege', 'build', 'rucni_alati', 30),
    ('cekici_sekire', 'Čekići, sekire i poluge', 'construction', 'rucni_alati', 40),
    ('libele_merni_alati', 'Libele, metri i laseri', 'straighten', 'rucni_alati', 50),

    -- Podkategorija: Radioničke mašine i strugovi (radionicke_masine)
    ('strugovi', 'Strugovi za metal i drvo', 'precision_manufacturing', 'radionicke_masine', 10),
    ('stubne_busilice', 'Stubne i stone bušilice', 'hardware', 'radionicke_masine', 20),
    ('prese_dizalice', 'Hidraulične prese i dizalice', 'vertical_align_top', 'radionicke_masine', 30),
    ('cirkulari_brente', 'Cirkulari i brente za sečenje drveta', 'carpenter', 'radionicke_masine', 40),

    -- Podkategorija: Aparati za varenje i lemljenje (zavarivanje)
    ('inverteri_varenje', 'Invertorski aparati za varenje', 'hardware', 'zavarivanje', 10),
    ('co2_mig_mag', 'CO2 i MIG/MAG aparati', 'hardware', 'zavarivanje', 20),
    ('boce_manometri', 'Boce za gas i manometri', 'propane_tank', 'zavarivanje', 30),
    ('maske_zica_elektrode', 'Maske za varenje, žica i elektrode', 'shield', 'zavarivanje', 40),

    -- Podkategorija: Kompresori i pneumatski alati (kompresori_pneumatika)
    ('kompresori', 'Klipni i bešumni kompresori', 'air', 'kompresori_pneumatika', 10),
    ('pneumatski_odvijaci', 'Pneumatski pištolji za odvijanje', 'handyman', 'kompresori_pneumatika', 20),
    ('pistolji_farbanje', 'Pištolji za farbanje i peskarenje', 'format_paint', 'kompresori_pneumatika', 30),
    ('pneumatska_creva', 'Pneumatska creva i priključci', 'cable', 'kompresori_pneumatika', 40),

    -- Podkategorija: Zaštitna i radna oprema (zastitna_oprema)
    ('radna_obuca', 'Radne cipele i čizme sa čelikom', 'hiking', 'zastitna_oprema', 10),
    ('radna_odela', 'Radna odela, kombinezoni i prsluci', 'checkroom', 'zastitna_oprema', 20),
    ('zastita_glave_ociju', 'Zaštitne naočare, antifoni i šlemovi', 'safety_divider', 'zastitna_oprema', 30),
    ('radne_rukavice', 'Radne rukavice', 'clean_hands', 'zastitna_oprema', 40),

    -- ========================================================================
    -- 5. Mobilni telefoni i oprema (telefoni)
    -- ========================================================================
    -- Podkategorija: Mobilni telefoni (smartfoni)
    ('iphone', 'Apple iPhone', 'smartphone', 'smartfoni', 10),
    ('samsung', 'Samsung Galaxy', 'smartphone', 'smartfoni', 20),
    ('xiaomi', 'Xiaomi i Redmi', 'smartphone', 'smartfoni', 30),
    ('honor_huawei', 'Honor i Huawei', 'smartphone', 'smartfoni', 40),
    ('ostali_smartfoni', 'Motorola, Google Pixel i ostali', 'smartphone', 'smartfoni', 50),

    -- Podkategorija: Maske, futrole i zaštitna stakla (maske_futrole)
    ('maske_za_telefone', 'Silikonske i preklopne maske', 'screen_lock_portrait', 'maske_futrole', 10),
    ('zastitna_stakla', 'Zaštitna kaljena stakla i folije', 'shield', 'maske_futrole', 20),

    -- Podkategorija: Punjači, kablovi i powerbank (punjaci_baterije)
    ('kucni_punjaci_kablovi', 'Brzi kućni punjači i kablovi (Type-C, Lightning)', 'battery_charging_full', 'punjaci_baterije', 10),
    ('auto_punjaci_drzaci', 'Auto punjači i držači za telefon', 'directions_car', 'punjaci_baterije', 20),
    ('powerbank_baterije', 'Powerbank eksterne baterije', 'battery_full', 'punjaci_baterije', 30),

    -- Podkategorija: Slušalice i prenosivi zvučnici (slusalice_audio)
    ('bluetooth_slusalice', 'Bežične Bluetooth slušalice (TWS)', 'headphones', 'slusalice_audio', 10),
    ('zicne_slusalice', 'Klasične žične slušalice', 'headset', 'slusalice_audio', 20),
    ('bluetooth_zvucnici', 'Bluetooth bežični zvučnici', 'speaker', 'slusalice_audio', 30),

    -- Podkategorija: Pametni satovi i fitnes narukvice (pametni_satovi)
    ('apple_watch', 'Apple Watch', 'watch', 'pametni_satovi', 10),
    ('samsung_watch', 'Samsung Galaxy Watch', 'watch', 'pametni_satovi', 20),
    ('huawei_xiaomi_watch', 'Huawei i Xiaomi pametni satovi', 'watch', 'pametni_satovi', 30),
    ('kaisevi_za_satove', 'Narukvice i kaiševi za pametne satove', 'watch', 'pametni_satovi', 40),

    -- Podkategorija: Rezervni delovi za telefone (delovi_telefoni)
    ('ekrani_displeji', 'Ekrani i displeji', 'screenshot', 'delovi_telefoni', 10),
    ('baterije_telefoni', 'Baterije za telefone', 'battery_charging_full', 'delovi_telefoni', 20),
    ('konektori_fletovi', 'Kamere, flet kablovi i konektori', 'memory', 'delovi_telefoni', 30),

    -- ========================================================================
    -- 6. Nekretnine (nekretnine)
    -- ========================================================================
    -- Podkategorija: Stanovi (stanovi)
    ('prodaja_stanova', 'Prodaja stanova', 'apartment', 'stanovi', 10),
    ('izdavanje_stanova', 'Izdavanje stanova', 'apartment', 'stanovi', 20),
    ('stan_na_dan', 'Stan na dan i kratkoročni najam', 'hotel', 'stanovi', 30),

    -- Podkategorija: Kuće i seoska domaćinstva (kuce_domacinstva)
    ('prodaja_kuca', 'Kuće na prodaju', 'house', 'kuce_domacinstva', 10),
    ('seoska_domacinstva', 'Seoska domaćinstva, salaši i imanja', 'holiday_village', 'kuce_domacinstva', 20),
    ('izdavanje_kuca', 'Izdavanje kuća', 'house', 'kuce_domacinstva', 30),

    -- Podkategorija: Vikendice i brvnare (vikendice)
    ('planinske_vikendice', 'Planinske vikendice', 'cabin', 'vikendice', 10),
    ('vikendice_reka_jezero', 'Vikendice pored reka i jezera', 'water', 'vikendice', 20),
    ('brvnare_eko_kuce', 'Brvnare i eko-kućice', 'forest', 'vikendice', 30),

    -- Podkategorija: Poljoprivredno zemljište (poljoprivredno_zemljiste)
    ('njive_oranice', 'Njive i oranice', 'terrain', 'poljoprivredno_zemljiste', 10),
    ('vocnjaci_vinogradi', 'Voćnjaci i vinogradi', 'yard', 'poljoprivredno_zemljiste', 20),
    ('sume_pasnjaci', 'Šume i pašnjaci', 'forest', 'poljoprivredno_zemljiste', 30),

    -- Podkategorija: Građevinski placevi (gradjevinski_placevi)
    ('placevi_za_kuce', 'Placevi za porodične kuće', 'landscape', 'gradjevinski_placevi', 10),
    ('industrijski_placevi', 'Industrijske i privredne zone', 'factory', 'gradjevinski_placevi', 20),

    -- Podkategorija: Poslovni prostori, hale i lokali (poslovni_prostori)
    ('lokali', 'Lokali i prodajni prostori', 'storefront', 'poslovni_prostori', 10),
    ('kancelarije', 'Kancelarijski prostori', 'business', 'poslovni_prostori', 20),
    ('magacini_hale', 'Magacini, skladišta i industrijske hale', 'warehouse', 'poslovni_prostori', 30),

    -- Podkategorija: Garaže i parking mesta (garaze_parking)
    ('prodaja_garaza', 'Prodaja garaža i parking mesta', 'garage', 'garaze_parking', 10),
    ('izdavanje_garaza', 'Izdavanje garaža', 'garage', 'garaze_parking', 20),

    -- ========================================================================
    -- 7. Odeća, obuća i aksesoari (odeca_obuca)
    -- ========================================================================
    -- Podkategorija: Muška odeća (muska_odeca)
    ('muske_jakne_kaputi', 'Zimske jakne, kaputi i prsluci', 'checkroom', 'muska_odeca', 10),
    ('muske_pantalone', 'Farmerke i pantalone', 'checkroom', 'muska_odeca', 20),
    ('muski_duksevi_trenerke', 'Duksevi, džemperi i trenerke', 'checkroom', 'muska_odeca', 30),
    ('muske_majice_kosulje', 'Košulje i majice', 'checkroom', 'muska_odeca', 40),
    ('muska_odela', 'Odela i sakoi', 'checkroom', 'muska_odeca', 50),

    -- Podkategorija: Ženska odeća (zenska_odeca)
    ('zenske_jakne_kaputi', 'Bunde, kaputi i zimske jakne', 'checkroom', 'zenska_odeca', 10),
    ('haljine_suknje', 'Haljine i suknje', 'checkroom', 'zenska_odeca', 20),
    ('zenske_bluze_majice', 'Bluze, košulje i majice', 'checkroom', 'zenska_odeca', 30),
    ('zenske_pantalone', 'Pantalone i farmerke', 'checkroom', 'zenska_odeca', 40),
    ('zenski_dzemperi', 'Džemperi i kardigani', 'checkroom', 'zenska_odeca', 50),

    -- Podkategorija: Muška i ženska obuća (obuca)
    ('muske_patike', 'Muške patike', 'hiking', 'obuca', 10),
    ('zenske_patike', 'Ženske patike', 'hiking', 'obuca', 20),
    ('cizme_gojzerice', 'Čizme, gležnjače i gojzerice', 'hiking', 'obuca', 30),
    ('svecane_cipele', 'Cipele za odelo i svečane prilike', 'hiking', 'obuca', 40),
    ('papuce_sandale', 'Papuče i sandale', 'hiking', 'obuca', 50),

    -- Podkategorija: Dečija odeća i obuća (decija_garderoba)
    ('odeca_za_bebe', 'Odeća za bebe', 'child_care', 'decija_garderoba', 10),
    ('odeca_devojcice', 'Odeća za devojčice', 'child_care', 'decija_garderoba', 20),
    ('odeca_decaci', 'Odeća za dečake', 'child_care', 'decija_garderoba', 30),
    ('decija_obuca', 'Dečija obuća i patike', 'hiking', 'decija_garderoba', 40),

    -- Podkategorija: Torbe, rančevi i novčanici (torbe_rancevi)
    ('zenske_tasne', 'Ženske tašne i torbe', 'backpack', 'torbe_rancevi', 10),
    ('rancevi', 'Rančevi za školu, sport i planinarenje', 'backpack', 'torbe_rancevi', 20),
    ('muske_torbice_novcanici', 'Muške torbice i novčanici', 'shopping_bag', 'torbe_rancevi', 30),
    ('putni_koferi', 'Putni koferi i putne torbe', 'luggage', 'torbe_rancevi', 40),

    -- Podkategorija: Nakit, ručni satovi i naočare (nakit_satovi)
    ('rucni_satovi', 'Muški i ženski ručni satovi', 'watch', 'nakit_satovi', 10),
    ('zlatni_srebrni_nakit', 'Zlatni i srebrni nakit', 'diamond', 'nakit_satovi', 20),
    ('bizuterija', 'Bižuterija', 'diamond', 'nakit_satovi', 30),
    ('naocare', 'Sunčane naočare i dioptrijski ramovi', 'visibility', 'nakit_satovi', 40),

    -- ========================================================================
    -- 8. Poljoprivreda i mehanizacija (poljoprivreda)
    -- ========================================================================
    -- Podkategorija: Traktori i kombajni (traktori_kombajni)
    ('traktori_imt_imr', 'Traktori IMT i IMR (533, 539, 542, 558...)', 'agriculture', 'traktori_kombajni', 10),
    ('traktori_belarus', 'Traktori Belarus / MTZ', 'agriculture', 'traktori_kombajni', 20),
    ('traktori_zetor_ursus', 'Traktori Zetor, Ursus i Univerzal', 'agriculture', 'traktori_kombajni', 30),
    ('traktori_zapadni', 'Traktori John Deere, Case, Fendt, New Holland', 'agriculture', 'traktori_kombajni', 40),
    ('kombajni', 'Kombajni za žito i kukuruz', 'agriculture', 'traktori_kombajni', 50),
    ('motokultivatori_freze', 'Motokultivatori, freze i kosačice', 'agriculture', 'traktori_kombajni', 60),

    -- Podkategorija: Priključne mašine (prikljucne_masine)
    ('plugovi', 'Plugovi (ravnjaci i obrtači)', 'handyman', 'prikljucne_masine', 10),
    ('tanjirace_drljace', 'Tanjirače, drljače i setvospremači', 'handyman', 'prikljucne_masine', 20),
    ('sejalice', 'Sejalice za žito i kukuruz', 'handyman', 'prikljucne_masine', 30),
    ('prskalice_atomizeri', 'Prskalice i atomizeri', 'water_drop', 'prikljucne_masine', 40),
    ('kosacice_skupljaci_sena', 'Roto kosačice i sakupljači sena', 'grass', 'prikljucne_masine', 50),
    ('balirke_prese', 'Balirke i prese za seno', 'inventory_2', 'prikljucne_masine', 60),
    ('rasipaci_djubriva', 'Rasipači mineralnog đubriva i stajnjaka', 'scatter_plot', 'prikljucne_masine', 70),
    ('beraci_kukuruza', 'Berači kukuruza i vadilice krompira', 'agriculture', 'prikljucne_masine', 80),

    -- Podkategorija: Rezervni delovi za traktore i mehanizaciju (delovi_za_traktore)
    ('delovi_motora_traktori', 'Delovi motora i menjača za traktore', 'settings', 'delovi_za_traktore', 10),
    ('gume_za_traktore', 'Gume za traktore i prikolice', 'tire_repair', 'delovi_za_traktore', 20),
    ('hidraulika_traktori', 'Hidraulika, pumpe i razvodnici', 'plumbing', 'delovi_za_traktore', 30),
    ('kardani_kacenja', 'Kardani, toplingzi i kačenja', 'link', 'delovi_za_traktore', 40),
    ('delovi_kombajni_balirke', 'Delovi za kombajne, sejalice i balirke', 'build', 'delovi_za_traktore', 50),

    -- Podkategorija: Stočna hrana, seno i žitarice (stocna_hrana)
    ('balirano_seno_lucerka', 'Balirano seno, lucerka i detelina', 'grass', 'stocna_hrana', 10),
    ('balirana_slama', 'Balirana i rinfuzna slama', 'grass', 'stocna_hrana', 20),
    ('kukuruz_stocni', 'Kukuruz u zrnu i klipu', 'grain', 'stocna_hrana', 30),
    ('zitarice_stocne', 'Pšenica, ječam, ovas i tritikal', 'grain', 'stocna_hrana', 40),
    ('silaza_senaza', 'Silaža i senaža', 'grass', 'stocna_hrana', 50),
    ('mekinje_sacme', 'Stočno brašno, mekinje i sojina sačma', 'bakery_dining', 'stocna_hrana', 60),

    -- Podkategorija: Sadnice, semena i rasad (sadnice_semena)
    ('sadnice_voca', 'Sadnice voća (šljive, maline, lešnici, jabuke)', 'yard', 'sadnice_semena', 10),
    ('sadnice_vinove_loze', 'Lozni kalemovi i vinova loza', 'yard', 'sadnice_semena', 20),
    ('semenska_roba', 'Semenski kukuruz, pšenica i suncokret', 'grain', 'sadnice_semena', 30),
    ('semenski_krompir_luk', 'Semenski krompir i arpadžik', 'yard', 'sadnice_semena', 40),
    ('rasad_povrca', 'Rasad povrća (paradajz, paprika, kupus)', 'spa', 'sadnice_semena', 50),

    -- Podkategorija: Navodnjavanje i plastenici (navodnjavanje_plastenici)
    ('plastenici_folije', 'Konstrukcije za plastenike i folije', 'home', 'navodnjavanje_plastenici', 10),
    ('kap_po_kap_trake', 'Sistemi i trake kap po kap', 'water_drop', 'navodnjavanje_plastenici', 20),
    ('pumpe_za_navodnjavanje', 'Motorne i električne pumpe za vodu', 'water', 'navodnjavanje_plastenici', 30),
    ('rezervoari_ibc', 'Cisterne, burad i IBC kontejneri', 'propane_tank', 'navodnjavanje_plastenici', 40),

    -- Podkategorija: Oprema za preradu voća i pića (prerada_voca_oprema)
    ('kazani_za_rakiju', 'Kazani za rakiju (prevrtači i stabilni)', 'liquor', 'prerada_voca_oprema', 10),
    ('mlinovi_za_voce', 'Sečke i mlinovi za voće', 'precision_manufacturing', 'prerada_voca_oprema', 20),
    ('prese_za_voce', 'Prese za ceđenje grožđa i jabuka', 'hardware', 'prerada_voca_oprema', 30),
    ('burad_prohrom_drvo', 'Prohromska i drvena burad za vino i rakiju', 'liquor', 'prerada_voca_oprema', 40),
    ('flase_baloni_staklo', 'Stakleni baloni, flaše i ambalaža', 'wine_bar', 'prerada_voca_oprema', 50),

    -- ========================================================================
    -- 9. Računari i elektronika (tehnika)
    -- ========================================================================
    -- Podkategorija: Laptopovi i prenosni računari (laptopovi)
    ('poslovni_laptopovi', 'Poslovni i svakodnevni laptopovi', 'laptop', 'laptopovi', 10),
    ('gejmerski_laptopovi', 'Gejmerski laptopovi', 'laptop_chromebook', 'laptopovi', 20),
    ('macbook', 'Apple MacBook', 'laptop_mac', 'laptopovi', 30),
    ('laptop_punjaci_torbe', 'Punjači i torbe za laptopove', 'backpack', 'laptopovi', 40),

    -- Podkategorija: Desktop računari i komponente (desktop_komponente)
    ('kompletni_racunari', 'Kompletni desktop računari', 'computer', 'desktop_komponente', 10),
    ('graficke_karte', 'Grafičke kartice (Nvidia, AMD)', 'memory', 'desktop_komponente', 20),
    ('procesori', 'Procesori (Intel, AMD Ryzen)', 'memory', 'desktop_komponente', 30),
    ('maticne_ploce_ram', 'Matične ploče i RAM memorija', 'developer_board', 'desktop_komponente', 40),
    ('ssd_hard_diskovi', 'SSD i Hard diskovi', 'storage', 'desktop_komponente', 50),
    ('kucista_napajanja', 'Kućišta i napajanja', 'power', 'desktop_komponente', 60),

    -- Podkategorija: Monitori, tastature i miševi (monitori_periferije)
    ('monitori', 'Monitori za računar', 'monitor', 'monitori_periferije', 10),
    ('tastature_misevi', 'Tastature i miševi', 'keyboard', 'monitori_periferije', 20),
    ('stampaci_toneri', 'Laserski i inkjet štampači i toneri', 'print', 'monitori_periferije', 30),
    ('pc_zvucnici_mikrofoni', 'Zvučnici i mikrofoni za računar', 'speaker', 'monitori_periferije', 40),

    -- Podkategorija: Televizori i video oprema (televizori_video)
    ('smart_televizori', 'Smart LED i OLED televizori', 'tv', 'televizori_video', 10),
    ('nosaci_antene', 'Nosači za televizore i antene', 'tv_gen', 'televizori_video', 20),
    ('projektori_platna', 'Projektori i platna', 'videocam', 'televizori_video', 30),
    ('android_tv_box', 'Android TV Box i Apple TV', 'connected_tv', 'televizori_video', 40),

    -- Podkategorija: Konzole i igrice (konzole_igrice)
    ('playstation', 'Sony PlayStation (PS5, PS4)', 'sports_esports', 'konzole_igrice', 10),
    ('xbox', 'Microsoft Xbox', 'sports_esports', 'konzole_igrice', 20),
    ('nintendo', 'Nintendo Switch', 'sports_esports', 'konzole_igrice', 30),
    ('igrice', 'Igrice za konzole i PC', 'sports_esports', 'konzole_igrice', 40),
    ('dzojstici_kontroleri', 'Džojstici i kontroleri', 'sports_esports', 'konzole_igrice', 50),

    -- Podkategorija: Video nadzor i mrežna oprema (video_nadzor_mreze)
    ('sigurnosne_kamere_dvr', 'Sigurnosne kamere i DVR snimači', 'videocam', 'video_nadzor_mreze', 10),
    ('ruteri_svicevi', 'Wi-Fi ruteri, svičevi i ripiteri', 'router', 'video_nadzor_mreze', 20),
    ('solarni_video_nadzor', 'Solarni video nadzor za imanja i voćnjake', 'solar_power', 'video_nadzor_mreze', 30),

    -- ========================================================================
    -- 10. Sport, lov, ribolov i hobi (sport_hobi)
    -- ========================================================================
    -- Podkategorija: Lov i lovačka oprema (lov_oprema)
    ('lovacka_optika', 'Lovačka optika, nišani i dvogledi', 'visibility', 'lov_oprema', 10),
    ('lovacka_garderoba', 'Lovačka odeća, obuća i prsluci', 'checkroom', 'lov_oprema', 20),
    ('futrole_lovacki_nozevi', 'Futrole, redenici i lovački noževi', 'hardware', 'lov_oprema', 30),
    ('oprema_za_lovacke_pse', 'GPS ogrlice i oprema za lovačke pse', 'pets', 'lov_oprema', 40),
    ('ceke_vabilice', 'Čeke i vabilice za divljač', 'forest', 'lov_oprema', 50),

    -- Podkategorija: Ribolov i pecanje (ribolov_pecanje)
    ('stapovi_za_pecanje', 'Štapovi za pecanje (feeder, varaličarski, šaranski)', 'phishing', 'ribolov_pecanje', 10),
    ('masinice_za_pecanje', 'Mašinice za pecanje', 'phishing', 'ribolov_pecanje', 20),
    ('varalice_udice', 'Varalice, plovci, olova i udice', 'phishing', 'ribolov_pecanje', 30),
    ('signalizatori_mreze', 'Rod podovi, signalizatori i mreže', 'phishing', 'ribolov_pecanje', 40),
    ('kampovanje_ribolov', 'Šatori, stolice i kreveti za ribolov', 'cabin', 'ribolov_pecanje', 50),

    -- Podkategorija: Bicikli i oprema za bicikle (bicikli_oprema)
    ('mtb_bicikli', 'Mountain bike (MTB) bicikli', 'pedal_bike', 'bicikli_oprema', 10),
    ('drumski_gradski_bicikli', 'Drumski i gradski bicikli', 'pedal_bike', 'bicikli_oprema', 20),
    ('elektricni_bicikli_trotineti', 'Električni bicikli i trotineti', 'electric_bike', 'bicikli_oprema', 30),
    ('deciji_bicikli', 'Dečiji bicikli', 'pedal_bike', 'bicikli_oprema', 40),
    ('delovi_oprema_bicikli', 'Delovi, kacige, svetla i gume za bicikle', 'build', 'bicikli_oprema', 50),

    -- Podkategorija: Fitnes i sprave za vežbanje (fitnes_treninzi)
    ('tegovi_sipke', 'Tegovi, bučice i šipke', 'fitness_center', 'fitnes_treninzi', 10),
    ('klupe_za_vezbanje', 'Klupe za vežbanje i sprave', 'fitness_center', 'fitnes_treninzi', 20),
    ('trake_sobni_bicikli', 'Trake za trčanje i sobni bicikli', 'fitness_center', 'fitnes_treninzi', 30),
    ('boks_oprema', 'Vreće i rukavice za boks', 'sports_mma', 'fitnes_treninzi', 40),

    -- Podkategorija: Muzički instrumenti (muzicki_instrumenti)
    ('harmonike', 'Harmonike (klavirske i dugmetare)', 'music_note', 'muzicki_instrumenti', 10),
    ('gitare', 'Akustične, električne i bas gitare', 'music_note', 'muzicki_instrumenti', 20),
    ('klavijature', 'Klavijature, sintisajzeri i klaviri', 'piano', 'muzicki_instrumenti', 30),
    ('bubnjevi', 'Bubnjevi i perkusije', 'music_note', 'muzicki_instrumenti', 40),
    ('ozvucenje_miksete', 'Ozvučenje, miksete, zvučnici i mikrofoni', 'speaker', 'muzicki_instrumenti', 50),

    -- Podkategorija: Kolekcionarstvo i antikviteti (kolekcionarstvo)
    ('numizmatika', 'Numizmatika (stari novac i kovanice)', 'paid', 'kolekcionarstvo', 10),
    ('militarija_ordenje', 'Militarija, ordenje i sablje', 'shield', 'kolekcionarstvo', 20),
    ('antikviteti_predmeti', 'Antikvitetni nameštaj, satovi i posuđe', 'auto_awesome', 'kolekcionarstvo', 30),
    ('stripovi_ploce_knjige', 'Stripovi, gramofonske ploče i stare knjige', 'menu_book', 'kolekcionarstvo', 40),

    -- ========================================================================
    -- 11. Usluge i poslovi (usluge)
    -- ========================================================================
    -- Podkategorija: Poljoprivredne i terenske usluge (poljoprivredne_usluge)
    ('oranje_setva', 'Oranje, tanjiranje, freziranje i setva', 'agriculture', 'poljoprivredne_usluge', 10),
    ('zetva_kombajniranje', 'Žetva, kombajniranje i berba', 'agriculture', 'poljoprivredne_usluge', 20),
    ('baliranje_usluge', 'Baliranje sena i slame', 'inventory_2', 'poljoprivredne_usluge', 30),
    ('orezivanje_prskanje_voca', 'Orezivanje i prskanje voćnjaka', 'yard', 'poljoprivredne_usluge', 40),
    ('seca_cepanje_drva', 'Seča i mašinsko cepanje drva', 'forest', 'poljoprivredne_usluge', 50),

    -- Podkategorija: Majstorske i zanatske usluge (majstori_zanatlije)
    ('vodoinstalaterske_usluge', 'Vodoinstalateri i odgušenje kanalizacije', 'plumbing', 'majstori_zanatlije', 10),
    ('elektricarske_usluge', 'Električari i elektroinstalacije', 'electrical_services', 'majstori_zanatlije', 20),
    ('molerski_gipsarski_radovi', 'Molerski i gipsarski radovi', 'format_paint', 'majstori_zanatlije', 30),
    ('keramicari_plocice', 'Keramičari i postavljanje pločica', 'grid_view', 'majstori_zanatlije', 40),
    ('bravarske_usluge', 'Bravari, varioci i izrada kapija', 'hardware', 'majstori_zanatlije', 50),

    -- Podkategorija: Građevinski radovi i iskop (gradjevinske_usluge)
    ('iskopi_bageri', 'Mašinski iskop bagerima i ravnanje terena', 'construction', 'gradjevinske_usluge', 10),
    ('zidanje_betoniranje', 'Zidanje, betoniranje i šalovanje', 'foundation', 'gradjevinske_usluge', 20),
    ('krovopokrivacki_radovi', 'Krovopokrivački i limarski radovi', 'roofing', 'gradjevinske_usluge', 30),
    ('asfaltiranje_behaton', 'Asfaltiranje i popločavanje behatonom', 'view_quilt', 'gradjevinske_usluge', 40),
    ('rusenje_odvoz_suta', 'Rušenje objekata i odvoz šuta', 'delete', 'gradjevinske_usluge', 50),

    -- Podkategorija: Prevoz tereta, selidbe i šlep služba (prevoz_selidbe)
    ('kombi_prevoz', 'Kombi prevoz robe i nameštaja', 'local_shipping', 'prevoz_selidbe', 10),
    ('kamionski_prevoz', 'Kamionski prevoz rasutog tereta i drva', 'local_shipping', 'prevoz_selidbe', 20),
    ('slep_sluzba', 'Šlep služba i prevoz automobila/traktora', 'car_repair', 'prevoz_selidbe', 30),
    ('selidbe_usluge', 'Kompletne selidbe sa radnicima', 'transfer_within_a_station', 'prevoz_selidbe', 40),

    -- Podkategorija: Servis mehanizacije i vozila (servis_mehanike)
    ('servis_traktora', 'Servis i popravka traktora i mehanizacije', 'agriculture', 'servis_mehanike', 10),
    ('automehanicari', 'Automehaničari i auto-dijagnostika', 'car_repair', 'servis_mehanike', 20),
    ('autolimari_farbari', 'Autolimari i farbanje vozila', 'format_paint', 'servis_mehanike', 30),
    ('vulkanizerske_usluge', 'Vulkanizerske usluge i montiranje guma', 'tire_repair', 'servis_mehanike', 40),

    -- Podkategorija: Poslovi i ponuda zaposlenja (poslovi_zaposlenje)
    ('sezonski_poslovi', 'Sezonski poslovi na poljoprivredi i voćnjacima', 'agriculture', 'poslovi_zaposlenje', 10),
    ('poslovi_gradjevina', 'Građevinski i majstorski poslovi', 'construction', 'poslovi_zaposlenje', 20),
    ('poslovi_vozaci', 'Vozači, dostavljači i kuriri', 'local_shipping', 'poslovi_zaposlenje', 30),
    ('poslovi_ugostiteljstvo', 'Ugostiteljstvo i trgovina', 'storefront', 'poslovi_zaposlenje', 40),

    -- ========================================================================
    -- 12. Vozila i auto-moto (vozila)
    -- ========================================================================
    -- Podkategorija: Automobili (automobili)
    ('automobili_nemacki', 'Nemački automobili (VW, Audi, BMW, Mercedes, Opel)', 'directions_car', 'automobili', 10),
    ('automobili_francuski', 'Francuski automobili (Renault, Peugeot, Citroen)', 'directions_car', 'automobili', 20),
    ('automobili_italijanski', 'Italijanski automobili (Fiat, Alfa Romeo)', 'directions_car', 'automobili', 30),
    ('automobili_azijski', 'Azijski automobili (Toyota, Hyundai, Kia, Nissan)', 'directions_car', 'automobili', 40),
    ('dzipovi_suv', 'Džipovi, terenci i SUV vozila', 'directions_car', 'automobili', 50),
    ('oldtajmeri_havarisani', 'Oldtajmeri i havarisana vozila', 'car_repair', 'automobili', 60),

    -- Podkategorija: Auto delovi i oprema (auto_delovi)
    ('motori_menjaci', 'Motori, menjači i delovi mehanike', 'settings', 'auto_delovi', 10),
    ('karoserija_limarija', 'Karoserija, vrata, krila i branici', 'directions_car', 'auto_delovi', 20),
    ('farovi_stop_svetla', 'Svetlosna grupa, farovi i stop svetla', 'highlight', 'auto_delovi', 30),
    ('auto_gume_felne', 'Auto gume i aluminijumske felne', 'tire_repair', 'auto_delovi', 40),
    ('kocnice_vesanje', 'Kočioni sistemi, amortizeri i vešanje', 'build', 'auto_delovi', 50),
    ('auto_multimedija', 'Auto akustika, navigacija i multimedija', 'speaker', 'auto_delovi', 60),

    -- Podkategorija: Dostavna i teretna vozila (teretna_vozila)
    ('kombiji', 'Teretni i putnički kombiji', 'airport_shuttle', 'teretna_vozila', 10),
    ('kamioni', 'Kamioni do 7.5t i preko 7.5t', 'local_shipping', 'teretna_vozila', 20),
    ('kiperi_sanducari', 'Kiperi i sandučari', 'local_shipping', 'teretna_vozila', 30),
    ('sleperi', 'Šleperi i tegljači', 'local_shipping', 'teretna_vozila', 40),

    -- Podkategorija: Prikolice (prikolice)
    ('traktorske_prikolice', 'Traktorske kiper prikolice i špediteri', 'rv_hookup', 'prikolice', 10),
    ('prikolice_za_stoku', 'Prikolice za prevoz stoke', 'rv_hookup', 'prikolice', 20),
    ('auto_prikolice', 'Auto prikolice do 750kg i preko 750kg', 'rv_hookup', 'prikolice', 30),
    ('slep_prikolice', 'Prikolice za prevoz automobila (šlep prikolice)', 'rv_hookup', 'prikolice', 40),

    -- Podkategorija: Motocikli, skuteri i kvadovi (motocikli_atv)
    ('skuteri', 'Skuteri do 50cc i preko 50cc', 'two_wheeler', 'motocikli_atv', 10),
    ('kros_enduro', 'Kros i enduro motori', 'two_wheeler', 'motocikli_atv', 20),
    ('kvadovi_atv', 'Kvadovi i ATV / UTV terenska vozila', 'two_wheeler', 'motocikli_atv', 30),
    ('coperi_kruzeri', 'Čoperi, kruzeri i turing motori', 'two_wheeler', 'motocikli_atv', 40),
    ('moto_oprema', 'Kacige, jakne i moto oprema', 'shield', 'motocikli_atv', 50),

    -- Podkategorija: Plovila i čamci (plovila_camci)
    ('camci_reka_jezero', 'Metalni i plastični čamci za reke i jezera', 'sailing', 'plovila_camci', 10),
    ('gumeni_camci', 'Gumeni čamci', 'sailing', 'plovila_camci', 20),
    ('vanbrodski_motori', 'Vanbrodski motori (Tomos, Yamaha, Honda...)', 'build', 'plovila_camci', 30),
    ('oprema_za_camce', 'Oprema za plovila (prsluci, sidra, prikolice)', 'anchor', 'plovila_camci', 40)
ON CONFLICT (id) DO UPDATE
SET
    name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order;
