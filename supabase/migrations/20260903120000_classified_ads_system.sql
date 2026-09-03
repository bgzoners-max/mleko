-- ============================================================================
-- Migracija za Veliki Oglasnik (Classifieds) platforme Domaći Market
-- ============================================================================

-- 1. Tabela kategorija oglasa
CREATE TABLE IF NOT EXISTS public.classified_categories (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    icon_name TEXT NOT NULL,
    parent_id TEXT REFERENCES public.classified_categories(id) ON DELETE SET NULL,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- RLS za classified_categories
ALTER TABLE public.classified_categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "classified_categories_read_all"
    ON public.classified_categories FOR SELECT
    USING (true);

-- 2. Tabela malih oglasa
CREATE TABLE IF NOT EXISTS public.classified_ads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    price NUMERIC NOT NULL DEFAULT 0,
    currency TEXT NOT NULL DEFAULT 'RSD' CHECK (currency IN ('RSD', 'EUR')),
    price_type TEXT NOT NULL DEFAULT 'fixed' CHECK (price_type IN ('fixed', 'negotiable', 'call', 'free')),
    category_id TEXT NOT NULL REFERENCES public.classified_categories(id) ON DELETE RESTRICT,
    condition TEXT NOT NULL DEFAULT 'used' CHECK (condition IN ('new', 'used', 'not_applicable')),
    images TEXT[] NOT NULL DEFAULT '{}',
    city TEXT NOT NULL,
    phone TEXT,
    phone_public BOOLEAN NOT NULL DEFAULT true,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'sold', 'archived')),
    views_count INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indeksi za maksimalne performanse pretrage i filtriranja
CREATE INDEX IF NOT EXISTS idx_classified_ads_status_created 
    ON public.classified_ads (status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_classified_ads_category 
    ON public.classified_ads (category_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_classified_ads_user 
    ON public.classified_ads (user_id);

CREATE INDEX IF NOT EXISTS idx_classified_ads_city 
    ON public.classified_ads (city);

-- RLS za classified_ads
ALTER TABLE public.classified_ads ENABLE ROW LEVEL SECURITY;

-- Svako može da čita aktivne oglase
CREATE POLICY "classified_ads_read_active"
    ON public.classified_ads FOR SELECT
    USING (status = 'active' OR auth.uid() = user_id);

-- Ulogovani korisnici mogu da kreiraju oglase
CREATE POLICY "classified_ads_insert_auth"
    ON public.classified_ads FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Vlasnik može da menja svoj oglas
CREATE POLICY "classified_ads_update_owner"
    ON public.classified_ads FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Vlasnik može da obriše svoj oglas
CREATE POLICY "classified_ads_delete_owner"
    ON public.classified_ads FOR DELETE
    USING (auth.uid() = user_id);

-- 3. RPC za bezbedno povećanje broja pregleda oglasa
CREATE OR REPLACE FUNCTION public.increment_classified_ad_views(ad_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    UPDATE public.classified_ads
    SET views_count = views_count + 1
    WHERE id = ad_id;
END;
$$;

-- 4. Unos 12 glavnih stubova kategorija oglasa
INSERT INTO public.classified_categories (id, name, icon_name, sort_order)
VALUES
    ('poljoprivreda', 'Poljoprivreda i mehanizacija', 'agriculture', 10),
    ('vozila', 'Vozila i auto-moto', 'directions_car', 20),
    ('masine_alati', 'Mašine, alati i zanatstvo', 'handyman', 30),
    ('dom_basta', 'Dom, nameštaj i bašta', 'chair', 40),
    ('telefoni', 'Mobilni telefoni i oprema', 'smartphone', 50),
    ('tehnika', 'Računari i elektronika', 'laptop', 60),
    ('nekretnine', 'Nekretnine', 'home_work', 70),
    ('gradjevinarstvo', 'Građevinarstvo i materijali', 'foundation', 80),
    ('odeca_obuca', 'Odeća, obuća i aksesoari', 'checkroom', 90),
    ('sport_hobi', 'Sport, lov, ribolov i hobi', 'sports_soccer', 100),
    ('ljubimci', 'Kućni ljubimci i domaće životinje', 'pets', 110),
    ('usluge', 'Usluge i poslovi', 'work', 120)
ON CONFLICT (id) DO NOTHING;

-- Podkategorije za najpopularnije segmente (npr. Poljoprivreda i Vozila)
INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order)
VALUES
    ('traktori', 'Traktori i kombajni', 'agriculture', 'poljoprivreda', 1),
    ('prikljucci', 'Priključne mašine', 'handyman', 'poljoprivreda', 2),
    ('stocna_hrana', 'Stočna hrana i sirovine', 'grass', 'poljoprivreda', 3),
    ('sadnice_semena', 'Sadnice i semena', 'yard', 'poljoprivreda', 4),
    ('stocarstvo_zivotinje', 'Domaće životinje', 'pets', 'poljoprivreda', 5),
    ('automobili', 'Automobili', 'directions_car', 'vozila', 1),
    ('auto_delovi', 'Auto delovi i oprema', 'build', 'vozila', 2),
    ('motocikli', 'Motocikli i skuteri', 'two_wheeler', 'vozila', 3),
    ('bela_tehnika', 'Bela tehnika i aparati', 'kitchen', 'dom_basta', 1),
    ('namestaj', 'Nameštaj', 'chair', 'dom_basta', 2),
    ('elektro_alati', 'Električni i ručni alati', 'construction', 'masine_alati', 1)
ON CONFLICT (id) DO NOTHING;
