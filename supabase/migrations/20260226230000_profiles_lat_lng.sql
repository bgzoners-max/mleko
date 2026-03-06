-- Koordinate za mapu prodavaca – kolone lat/lng u profiles
-- Potrebno za "Prodavci na mapi"

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS lat NUMERIC;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS lng NUMERIC;
