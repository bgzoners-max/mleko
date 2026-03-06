-- Automatska arhivacija i data retention za porudžbine
-- 30 dana: status -> arhivirano, archived_at = now()
-- 12 meseci: trajno brisanje porudžbine i order_items (CASCADE)

-- Kolone na orders
ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS archived_at TIMESTAMPTZ;
ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ;

-- Status 'arhivirano' u dozvoljene vrednosti
ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS orders_status_check;
ALTER TABLE public.orders ADD CONSTRAINT orders_status_check
  CHECK (status IN ('sent', 'accepted', 'rejected', 'delivered', 'cancelled_by_seller', 'arhivirano'));

-- Funkcija: arhiviraj stare (30 dana) i obriši istekle (12 meseci)
-- U bazi je status = 'sent' (ne 'poslato')
CREATE OR REPLACE FUNCTION public.archive_and_expire_orders()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- 1) Arhiviraj samo porudžbine u statusu 'sent' starije od 30 dana
  UPDATE public.orders
  SET status = 'arhivirano', archived_at = now()
  WHERE status = 'sent'
    AND created_at <= now() - interval '30 days';

  -- 2) Trajno obriši porudžbine sa expires_at <= now() (order_items se brišu CASCADE)
  DELETE FROM public.orders
  WHERE expires_at IS NOT NULL AND expires_at <= now();
END;
$$;

-- Zakazani posao (pg_cron): svaki dan u 02:00 UTC
-- Unschedule samo ako job postoji (inače pg_cron baca grešku)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'archive-and-expire-orders') THEN
      PERFORM cron.unschedule('archive-and-expire-orders');
    END IF;
  END IF;
EXCEPTION WHEN undefined_object THEN NULL;
END
$$;
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    PERFORM cron.schedule(
      'archive-and-expire-orders',
      '0 2 * * *',
      'SELECT public.archive_and_expire_orders()'
    );
  END IF;
EXCEPTION WHEN undefined_object THEN NULL;
END
$$;
