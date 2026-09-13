-- Migracija za proširenje hijerarhije kategorija nekretnina
-- Datum: 2026-09-11

-- 1. Unos detaljnih podkategorija za nekretnine
INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order)
VALUES
    -- Stanovi
    ('stanovi_prodaja', 'Stanovi – Prodaja', 'apartment', 'stanovi', 10),
    ('stanovi_izdavanje', 'Stanovi – Izdavanje', 'key', 'stanovi', 20),
    ('garsonjere', 'Garsonjere i manji stanovi', 'single_bed', 'stanovi', 30),

    -- Kuće i domaćinstva
    ('kuce_prodaja', 'Kuće – Prodaja', 'home', 'kuce_domacinstva', 10),
    ('kuce_izdavanje', 'Kuće – Izdavanje', 'key', 'kuce_domacinstva', 20),
    ('seoska_domacinstva', 'Seoska domaćinstva i gazdinstva', 'cottage', 'kuce_domacinstva', 30),
    ('montazne_kuce', 'Montažne kuće i brvnare', 'cabin', 'kuce_domacinstva', 40),

    -- Vikendice i salaši
    ('vikendice_prodaja', 'Vikendice – Prodaja', 'cabin', 'vikendice', 10),
    ('vikendice_dan', 'Izdavanje na dan / Seoski turizam', 'hotel', 'vikendice', 20),
    ('salasi', 'Salaši i vojvođanska imanja', 'agriculture', 'vikendice', 30),

    -- Poljoprivredno zemljište
    ('njive_oranice', 'Njive i obradivo zemljište', 'terrain', 'poljoprivredno_zemljiste', 10),
    ('vocnjaci_vinogradi', 'Voćnjaci i vinogradi', 'yard', 'poljoprivredno_zemljiste', 20),
    ('sume_pasnjaci', 'Šume, pašnjaci i livade', 'forest', 'poljoprivredno_zemljiste', 30),

    -- Građevinski placevi
    ('placevi_gradnja', 'Placevi za stambenu gradnju', 'landscape', 'gradjevinski_placevi', 10),
    ('industrijske_zone', 'Industrijsko i komercijalno zemljište', 'factory', 'gradjevinski_placevi', 20),

    -- Poslovni prostori
    ('lokali', 'Lokali i prodavnice', 'storefront', 'poslovni_prostori', 10),
    ('kancelarije', 'Kancelarijski prostori', 'business', 'poslovni_prostori', 20),
    ('magacini_hale', 'Magacini, hale i radionice', 'warehouse', 'poslovni_prostori', 30)
ON CONFLICT (id) DO UPDATE
SET name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order;

-- 2. Osiguraj da za sve podkategorije nekretnina is_condition_applicable bude false
UPDATE public.classified_categories
SET is_condition_applicable = false
WHERE id = 'nekretnine' 
   OR parent_id = 'nekretnine'
   OR parent_id IN (SELECT id FROM public.classified_categories WHERE parent_id = 'nekretnine');
