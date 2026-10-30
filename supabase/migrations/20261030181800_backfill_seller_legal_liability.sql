-- ============================================================================
-- Migracija: 20261030181800_backfill_seller_legal_liability.sql
-- Naziv: Popunjavanje legal_liability_accepted_at za sve postojeće i buduće prodavce
-- ============================================================================

-- 1. Backfill za sve postojeće prodavce (i sve korisnike koji su već objavili proizvode)
UPDATE public.profiles p
SET legal_liability_accepted_at = COALESCE(p.created_at, now())
WHERE p.legal_liability_accepted_at IS NULL
  AND (
    p.role = 'seller'
    OR p.farm_name IS NOT NULL
    OR EXISTS (SELECT 1 FROM public.products pr WHERE pr.seller_id = p.id)
  );

-- 2. Trigger koji garantuje da svaki prodavac uvek ima upisan legal_liability_accepted_at
CREATE OR REPLACE FUNCTION public.ensure_seller_legal_liability_accepted()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF (NEW.role = 'seller' OR NEW.farm_name IS NOT NULL)
     AND NEW.legal_liability_accepted_at IS NULL THEN
    NEW.legal_liability_accepted_at := COALESCE(NEW.created_at, now());
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_ensure_seller_legal_liability ON public.profiles;
CREATE TRIGGER trg_ensure_seller_legal_liability
  BEFORE INSERT OR UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.ensure_seller_legal_liability_accepted();
