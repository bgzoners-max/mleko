-- Kolona created_at za prikaz "Član od {datum}" na profilu
-- Ako profiles nema created_at (stari setup), dodaj i popuni iz auth.users

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();

-- Popuni created_at za stare profile iz auth.users (ako je NULL)
UPDATE public.profiles p
SET created_at = COALESCE(au.created_at, NOW())
FROM auth.users au
WHERE p.id = au.id AND p.created_at IS NULL;
