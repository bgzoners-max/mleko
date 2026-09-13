-- ============================================================================
-- Migracija: Dodavanje nedostajućih popularnih marki automobila i države Srbija
-- Zastava, Smart, Mini, Lancia, Saab, Chrysler, Dodge, Daewoo, Geely, Chery,
-- Infiniti, Isuzu, DS Automobiles, SsangYong, Rover, Genesis
-- ============================================================================

-- 1. Unos kategorije države porekla 'Srbija' pod 'automobili'
INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order)
VALUES
    ('auto_srbija', 'Srbija', 'directions_car', 'automobili', 15)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order;

-- 2. Unos marki automobila pod odgovarajuće države porekla
INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order)
VALUES
    -- Srbija
    ('auto_zastava', 'Zastava', 'directions_car', 'auto_srbija', 10),

    -- Nemačka
    ('auto_smart', 'Smart', 'directions_car', 'auto_nemacka', 70),

    -- Velika Britanija
    ('auto_mini', 'Mini', 'directions_car', 'auto_velika_britanija', 325),
    ('auto_rover', 'Rover', 'directions_car', 'auto_velika_britanija', 370),

    -- Italija
    ('auto_lancia', 'Lancia', 'directions_car', 'auto_italija', 280),

    -- Francuska
    ('auto_ds', 'DS Automobiles', 'directions_car', 'auto_francuska', 320),

    -- Švedska
    ('auto_saab', 'Saab', 'directions_car', 'auto_svedska', 430),

    -- SAD
    ('auto_chrysler', 'Chrysler', 'directions_car', 'auto_sad', 230),
    ('auto_dodge', 'Dodge', 'directions_car', 'auto_sad', 240),

    -- Japan
    ('auto_infiniti', 'Infiniti', 'directions_car', 'auto_japan', 145),
    ('auto_isuzu', 'Isuzu', 'directions_car', 'auto_japan', 150),

    -- Južna Koreja
    ('auto_daewoo', 'Daewoo', 'directions_car', 'auto_juzna_koreja', 170),
    ('auto_ssangyong', 'SsangYong', 'directions_car', 'auto_juzna_koreja', 180),
    ('auto_genesis', 'Genesis', 'directions_car', 'auto_juzna_koreja', 190),

    -- Kina
    ('auto_geely', 'Geely', 'directions_car', 'auto_kina', 420),
    ('auto_chery', 'Chery', 'directions_car', 'auto_kina', 430)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order;
