-- Hosted projekat koristi notification_type enum.
-- Support tiket trigger upisuje support_ticket_created, pa vrednost mora postojati.

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'public'
      AND t.typname = 'notification_type'
  ) THEN
    ALTER TYPE public.notification_type
      ADD VALUE IF NOT EXISTS 'support_ticket_created';
  END IF;
END
$$;
