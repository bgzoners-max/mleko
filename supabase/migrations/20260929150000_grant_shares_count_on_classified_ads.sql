-- ============================================================================
-- Migracija 20260929150000: Grant SELECT on shares_count on classified_ads
--
-- Popravlja kolonsku SELECT privilegiju nad classified_ads.
-- U migraciji 20260929100000, dodeljena su prava za sve kolone osim 'phone' (koji je osetljiv),
-- ali je kolona 'shares_count' (dodata u migraciji 20260910270000) bila izostavljena,
-- što je dovodilo do greške 'permission denied for column shares_count' pri učitavanju
-- korisničkih oglasa (MyClassifiedAdsScreen).
-- ============================================================================

GRANT SELECT (shares_count) ON public.classified_ads TO anon, authenticated;
