-- ============================================================================
-- Migracija: Hijerarhijska podela marki automobila po državama porekla
-- Automobili -> Države (Nemačka, Japan...) -> Marke (Volkswagen, BMW...)
-- ============================================================================

-- 1. Unos kategorija država porekla pod kategoriju 'automobili'
INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order)
VALUES
    ('auto_nemacka', 'Nemačka', 'directions_car', 'automobili', 10),
    ('auto_francuska', 'Francuska', 'directions_car', 'automobili', 20),
    ('auto_italija', 'Italija', 'directions_car', 'automobili', 30),
    ('auto_japan', 'Japan', 'directions_car', 'automobili', 40),
    ('auto_ceska', 'Češka', 'directions_car', 'automobili', 50),
    ('auto_sad', 'SAD', 'directions_car', 'automobili', 60),
    ('auto_juzna_koreja', 'Južna Koreja', 'directions_car', 'automobili', 70),
    ('auto_velika_britanija', 'Velika Britanija', 'directions_car', 'automobili', 80),
    ('auto_svedska', 'Švedska', 'directions_car', 'automobili', 90),
    ('auto_spanija', 'Španija', 'directions_car', 'automobili', 100),
    ('auto_rumunija', 'Rumunija', 'directions_car', 'automobili', 110),
    ('auto_rusija', 'Rusija', 'directions_car', 'automobili', 120),
    ('auto_kina', 'Kina', 'directions_car', 'automobili', 130)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order;

-- 2. Postavljanje parent_id za svaku marku automobila na odgovarajuću državu porekla

-- Nemačka
UPDATE public.classified_categories
SET parent_id = 'auto_nemacka'
WHERE id IN ('auto_volkswagen', 'auto_bmw', 'auto_mercedes_benz', 'auto_audi', 'auto_porsche', 'auto_opel');

-- Japan
UPDATE public.classified_categories
SET parent_id = 'auto_japan'
WHERE id IN ('auto_toyota', 'auto_honda', 'auto_nissan', 'auto_mazda', 'auto_subaru', 'auto_suzuki', 'auto_mitsubishi', 'auto_lexus');

-- Južna Koreja
UPDATE public.classified_categories
SET parent_id = 'auto_juzna_koreja'
WHERE id IN ('auto_hyundai', 'auto_kia');

-- SAD
UPDATE public.classified_categories
SET parent_id = 'auto_sad'
WHERE id IN ('auto_ford', 'auto_chevrolet', 'auto_tesla', 'auto_jeep', 'auto_cadillac', 'auto_rivian');

-- Italija
UPDATE public.classified_categories
SET parent_id = 'auto_italija'
WHERE id IN ('auto_fiat', 'auto_alfa_romeo', 'auto_ferrari', 'auto_maserati', 'auto_lamborghini');

-- Francuska
UPDATE public.classified_categories
SET parent_id = 'auto_francuska'
WHERE id IN ('auto_renault', 'auto_peugeot', 'auto_citroen', 'auto_bugatti');

-- Velika Britanija
UPDATE public.classified_categories
SET parent_id = 'auto_velika_britanija'
WHERE id IN ('auto_jaguar', 'auto_land_rover', 'auto_aston_martin', 'auto_bentley', 'auto_rolls_royce');

-- Kina
UPDATE public.classified_categories
SET parent_id = 'auto_kina'
WHERE id IN ('auto_byd', 'auto_nio', 'auto_xpeng', 'auto_zeekr', 'auto_mg');

-- Švedska
UPDATE public.classified_categories
SET parent_id = 'auto_svedska'
WHERE id IN ('auto_volvo', 'auto_polestar');

-- Češka
UPDATE public.classified_categories
SET parent_id = 'auto_ceska'
WHERE id IN ('auto_skoda');

-- Španija
UPDATE public.classified_categories
SET parent_id = 'auto_spanija'
WHERE id IN ('auto_seat', 'auto_cupra');

-- Rumunija
UPDATE public.classified_categories
SET parent_id = 'auto_rumunija'
WHERE id IN ('auto_dacia');

-- Rusija
UPDATE public.classified_categories
SET parent_id = 'auto_rusija'
WHERE id IN ('auto_lada');
