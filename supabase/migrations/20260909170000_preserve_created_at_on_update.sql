-- ============================================================================
-- Migracija 20260909170000: Sprečavanje resetovanja created_at pri UPDATE-u
-- Garantuje na nivou baze da se created_at nikada ne menja na proizvodima i oglasima,
-- a automatski osvežava updated_at na oglasima.
-- ============================================================================

-- 1. Trigger za classified_ads: zadržava originalni created_at i osvežava updated_at
CREATE OR REPLACE FUNCTION public.preserve_classified_ad_created_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    NEW.created_at := OLD.created_at;
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_preserve_classified_ad_created_at ON public.classified_ads;
CREATE TRIGGER trg_preserve_classified_ad_created_at
BEFORE UPDATE ON public.classified_ads
FOR EACH ROW
EXECUTE FUNCTION public.preserve_classified_ad_created_at();

-- 2. Trigger za products: zadržava originalni created_at
CREATE OR REPLACE FUNCTION public.preserve_product_created_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    NEW.created_at := OLD.created_at;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_preserve_product_created_at ON public.products;
CREATE TRIGGER trg_preserve_product_created_at
BEFORE UPDATE ON public.products
FOR EACH ROW
EXECUTE FUNCTION public.preserve_product_created_at();
