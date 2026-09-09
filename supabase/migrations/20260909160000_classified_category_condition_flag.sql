-- ============================================================================
-- Migracija 20260909160000: Dodavanje kolone is_condition_applicable na classified_categories
-- Rešava arhitektonski problem C2 (dupliranje pravila o stanju predmeta u klijentu i bazi).
-- ============================================================================

-- 1. Dodavanje kolone is_condition_applicable sa podrazumevanom vrednošću true
ALTER TABLE public.classified_categories 
ADD COLUMN IF NOT EXISTS is_condition_applicable BOOLEAN NOT NULL DEFAULT true;

-- 2. Označavanje kategorija za koje stanje nema smisla (životinje, biljke, hrana, usluge, nekretnine)
UPDATE public.classified_categories 
SET is_condition_applicable = false
WHERE id IN (
    -- Glavni stubovi
    'ljubimci', 'usluge', 'nekretnine',
    
    -- Životinje i podkategorije
    'psi', 'lovacki_psi', 'cuvari_ovcari', 'mali_kucni_psi', 'terijeri_gonici', 'udomljavanje_pasa',
    'macke', 'rasne_macke', 'domace_macke', 'domace_zivotinje', 'stocarstvo_zivotinje', 'krave_telad',
    'ovce_jagnjad', 'koze_jarici', 'svinje_prasad', 'konji_magarci', 'zivina_ptice', 'kokoske_pilici',
    'curke', 'patke_guske', 'papagaji_ptice', 'golubovi', 'pcelarstvo', 'pcelinja_drustva_matice',
    'hrana_psi_macke', 'koncentrati_premiksi',
    
    -- Voće, povrće, sadnice, rasad, semena, stočna hrana
    'sadnice_semena', 'sadnice_voca', 'sadnice_vinove_loze', 'semenska_roba', 'semenski_krompir_luk',
    'rasad_povrca', 'stocna_hrana', 'balirano_seno_lucerka', 'balirana_slama', 'kukuruz_stocni',
    'zitarice_stocne', 'silaza_senaza', 'mekinje_sacme',
    
    -- Usluge
    'poljoprivredne_usluge', 'majstori_zanatlije', 'gradjevinske_usluge', 'prevoz_selidbe',
    'servis_mehanike', 'poslovi_zaposlenje',
    
    -- Nekretnine
    'stanovi', 'kuce_domacinstva', 'vikendice',
    'poljoprivredno_zemljiste', 'gradjevinski_placevi', 'poslovni_prostori', 'garaze_parking'
) OR (
    -- Sve podkategorije pod uslugama i nekretninama
    parent_id IN ('usluge', 'nekretnine')
);

-- Izuzetak: oprema za životinje, košnice i delovi mehanizacije imaju stanje
UPDATE public.classified_categories
SET is_condition_applicable = true
WHERE id IN ('oprema_za_zivotinje', 'delovi_za_traktore', 'prerada_voca_oprema');

-- 3. Pojednostavljeni trigger koji čita is_condition_applicable direktno iz kategorije
CREATE OR REPLACE FUNCTION public.enforce_classified_ad_condition()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_applicable BOOLEAN;
BEGIN
    SELECT is_condition_applicable
    INTO v_applicable
    FROM public.classified_categories
    WHERE id = NEW.category_id;

    IF v_applicable = false THEN
        NEW.condition := 'not_applicable';
    END IF;

    RETURN NEW;
END;
$$;
