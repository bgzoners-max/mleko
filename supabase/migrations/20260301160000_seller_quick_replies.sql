-- Prodavci: sopstveni šabloni brzih odgovora u chatu

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS seller_quick_replies TEXT[] DEFAULT '{}'::text[];

