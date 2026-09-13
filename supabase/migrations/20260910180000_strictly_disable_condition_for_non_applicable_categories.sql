-- ============================================================================
-- Migracija 20260910180000: Stroga eliminacija stanja ("Novo" / "Polovno")
-- za nekretnine, usluge, žive životinje, useve, semena i hranu.
-- Rešava problem gde su podkategorije 3. nivoa (npr. prodaja_stanova, prodaja_kuca)
-- imale is_condition_applicable = true jer im je parent_id bio 2. nivo, a ne koren.
-- ============================================================================

-- 1. Rekurzivno ažuriranje svih potomaka (1, 2. i 3. nivo) krovnih grana
WITH RECURSIVE non_applicable_tree AS (
    -- Bazni korenski čvorovi i podgrane
    SELECT id, parent_id
    FROM public.classified_categories
    WHERE id IN (
        'nekretnine',
        'usluge',
        'psi',
        'macke',
        'domace_zivotinje',
        'zivina_ptice',
        'stocna_hrana',
        'sadnice_semena'
    )
    UNION ALL
    -- Rekurzivno svi potomci
    SELECT c.id, c.parent_id
    FROM public.classified_categories c
    INNER JOIN non_applicable_tree t ON c.parent_id = t.id
)
UPDATE public.classified_categories
SET is_condition_applicable = false
WHERE id IN (SELECT id FROM non_applicable_tree);

-- 2. Eksplicitno navođenje svih pojedinačnih podkategorija za potpunu robusnost
UPDATE public.classified_categories
SET is_condition_applicable = false
WHERE id IN (
    -- Krovne kategorije
    'nekretnine', 'usluge', 'ljubimci',

    -- Nekretnine - Nivo 2 i Nivo 3
    'stanovi', 'prodaja_stanova', 'izdavanje_stanova', 'stan_na_dan',
    'kuce_domacinstva', 'prodaja_kuca', 'seoska_domacinstva', 'izdavanje_kuca',
    'vikendice', 'planinske_vikendice', 'vikendice_reka_jezero', 'brvnare_eko_kuce',
    'poljoprivredno_zemljiste', 'njive_oranice', 'vocnjaci_vinogradi', 'sume_pasnjaci',
    'gradjevinski_placevi', 'placevi_za_kuce', 'industrijski_placevi',
    'poslovni_prostori', 'lokali', 'kancelarije', 'magacini_hale',
    'garaze_parking', 'prodaja_garaza', 'izdavanje_garaza',

    -- Usluge - Nivo 2 i Nivo 3
    'poljoprivredne_usluge', 'oranje_setva', 'zetva_kombajniranje', 'baliranje_usluge', 'orezivanje_prskanje_voca', 'seca_cepanje_drva',
    'majstori_zanatlije', 'vodoinstalaterske_usluge', 'elektricarske_usluge', 'molerski_gipsarski_radovi', 'keramicari_plocice', 'bravarske_usluge',
    'gradjevinske_usluge', 'iskopi_bageri', 'zidanje_betoniranje', 'krovopokrivacki_radovi', 'asfaltiranje_behaton', 'rusenje_odvoz_suta',
    'prevoz_selidbe', 'kombi_prevoz', 'kamionski_prevoz', 'slep_sluzba', 'selidbe_usluge',
    'servis_mehanike', 'servis_traktora', 'automehanicari', 'autolimari_farbari', 'vulkanizerske_usluge',
    'poslovi_zaposlenje', 'sezonski_poslovi', 'poslovi_gradjevina', 'poslovi_vozaci', 'poslovi_ugostiteljstvo',

    -- Žive životinje i pčele
    'psi', 'lovacki_psi', 'cuvari_ovcari', 'mali_kucni_psi', 'terijeri_gonici', 'udomljavanje_pasa',
    'macke', 'rasne_macke', 'domace_macke',
    'domace_zivotinje', 'stocarstvo_zivotinje', 'krave_telad', 'ovce_jagnjad', 'koze_jarici', 'svinje_prasad', 'konji_magarci',
    'zivina_ptice', 'kokoske_pilici', 'curke', 'patke_guske', 'papagaji_ptice', 'golubovi',
    'pcelinja_drustva_matice',

    -- Hrana za životinje, usevi, sadnice i semena
    'hrana_psi_macke', 'koncentrati_premiksi',
    'stocna_hrana', 'balirano_seno_lucerka', 'balirana_slama', 'kukuruz_stocni', 'zitarice_stocne', 'silaza_senaza', 'mekinje_sacme',
    'sadnice_semena', 'sadnice_voca', 'sadnice_vinove_loze', 'semenska_roba', 'semenski_krompir_luk', 'rasad_povrca'
);

-- 3. Zaštita i potvrda za fizičku opremu koja MOŽE imati stanje (Novo / Polovno)
UPDATE public.classified_categories
SET is_condition_applicable = true
WHERE id IN (
    'oprema_za_zivotinje', 'boksevi_kucice_kavezi', 'hranilice_pojilice_muzilice',
    'pcelarstvo', 'kosnice_ramovi', 'vrcajke_za_med', 'pcelarski_pribor',
    'delovi_za_traktore', 'delovi_motora_traktori', 'gume_za_traktore', 'hidraulika_traktori', 'kardani_kacenja', 'delovi_kombajni_balirke',
    'prerada_voca_oprema', 'kazani_za_rakiju', 'mlinovi_za_voce', 'prese_za_voce', 'burad_prohrom_drvo', 'flase_baloni_staklo',
    'navodnjavanje_plastenici', 'plastenici_folije', 'kap_po_kap_trake', 'pumpe_za_navodnjavanje', 'rezervoari_ibc'
);

-- 4. Rekurzivni trigger koji garantuje da stanje 'not_applicable' važi za celu hijerarhiju
CREATE OR REPLACE FUNCTION public.enforce_classified_ad_condition()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_applicable BOOLEAN;
    v_root_id TEXT;
BEGIN
    -- 1. Provera direktno iz kategorije
    SELECT is_condition_applicable
    INTO v_applicable
    FROM public.classified_categories
    WHERE id = NEW.category_id;

    -- 2. Ako nije eksplicitno podešeno (ili je true, ali predak spada u strogo neprikladne)
    IF v_applicable IS NULL OR v_applicable = true THEN
        WITH RECURSIVE cat_ancestors AS (
            SELECT id, parent_id
            FROM public.classified_categories
            WHERE id = NEW.category_id
            UNION ALL
            SELECT c.id, c.parent_id
            FROM public.classified_categories c
            INNER JOIN cat_ancestors a ON c.id = a.parent_id
        )
        SELECT id INTO v_root_id
        FROM cat_ancestors
        WHERE id IN ('nekretnine', 'usluge', 'psi', 'macke', 'domace_zivotinje', 'zivina_ptice', 'stocna_hrana', 'sadnice_semena')
        LIMIT 1;

        -- Ako je predak neka od ovih grana, a nije izuzetak opreme
        IF v_root_id IS NOT NULL AND NEW.category_id NOT IN (
            'oprema_za_zivotinje', 'boksevi_kucice_kavezi', 'hranilice_pojilice_muzilice',
            'kosnice_ramovi', 'vrcajke_za_med', 'pcelarski_pribor',
            'delovi_za_traktore', 'prerada_voca_oprema', 'navodnjavanje_plastenici'
        ) THEN
            v_applicable := false;
        END IF;
    END IF;

    IF v_applicable = false THEN
        NEW.condition := 'not_applicable';
    END IF;

    RETURN NEW;
END;
$$;

-- 5. Ažuriranje svih postojećih oglasa koji pripadaju neprikladnim kategorijama
UPDATE public.classified_ads
SET condition = 'not_applicable'
WHERE category_id IN (
    SELECT id FROM public.classified_categories WHERE is_condition_applicable = false
)
AND condition != 'not_applicable';
