-- =============================================================================
-- Predlozi za arhiviranje i retention – primenjeno korak po korak
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Korak 1: Funkcija za arhiviranje i brisanje
-- U bazi je status = 'sent' (ne 'poslato') – CHECK constraint u orders
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_order_retention()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Arhiviranje: samo status 'sent', starije od 30 dana
  UPDATE public.orders
  SET status = 'arhivirano',
      archived_at = now()
  WHERE status = 'sent'
    AND created_at <= now() - interval '30 days';

  -- Brisanje: expires_at <= sada (order_items se brišu CASCADE)
  DELETE FROM public.orders
  WHERE expires_at <= now();
END;
$$;

-- Zadržavamo i staru funkciju kao wrapper (cron može da poziva bilo koju)
CREATE OR REPLACE FUNCTION public.archive_and_expire_orders()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public.handle_order_retention();
END;
$$;


-- -----------------------------------------------------------------------------
-- Korak 2: FOREIGN KEY sa ON DELETE CASCADE na order_items
-- (Već postoji u 20260228000000_order_items.sql; ovde eksplicitno osiguravamo.)
-- -----------------------------------------------------------------------------
ALTER TABLE public.order_items
  DROP CONSTRAINT IF EXISTS order_items_order_id_fkey;

ALTER TABLE public.order_items
  ADD CONSTRAINT order_items_order_id_fkey
  FOREIGN KEY (order_id)
  REFERENCES public.orders(id)
  ON DELETE CASCADE;


-- -----------------------------------------------------------------------------
-- Korak 3: pg_cron – dnevno u 03:00
-- Unschedule samo ako job postoji (inače pg_cron baca grešku)
-- -----------------------------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'archive-and-expire-orders') THEN
      PERFORM cron.unschedule('archive-and-expire-orders');
    END IF;
    IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'daily_order_retention') THEN
      PERFORM cron.unschedule('daily_order_retention');
    END IF;
  END IF;
EXCEPTION WHEN undefined_object THEN NULL;
END
$$;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    PERFORM cron.schedule(
      'daily_order_retention',
      '0 3 * * *',
      'SELECT public.handle_order_retention()'
    );
  END IF;
EXCEPTION WHEN undefined_object THEN NULL;
END
$$;


-- -----------------------------------------------------------------------------
-- Korak 4: expires_at NOT NULL + DEFAULT (100% sigurnost)
-- Prvo popunimo postojeće redove, pa constraint i default za buduće insert-e
-- -----------------------------------------------------------------------------
UPDATE public.orders
SET expires_at = created_at + interval '12 months'
WHERE expires_at IS NULL;

ALTER TABLE public.orders
  ALTER COLUMN expires_at SET NOT NULL;

-- Pri kreiranju porudžbine: ako expires_at nije poslat, baza postavlja now() + 12 meseci
ALTER TABLE public.orders
  ALTER COLUMN expires_at SET DEFAULT (now() + interval '12 months');
