-- Osiguraj da body kolona postoji (bez IF NOT EXISTS komplikacija)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'support_tickets'
      AND column_name = 'body'
  ) THEN
    ALTER TABLE public.support_tickets ADD COLUMN body text;
  END IF;
END
$$;

-- Forsiraj PostgREST da reloaduje schema cache
NOTIFY pgrst, 'reload schema';
