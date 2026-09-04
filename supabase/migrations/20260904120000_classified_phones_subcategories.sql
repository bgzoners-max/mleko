-- ============================================================================
-- Migracija: Detaljne podkategorije i brendovi za Mobilne telefone
-- ============================================================================

-- 1. Ažuriranje i dodavanje podkategorija 2. nivoa pod 'telefoni'
UPDATE public.classified_categories
SET name = 'Pametni telefoni (Smartphones)', icon_name = 'smartphone', sort_order = 10
WHERE id = 'smartfoni';

INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order)
VALUES
    ('robusni_telefoni', 'Robusni telefoni (Rugged / Outdoor)', 'shield', 'telefoni', 20),
    ('klasicni_telefoni', 'Klasični telefoni (Dugmaši / Za starije)', 'dialpad', 'telefoni', 30)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order;

-- Ažuriranje sort_order za ostale podkategorije u 'telefoni'
UPDATE public.classified_categories SET sort_order = 40 WHERE id = 'maske_futrole';
UPDATE public.classified_categories SET sort_order = 50 WHERE id = 'punjaci_baterije';
UPDATE public.classified_categories SET sort_order = 60 WHERE id = 'slusalice_audio';
UPDATE public.classified_categories SET sort_order = 70 WHERE id = 'pametni_satovi';
UPDATE public.classified_categories SET sort_order = 80 WHERE id = 'delovi_telefoni';

-- 2. Brisanje starih privremenih podkategorija pod 'smartfoni'
DELETE FROM public.classified_categories 
WHERE id IN ('iphone', 'honor_huawei', 'ostali_smartfoni');

-- 3. Ubacivanje brendova za Pametni telefoni (Smartphones)
INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order)
VALUES
    ('apple', 'Apple', 'smartphone', 'smartfoni', 10),
    ('samsung', 'Samsung', 'smartphone', 'smartfoni', 20),
    ('xiaomi', 'Xiaomi', 'smartphone', 'smartfoni', 30),
    ('redmi', 'Redmi', 'smartphone', 'smartfoni', 40),
    ('poco', 'POCO', 'smartphone', 'smartfoni', 50),
    ('honor', 'Honor', 'smartphone', 'smartfoni', 60),
    ('motorola', 'Motorola', 'smartphone', 'smartfoni', 70),
    ('realme', 'Realme', 'smartphone', 'smartfoni', 80),
    ('vivo', 'Vivo', 'smartphone', 'smartfoni', 90),
    ('infinix', 'Infinix', 'smartphone', 'smartfoni', 100),
    ('tecno', 'Tecno', 'smartphone', 'smartfoni', 110),
    ('google', 'Google', 'smartphone', 'smartfoni', 120),
    ('nothing', 'Nothing', 'smartphone', 'smartfoni', 130),
    ('cmf_nothing', 'CMF by Nothing', 'smartphone', 'smartfoni', 140),
    ('huawei', 'Huawei', 'smartphone', 'smartfoni', 150),
    ('asus', 'Asus', 'smartphone', 'smartfoni', 160),
    ('asus_rog', 'ROG', 'smartphone', 'smartfoni', 170),
    ('asus_zenfone', 'Zenfone', 'smartphone', 'smartfoni', 180),
    ('sony', 'Sony', 'smartphone', 'smartfoni', 190),
    ('zte', 'ZTE', 'smartphone', 'smartfoni', 200),
    ('nubia', 'Nubia', 'smartphone', 'smartfoni', 210),
    ('tcl', 'TCL', 'smartphone', 'smartfoni', 220)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order;

-- 4. Ubacivanje brendova za Robusni telefoni (Rugged / Outdoor)
INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order)
VALUES
    ('cat', 'CAT', 'shield', 'robusni_telefoni', 10),
    ('blackview', 'Blackview', 'shield', 'robusni_telefoni', 20),
    ('ulefone', 'Ulefone', 'shield', 'robusni_telefoni', 30),
    ('doogee', 'Doogee', 'shield', 'robusni_telefoni', 40),
    ('cubot', 'Cubot', 'shield', 'robusni_telefoni', 50),
    ('oukitel', 'Oukitel', 'shield', 'robusni_telefoni', 60)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order;

-- 5. Ubacivanje brendova za Klasični telefoni (Dugmaši / Za starije)
INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order)
VALUES
    ('nokia_hmd', 'Nokia / HMD', 'dialpad', 'klasicni_telefoni', 10),
    ('meanit', 'MeanIT', 'dialpad', 'klasicni_telefoni', 20),
    ('denver', 'Denver', 'dialpad', 'klasicni_telefoni', 30),
    ('panasonic', 'Panasonic', 'dialpad', 'klasicni_telefoni', 40),
    ('maxcom', 'Maxcom', 'dialpad', 'klasicni_telefoni', 50),
    ('doro', 'Doro', 'dialpad', 'klasicni_telefoni', 60)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order;
