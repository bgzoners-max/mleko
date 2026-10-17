-- Dodavanje nedostajućih vrednosti u public.notification_type enum.
-- 1. 'admin_reply': triger notify_user_on_admin_ticket_reply() šalje ovu notifikaciju korisniku
--    kad admin pošalje odgovor na tiket (support_ticket_messages).
-- 2. 'classified_ad_moderation', 'classified_saved_search', 'new_classified_ad':
--    tipovi notifikacija za modul malih oglasa.

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'public'
      AND t.typname = 'notification_type'
  ) THEN
    EXECUTE 'ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS ''admin_reply''';
    EXECUTE 'ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS ''classified_ad_moderation''';
    EXECUTE 'ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS ''classified_saved_search''';
    EXECUTE 'ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS ''new_classified_ad''';
  END IF;
END $$;
