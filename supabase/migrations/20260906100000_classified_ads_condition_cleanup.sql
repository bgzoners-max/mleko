-- ============================================================================
-- Migracija 20260906100000: Usklađivanje stanja ('not_applicable') za životinje, voće i povrće
-- Za životinje (mačići, mačke, psi, stoka, živina...), voće, povrće, sadnice, stočnu hranu,
-- usluge i nekretnine stanje 'Novo'/'Polovno' nema logike i postavlja se na 'not_applicable'.
-- ============================================================================

-- 1. Ažuriranje postojećih oglasa u bazi za kategorije gde stanje nije primenjivo
UPDATE public.classified_ads
SET condition = 'not_applicable'
WHERE condition != 'not_applicable'
  AND (
    category_id IN (
      -- Kućni ljubimci i domaće životinje
      'ljubimci', 'psi', 'lovacki_psi', 'cuvari_ovcari', 'mali_kucni_psi', 'terijeri_gonici', 'udomljavanje_pasa',
      'macke', 'rasne_macke', 'domace_macke', 'domace_zivotinje', 'stocarstvo_zivotinje', 'krave_telad',
      'ovce_jagnjad', 'koze_jarici', 'svinje_prasad', 'konji_magarci', 'zivina_ptice', 'kokoske_pilici',
      'curke', 'patke_guske', 'papagaji_ptice', 'golubovi', 'pcelarstvo', 'pcelinja_drustva_matice',
      'hrana_psi_macke', 'koncentrati_premiksi',

      -- Voće, povrće, sadnice, rasad, semena, stočna hrana
      'sadnice_semena', 'sadnice_voca', 'sadnice_vinove_loze', 'semenska_roba', 'semenski_krompir_luk',
      'rasad_povrca', 'stocna_hrana', 'balirano_seno_lucerka', 'balirana_slama', 'kukuruz_stocni',
      'zitarice_stocne', 'silaza_senaza', 'mekinje_sacme',

      -- Usluge i nekretnine
      'usluge', 'poljoprivredne_usluge', 'majstori_zanatlije', 'gradjevinske_usluge', 'prevoz_selidbe',
      'servis_mehanike', 'poslovi_zaposlenje', 'nekretnine', 'stanovi', 'kuce_domacinstva', 'vikendice',
      'poljoprivredno_zemljiste', 'gradjevinski_placevi', 'poslovni_prostori', 'garaze_parking'
    )
    OR (
      -- Zaštita i pretraga po naslovu za mačiće, pse, životinje, voće, povrće ako nisu oprema/mašine
      LOWER(title) ~* '(mačić|macic|mačk|mack|šten|sten|kučić|kucic|krav|telad|tele|junad|junic|bik|ovc|jagnj|ovan|koz|jarić|jaric|jarac|svinj|prasad|prase|krmač|krmac|konj|ždreb|zdreb|kobil|kokoš|kokos|pilić|pilic|pile|ćurk|curk|ćurić|curic|patk|gusk|mork|ptic|papagaj|kanarin|golub|pčel|pcel|rojevi|matic|voće|voce|povrće|povrce|jabuk|krušk|krusk|šljiv|sljiv|malin|kupin|jagod|trešnj|tresnj|višnj|visnj|grožđ|grozd|kajsij|breskv|dunj|lešnik|lesnik|orah|orasi|krompir|paradajz|paprik|kupus|pasulj|šargarep|sargarep|cvekl|krastav|tikvic|grašak|grasak|spanać|spanac|zelje|rotkvic|sadnic|rasad|semen|pšenic|psenic|kukuruz|ječam|jecam|lucerk|seno|slama)'
      AND NOT (LOWER(title) ~* '(oprem|mašin|masin|alat|delov|pribor|kavez|boks|kućic|kucic|mlin|sečk|seck|pres|kazan|burad|flaš|flas|pump|trak|sistem|ogrlic|povoc|hranilic|pojilic|muzilic|košnic|kosnic|ramov|centrifug|traktor|kombajn|priključ|prikljuc)')
    )
  );

-- 2. Trigger za automatsko postavljanje 'not_applicable' pri unosu/izmeni oglasa za ove kategorije
CREATE OR REPLACE FUNCTION public.enforce_classified_ad_condition()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.category_id IN (
      'ljubimci', 'psi', 'lovacki_psi', 'cuvari_ovcari', 'mali_kucni_psi', 'terijeri_gonici', 'udomljavanje_pasa',
      'macke', 'rasne_macke', 'domace_macke', 'domace_zivotinje', 'stocarstvo_zivotinje', 'krave_telad',
      'ovce_jagnjad', 'koze_jarici', 'svinje_prasad', 'konji_magarci', 'zivina_ptice', 'kokoske_pilici',
      'curke', 'patke_guske', 'papagaji_ptice', 'golubovi', 'pcelarstvo', 'pcelinja_drustva_matice',
      'hrana_psi_macke', 'koncentrati_premiksi',
      'sadnice_semena', 'sadnice_voca', 'sadnice_vinove_loze', 'semenska_roba', 'semenski_krompir_luk',
      'rasad_povrca', 'stocna_hrana', 'balirano_seno_lucerka', 'balirana_slama', 'kukuruz_stocni',
      'zitarice_stocne', 'silaza_senaza', 'mekinje_sacme',
      'usluge', 'poljoprivredne_usluge', 'majstori_zanatlije', 'gradjevinske_usluge', 'prevoz_selidbe',
      'servis_mehanike', 'poslovi_zaposlenje', 'nekretnine', 'stanovi', 'kuce_domacinstva', 'vikendice',
      'poljoprivredno_zemljiste', 'gradjevinski_placevi', 'poslovni_prostori', 'garaze_parking'
  ) THEN
    NEW.condition := 'not_applicable';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_enforce_classified_ad_condition ON public.classified_ads;
CREATE TRIGGER trigger_enforce_classified_ad_condition
  BEFORE INSERT OR UPDATE ON public.classified_ads
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_classified_ad_condition();
