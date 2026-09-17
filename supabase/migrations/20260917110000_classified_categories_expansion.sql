-- ============================================================================
-- Migracija: Proširenje kategorija i podkategorija za Mali Oglasnik (Classifieds)
-- Datum: 2026-09-17
-- Opis: Dodavanje novih podkategorija (Odeća, Sport, Usluge, Teretna vozila, Prikolice,
--       Gume/felne, Motokultivatori, Foto/video/dronovi, Audio/Hi-Fi, Skijanje,
--       Stripovi, Antikviteti, Udžbenici nivo 3) i 3 nove krovne kategorije
--       (Zdravlje i lepota, Knjige i edukacija, Umetnost i rukotvorine)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Nove podkategorije za Odeća, obuća i aksesoari (odeca_obuca)
-- ----------------------------------------------------------------------------
INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order)
VALUES
    ('sportska_odeca_obuca', 'Sportska odeća i obuća', 'fitness_center', 'odeca_obuca', 70),
    ('radna_odeca_uniforme', 'Radna odeća i uniforma', 'shield', 'odeca_obuca', 80),
    ('vintage_retro_odeca', 'Vintage i retro odeća', 'auto_awesome', 'odeca_obuca', 90),
    ('narodna_nosnja', 'Tradicionalna narodna nošnja', 'checkroom', 'odeca_obuca', 100),
    ('vencanice_svecana_odeca', 'Venčanice i svečana odeća', 'diamond', 'odeca_obuca', 110),
    ('donji_ves_spavaci_program', 'Donji veš i spavaća odeća', 'bed', 'odeca_obuca', 120),
    ('zimska_odeca', 'Zimska odeća (jakne, bunde, kaputi)', 'checkroom', 'odeca_obuca', 130),
    ('letnja_odeca', 'Letnja odeća i kupaći kostimi', 'checkroom', 'odeca_obuca', 140),
    ('kape_sesiri_marame', 'Kape, šeširi i marame', 'face', 'odeca_obuca', 150),
    ('salovi_rukavice_pojasevi', 'Šalovi, rukavice i pojasevi', 'checkroom', 'odeca_obuca', 160)
ON CONFLICT (id) DO UPDATE
SET name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order;

-- ----------------------------------------------------------------------------
-- 2. Nove podkategorije za Sport, lov, ribolov i hobi (sport_hobi)
-- ----------------------------------------------------------------------------
INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order)
VALUES
    ('fudbal_oprema', 'Fudbal i mali fudbal', 'sports_soccer', 'sport_hobi', 70),
    ('kosarka_rukomet', 'Košarka i rukomet', 'sports_basketball', 'sport_hobi', 80),
    ('tenis_stoni_tenis', 'Tenis i stoni tenis', 'sports_tennis', 'sport_hobi', 90),
    ('planinarenje_kampovanje', 'Planinarenje i kampovanje', 'hiking', 'sport_hobi', 100),
    ('konjicki_sport', 'Konjički sport i oprema', 'pets', 'sport_hobi', 110),
    ('strelicarstvo_streljastvo', 'Streličarstvo i streljaštvo', 'track_changes', 'sport_hobi', 120),
    ('borilacki_sportovi', 'Borilački sportovi (boks, MMA, karate)', 'sports_mma', 'sport_hobi', 130),
    ('drustvene_igre_tabli', 'Igre na tabli i društvene igre', 'extension', 'sport_hobi', 140),
    ('umetnicki_materijali', 'Umetnički materijali i pribor', 'brush', 'sport_hobi', 150),
    ('bastovanstvo_cvece', 'Baštovanstvo i cvećarstvo', 'yard', 'sport_hobi', 160),
    ('skijanje_zimski_sportovi', 'Skijanje i zimski sportovi', 'downhill_skiing', 'sport_hobi', 170)
ON CONFLICT (id) DO UPDATE
SET name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order;

-- ----------------------------------------------------------------------------
-- 3. Nove podkategorije za Usluge i poslovi (usluge)
--    Strogo pravilo: is_condition_applicable = false za sve usluge
-- ----------------------------------------------------------------------------
INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order, is_condition_applicable)
VALUES
    ('it_usluge', 'IT usluge, web i računari', 'computer', 'usluge', 70, false),
    ('konsultantske_usluge', 'Konsultantske i pravne usluge', 'business_center', 'usluge', 80, false),
    ('edukacija_obuka', 'Edukacija, kursevi i obuka', 'school', 'usluge', 90, false),
    ('kreativne_usluge', 'Kreativne usluge, foto i video', 'videocam', 'usluge', 100, false),
    ('marketing_oglasavanje', 'Marketing i oglašavanje', 'campaign', 'usluge', 110, false),
    ('ciscenje_odrzavanje', 'Čišćenje i održavanje objekata', 'cleaning_services', 'usluge', 120, false),
    ('dogadjaji_proslave', 'Organizacija događaja i proslava', 'celebration', 'usluge', 130, false),
    ('zdravstvene_usluge', 'Zdravstvene usluge i masaža', 'healing', 'usluge', 140, false),
    ('prevodjenje_lektura', 'Prevođenje i lektura', 'translate', 'usluge', 150, false),
    ('racunovodstvo_knjigovodstvo', 'Računovodstvo i knjigovodstvo', 'receipt_long', 'usluge', 160, false)
ON CONFLICT (id) DO UPDATE
SET name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order,
    is_condition_applicable = false;

-- ----------------------------------------------------------------------------
-- 4. Nove podkategorije za Vozila i auto-moto (vozila)
-- ----------------------------------------------------------------------------
INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order)
VALUES
    ('gume_felne', 'Gume, felne i točkovi', 'tire_repair', 'vozila', 35),
    ('teretna_vozila', 'Komercijalna i teretna vozila (kombiji, kamioni)', 'local_shipping', 'vozila', 40),
    ('prikolice', 'Auto i traktorske prikolice', 'rv_hookup', 'vozila', 50),
    ('plovila_nautika', 'Čamci, motori i nautika', 'sailing', 'vozila', 60),
    ('gradjevinske_masine', 'Građevinske mašine i viljuškari', 'precision_manufacturing', 'vozila', 70)
ON CONFLICT (id) DO UPDATE
SET name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order;

-- ----------------------------------------------------------------------------
-- 5. Nove podkategorije za Poljoprivredu i mehanizaciju (poljoprivreda)
-- ----------------------------------------------------------------------------
INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order)
VALUES
    ('motokultivatori_freze', 'Motokultivatori, freze i kosačice', 'handyman', 'poljoprivreda', 25),
    ('djubriva_zastita', 'Đubriva i zaštita bilja', 'eco', 'poljoprivreda', 80),
    ('sumarstvo_ogrev', 'Šumarstvo, ogrevno drvo i pelet', 'forest', 'poljoprivreda', 90)
ON CONFLICT (id) DO UPDATE
SET name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order;

-- ----------------------------------------------------------------------------
-- 6. Nove podkategorije za Računari i elektronika (tehnika)
-- ----------------------------------------------------------------------------
INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order)
VALUES
    ('foto_kamere_optika', 'Foto-aparati, kamere i dronovi', 'camera_alt', 'tehnika', 70),
    ('audio_hifi', 'Audio, Hi-Fi i gramofoni', 'speaker', 'tehnika', 80)
ON CONFLICT (id) DO UPDATE
SET name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order;

-- ----------------------------------------------------------------------------
-- 7. Nova krovna kategorija: Zdravlje i lepota (zdravlje_lepota)
-- ----------------------------------------------------------------------------
INSERT INTO public.classified_categories (id, name, icon_name, sort_order)
VALUES ('zdravlje_lepota', 'Zdravlje i lepota', 'spa', 130)
ON CONFLICT (id) DO UPDATE
SET name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    sort_order = EXCLUDED.sort_order;

INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order)
VALUES
    ('prirodna_kozmetika_oglasi', 'Prirodna kozmetika (kreme, sapuni, ulja)', 'spa', 'zdravlje_lepota', 10),
    ('suplementi_vitamini', 'Suplementi i vitamini', 'healing', 'zdravlje_lepota', 20),
    ('biljni_preparati_cajevi', 'Čajevi i biljni preparati', 'local_florist', 'zdravlje_lepota', 30),
    ('etericna_ulja_aromaterapija', 'Eterična ulja i aromaterapija', 'water_drop', 'zdravlje_lepota', 40),
    ('fitness_suplementi', 'Fitness suplementi (proteini, kreatin)', 'fitness_center', 'zdravlje_lepota', 50),
    ('oprema_masaza_relaksacija', 'Oprema za masažu i relaksaciju', 'spa', 'zdravlje_lepota', 60)
ON CONFLICT (id) DO UPDATE
SET name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order;

-- ----------------------------------------------------------------------------
-- 8. Nova krovna kategorija: Knjige i edukacija (knjige_edukacija)
-- ----------------------------------------------------------------------------
INSERT INTO public.classified_categories (id, name, icon_name, sort_order)
VALUES ('knjige_edukacija', 'Knjige i edukacija', 'menu_book', 140)
ON CONFLICT (id) DO UPDATE
SET name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    sort_order = EXCLUDED.sort_order;

INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order)
VALUES
    ('udzbenici_skola', 'Udžbenici i školska literatura', 'school', 'knjige_edukacija', 10),
    ('beletristika_romani', 'Beletristika i romani', 'menu_book', 'knjige_edukacija', 20),
    ('strucna_literatura', 'Stručna literatura (medicina, pravo, ekonomija)', 'menu_book', 'knjige_edukacija', 30),
    ('decije_knjige', 'Dečije knjige i slikovnice', 'child_care', 'knjige_edukacija', 40),
    ('enciklopedije_recnici', 'Enciklopedije i rečnici', 'menu_book', 'knjige_edukacija', 50),
    ('audio_knjige', 'Audio knjige', 'headphones', 'knjige_edukacija', 60),
    ('eknjige_digitalno', 'E-knjige i digitalni sadržaj', 'tablet', 'knjige_edukacija', 70),
    ('stripovi', 'Stripovi i grafičke novele', 'menu_book', 'knjige_edukacija', 80)
ON CONFLICT (id) DO UPDATE
SET name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order;

-- Nivo 3: Udžbenici razvrstani po nivoima obrazovanja
INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order)
VALUES
    ('udzbenici_osnovna', 'Udžbenici za osnovnu školu', 'school', 'udzbenici_skola', 10),
    ('udzbenici_srednja', 'Udžbenici za srednju školu', 'school', 'udzbenici_skola', 20),
    ('udzbenici_fakultet', 'Fakultetska literatura i skripte', 'school', 'udzbenici_skola', 30)
ON CONFLICT (id) DO UPDATE
SET name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order;

-- ----------------------------------------------------------------------------
-- 9. Nova krovna kategorija: Umetnost i rukotvorine (umetnost_rukotvorine)
-- ----------------------------------------------------------------------------
INSERT INTO public.classified_categories (id, name, icon_name, sort_order)
VALUES ('umetnost_rukotvorine', 'Umetnost i rukotvorine', 'palette', 150)
ON CONFLICT (id) DO UPDATE
SET name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    sort_order = EXCLUDED.sort_order;

INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order)
VALUES
    ('slike_umetnicka_dela', 'Slike i umetnička dela', 'palette', 'umetnost_rukotvorine', 10),
    ('skulpture_figure', 'Skulpture i figure', 'handyman', 'umetnost_rukotvorine', 20),
    ('rucno_radjeni_nakit', 'Ručno rađeni nakit', 'diamond', 'umetnost_rukotvorine', 30),
    ('keramika_grncarija', 'Keramika i grnčarija', 'palette', 'umetnost_rukotvorine', 40),
    ('tekstil_vez', 'Tekstil i vez', 'checkroom', 'umetnost_rukotvorine', 50),
    ('drvenarija_rezbarije', 'Drvenarija i rezbarije', 'carpenter', 'umetnost_rukotvorine', 60),
    ('pleteni_heklani_proizvodi', 'Pleteni i heklani proizvodi', 'checkroom', 'umetnost_rukotvorine', 70),
    ('svece_sapuni_rucna_izrada', 'Sveće i sapuni ručne izrade', 'spa', 'umetnost_rukotvorine', 80),
    ('antikviteti', 'Antikviteti i etno predmeti', 'auto_awesome', 'umetnost_rukotvorine', 90)
ON CONFLICT (id) DO UPDATE
SET name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order;

-- ----------------------------------------------------------------------------
-- 10. Osiguranje da su sve usluge uvek bez selekcije stanja (Novo/Polovno)
-- ----------------------------------------------------------------------------
UPDATE public.classified_categories
SET is_condition_applicable = false
WHERE parent_id = 'usluge' OR id = 'usluge';
