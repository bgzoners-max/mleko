-- ============================================================================
-- Migracija: 48 zasebnih marki automobila za podkategoriju Automobili (automobili)
-- ============================================================================

-- 1. Bezbedno prebacivanje eventualnih postojećih oglasa sa starih privremenih grupa
UPDATE public.classified_ads
SET category_id = 'automobili'
WHERE category_id IN (
    'automobili_nemacki',
    'automobili_francuski',
    'automobili_italijanski',
    'automobili_azijski'
);

-- 2. Uklanjanje starih privremenih regionalnih grupa
DELETE FROM public.classified_categories
WHERE id IN (
    'automobili_nemacki',
    'automobili_francuski',
    'automobili_italijanski',
    'automobili_azijski'
);

-- 3. Ubacivanje 48 pojedinačnih marki automobila + Ostale marke
INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order)
VALUES
    -- Nemačka
    ('auto_volkswagen', 'Volkswagen', 'directions_car', 'automobili', 10),
    ('auto_bmw', 'BMW', 'directions_car', 'automobili', 20),
    ('auto_mercedes_benz', 'Mercedes-Benz', 'directions_car', 'automobili', 30),
    ('auto_audi', 'Audi', 'directions_car', 'automobili', 40),
    ('auto_porsche', 'Porsche', 'directions_car', 'automobili', 50),
    ('auto_opel', 'Opel', 'directions_car', 'automobili', 60),

    -- Japan
    ('auto_toyota', 'Toyota', 'directions_car', 'automobili', 70),
    ('auto_honda', 'Honda', 'directions_car', 'automobili', 80),
    ('auto_nissan', 'Nissan', 'directions_car', 'automobili', 90),
    ('auto_mazda', 'Mazda', 'directions_car', 'automobili', 100),
    ('auto_subaru', 'Subaru', 'directions_car', 'automobili', 110),
    ('auto_suzuki', 'Suzuki', 'directions_car', 'automobili', 120),
    ('auto_mitsubishi', 'Mitsubishi', 'directions_car', 'automobili', 130),
    ('auto_lexus', 'Lexus', 'directions_car', 'automobili', 140),

    -- Južna Koreja
    ('auto_hyundai', 'Hyundai', 'directions_car', 'automobili', 150),
    ('auto_kia', 'Kia', 'directions_car', 'automobili', 160),

    -- SAD
    ('auto_ford', 'Ford', 'directions_car', 'automobili', 170),
    ('auto_chevrolet', 'Chevrolet', 'directions_car', 'automobili', 180),
    ('auto_tesla', 'Tesla', 'directions_car', 'automobili', 190),
    ('auto_jeep', 'Jeep', 'directions_car', 'automobili', 200),
    ('auto_cadillac', 'Cadillac', 'directions_car', 'automobili', 210),
    ('auto_rivian', 'Rivian', 'directions_car', 'automobili', 220),

    -- Italija
    ('auto_fiat', 'Fiat', 'directions_car', 'automobili', 230),
    ('auto_alfa_romeo', 'Alfa Romeo', 'directions_car', 'automobili', 240),
    ('auto_ferrari', 'Ferrari', 'directions_car', 'automobili', 250),
    ('auto_maserati', 'Maserati', 'directions_car', 'automobili', 260),
    ('auto_lamborghini', 'Lamborghini', 'directions_car', 'automobili', 270),

    -- Francuska
    ('auto_renault', 'Renault', 'directions_car', 'automobili', 280),
    ('auto_peugeot', 'Peugeot', 'directions_car', 'automobili', 290),
    ('auto_citroen', 'Citroën', 'directions_car', 'automobili', 300),
    ('auto_bugatti', 'Bugatti', 'directions_car', 'automobili', 310),

    -- Velika Britanija
    ('auto_jaguar', 'Jaguar', 'directions_car', 'automobili', 320),
    ('auto_land_rover', 'Land Rover', 'directions_car', 'automobili', 330),
    ('auto_aston_martin', 'Aston Martin', 'directions_car', 'automobili', 340),
    ('auto_bentley', 'Bentley', 'directions_car', 'automobili', 350),
    ('auto_rolls_royce', 'Rolls-Royce', 'directions_car', 'automobili', 360),

    -- Kina
    ('auto_byd', 'BYD', 'directions_car', 'automobili', 370),
    ('auto_nio', 'NIO', 'directions_car', 'automobili', 380),
    ('auto_xpeng', 'XPeng', 'directions_car', 'automobili', 390),
    ('auto_zeekr', 'Zeekr', 'directions_car', 'automobili', 400),
    ('auto_mg', 'MG', 'directions_car', 'automobili', 410),

    -- Švedska
    ('auto_volvo', 'Volvo', 'directions_car', 'automobili', 420),
    ('auto_polestar', 'Polestar', 'directions_car', 'automobili', 430),

    -- Češka
    ('auto_skoda', 'Škoda', 'directions_car', 'automobili', 440),

    -- Španija
    ('auto_seat', 'SEAT', 'directions_car', 'automobili', 450),
    ('auto_cupra', 'CUPRA', 'directions_car', 'automobili', 460),

    -- Rumunija
    ('auto_dacia', 'Dacia', 'directions_car', 'automobili', 470),

    -- Rusija
    ('auto_lada', 'Lada', 'directions_car', 'automobili', 480),

    -- Ostalo
    ('auto_ostalo', 'Ostale marke', 'directions_car', 'automobili', 520)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order;
