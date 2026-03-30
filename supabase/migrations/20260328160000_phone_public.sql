-- Add phone_public flag to profiles
-- Controls whether the buyer's phone is visible on their public profile
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS phone_public BOOLEAN NOT NULL DEFAULT false;
