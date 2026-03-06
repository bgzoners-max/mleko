-- Tagovi prodavca: predefinisane oznake koje kupac vidi na profilu
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS seller_tags TEXT[] DEFAULT '{}';
