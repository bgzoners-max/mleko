-- Hosted Supabase projekti često koriste enum public.notification_type za notifications.type.
-- Triggeri iz 20260322140000_notify_on_new_reviews.sql umeću 'new_review' i 'new_buyer_review';
-- bez ovih vrednosti INSERT pada sa: invalid input value for enum notification_type.

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'public'
      AND t.typname = 'notification_type'
  ) THEN
    EXECUTE 'ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS ''new_review''';
    EXECUTE 'ALTER TYPE public.notification_type ADD VALUE IF NOT EXISTS ''new_buyer_review''';
  END IF;
END $$;
