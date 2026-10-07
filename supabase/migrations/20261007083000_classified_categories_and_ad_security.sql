-- ============================================================================
-- Migracija: classified_categories hijerarhijsko računanje i classified_ads RLS zaštita
-- 1. Kanonski rekurzivni view za kategorije (nasleđivanje is_condition_applicable)
-- 2. Sinhronizacija classified_categories tabele
-- 3. Striktna zaštita administrativnih/promotivnih polja na classified_ads
-- ============================================================================

-- 1. Rekurzivni view koji garantuje da ako je predak is_condition_applicable = false,
--    onda je i svako dete u podstablu automatski is_condition_applicable = false.
CREATE OR REPLACE VIEW public.v_classified_categories AS
WITH RECURSIVE category_tree AS (
    -- Korenske kategorije (parent_id IS NULL)
    SELECT 
        id,
        name,
        icon_name,
        parent_id,
        sort_order,
        is_condition_applicable,
        created_at
    FROM public.classified_categories
    WHERE parent_id IS NULL
    
    UNION ALL
    
    -- Podkategorije (nasleđuju boolean AND sa roditeljem)
    SELECT 
        c.id,
        c.name,
        c.icon_name,
        c.parent_id,
        c.sort_order,
        (ct.is_condition_applicable AND c.is_condition_applicable) AS is_condition_applicable,
        c.created_at
    FROM public.classified_categories c
    INNER JOIN category_tree ct ON c.parent_id = ct.id
)
SELECT * FROM category_tree;

GRANT SELECT ON public.v_classified_categories TO anon, authenticated, service_role;

-- 2. Propagacija i sinhronizacija na samoj tabeli classified_categories
WITH RECURSIVE non_applicable_hierarchy AS (
    SELECT id
    FROM public.classified_categories
    WHERE is_condition_applicable = false
    UNION ALL
    SELECT c.id
    FROM public.classified_categories c
    INNER JOIN non_applicable_hierarchy p ON c.parent_id = p.id
)
UPDATE public.classified_categories
SET is_condition_applicable = false
WHERE id IN (SELECT id FROM non_applicable_hierarchy)
  AND is_condition_applicable = true;

-- 3. Funkcija i trigger za zaštitu promotivnih kolona (is_featured, is_urgent, featured_until)
--    Ako korisnik nije admin a pokuša da izmeni ove kolone, baza direktno podiže 42501 grešku.
CREATE OR REPLACE FUNCTION public.protect_classified_ad_administrative_columns()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_is_caller_admin BOOLEAN := public.is_admin_or_service_role();
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Novi oglas koji postavlja običan korisnik ne može imati promotivne statuse
    IF NOT v_is_caller_admin THEN
      NEW.is_featured := false;
      NEW.featured_until := NULL;
      NEW.is_urgent := false;
      NEW.reports_count := 0;
      NEW.call_clicks_count := 0;
      NEW.views_count := 0;
    END IF;
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' THEN
    -- Spreči otimanje vlasništva oglasa
    NEW.user_id := OLD.user_id;

    -- Samo administrator sme da menja is_featured, is_urgent ili featured_until
    IF NOT v_is_caller_admin THEN
      IF (NEW.is_featured IS DISTINCT FROM OLD.is_featured) OR
         (NEW.is_urgent IS DISTINCT FROM OLD.is_urgent) OR
         (NEW.featured_until IS DISTINCT FROM OLD.featured_until) THEN
        RAISE EXCEPTION USING
          ERRCODE = '42501',
          MESSAGE = 'Samo administrator može menjati status istaknutosti ili hitnosti oglasa.';
      END IF;

      -- Spreči vlasnika da lažira brojače pregleda ili resetuje prijave
      NEW.reports_count := OLD.reports_count;
      NEW.call_clicks_count := OLD.call_clicks_count;
      NEW.views_count := OLD.views_count;
    END IF;
    RETURN NEW;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_classified_ad_administrative_columns ON public.classified_ads;
CREATE TRIGGER trg_protect_classified_ad_administrative_columns
  BEFORE INSERT OR UPDATE ON public.classified_ads
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_classified_ad_administrative_columns();
