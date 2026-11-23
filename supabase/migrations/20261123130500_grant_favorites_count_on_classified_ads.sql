-- Dopuna kolonskog GRANT SELECT za novu kolonu `favorites_count` na `public.classified_ads`.
-- Tabela `public.classified_ads` koristi eksplicitne kolonske SELECT dozvole kako bi kolona
-- `phone` ostala skrivena od direktnih upita; bez ovog GRANT-a PostgREST vraća 42501
-- ("permission denied for table classified_ads") kada klijent selektuje `favorites_count`.

GRANT SELECT (favorites_count) ON public.classified_ads TO anon, authenticated;
