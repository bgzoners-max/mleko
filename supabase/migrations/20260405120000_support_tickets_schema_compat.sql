-- Uskladi hostovanu support_tickets tabelu sa Flutter aplikacijom.
-- Produkcija je ostala na starijoj verziji sa email/message/admin_reply kolonama.

CREATE SEQUENCE IF NOT EXISTS public.support_ticket_seq START 1;

ALTER TABLE public.support_tickets
  ADD COLUMN IF NOT EXISTS ticket_number text,
  ADD COLUMN IF NOT EXISTS user_email text,
  ADD COLUMN IF NOT EXISTS user_name text,
  ADD COLUMN IF NOT EXISTS category text,
  ADD COLUMN IF NOT EXISTS body text,
  ADD COLUMN IF NOT EXISTS admin_note text;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'support_tickets' AND column_name = 'email'
  ) THEN
    UPDATE public.support_tickets SET user_email = COALESCE(user_email, email) WHERE user_email IS NULL;
  END IF;
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'support_tickets' AND column_name = 'message'
  ) THEN
    UPDATE public.support_tickets SET body = COALESCE(body, message) WHERE body IS NULL;
  END IF;
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'support_tickets' AND column_name = 'admin_reply'
  ) THEN
    UPDATE public.support_tickets SET admin_note = COALESCE(admin_note, admin_reply) WHERE admin_note IS NULL;
  END IF;
END
$$;

UPDATE public.support_tickets
SET category = 'ostalo'
WHERE category IS NULL OR btrim(category) = '';

UPDATE public.support_tickets
SET ticket_number = 'MLK-'
  || to_char(COALESCE(created_at, now()), 'YYYY')
  || '-'
  || lpad(nextval('public.support_ticket_seq')::text, 5, '0')
WHERE ticket_number IS NULL OR btrim(ticket_number) = '';

ALTER TABLE public.support_tickets
  ALTER COLUMN user_email DROP DEFAULT,
  ALTER COLUMN user_name DROP DEFAULT,
  ALTER COLUMN category SET DEFAULT 'ostalo',
  ALTER COLUMN category SET NOT NULL,
  ALTER COLUMN body SET NOT NULL,
  ALTER COLUMN ticket_number SET DEFAULT 'MLK-'
    || to_char(now(), 'YYYY')
    || '-'
    || lpad(nextval('public.support_ticket_seq')::text, 5, '0');

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'support_tickets_ticket_number_key'
  ) THEN
    ALTER TABLE public.support_tickets
      ADD CONSTRAINT support_tickets_ticket_number_key UNIQUE (ticket_number);
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'support_tickets_category_check'
  ) THEN
    ALTER TABLE public.support_tickets
      ADD CONSTRAINT support_tickets_category_check
      CHECK (category IN ('bug', 'pitanje', 'sugestija', 'ostalo'));
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'support_tickets_body_length'
  ) THEN
    ALTER TABLE public.support_tickets
      ADD CONSTRAINT support_tickets_body_length
      CHECK (char_length(body) BETWEEN 10 AND 5000);
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'support_tickets_status_check'
  ) THEN
    ALTER TABLE public.support_tickets
      ADD CONSTRAINT support_tickets_status_check
      CHECK (status IN ('otvoren', 'u_obradi', 'zatvoren'));
  END IF;
END
$$;

CREATE INDEX IF NOT EXISTS idx_support_tickets_user_id
  ON public.support_tickets(user_id);

CREATE INDEX IF NOT EXISTS idx_support_tickets_created_at
  ON public.support_tickets(created_at DESC);

CREATE OR REPLACE FUNCTION public.update_support_ticket_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_support_tickets_updated_at ON public.support_tickets;
CREATE TRIGGER trg_support_tickets_updated_at
  BEFORE UPDATE ON public.support_tickets
  FOR EACH ROW
  EXECUTE FUNCTION public.update_support_ticket_updated_at();

NOTIFY pgrst, 'reload schema';
