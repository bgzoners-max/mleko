-- Praćenje / čuvanje malih oglasa (`♡ Prati`) sa automatskim brojačem `favorites_count`
-- 1. Dodaje kolonu `favorites_count` na `public.classified_ads`
-- 2. Kreira tabelu `public.classified_ad_favorites` sa RLS (InitPlan `(SELECT auth.uid())`)
-- 3. Održava `favorites_count` preko SECURITY DEFINER trigera uz `app.internal_ad_metrics_update`
-- 4. Štiti `favorites_count` u `protect_classified_ad_administrative_columns()`
-- 5. Ažurira `public.public_classified_ads` view sa kolonom `favorites_count`

-- ============================================================================
-- 1. Kolona `favorites_count` na `public.classified_ads`
-- ============================================================================
ALTER TABLE public.classified_ads
  ADD COLUMN IF NOT EXISTS favorites_count INTEGER NOT NULL DEFAULT 0
  CHECK (favorites_count >= 0);

-- ============================================================================
-- 2. Tabela `public.classified_ad_favorites` + RLS
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.classified_ad_favorites (
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  ad_id UUID NOT NULL REFERENCES public.classified_ads(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, ad_id)
);

CREATE INDEX IF NOT EXISTS idx_classified_ad_favorites_ad_id
  ON public.classified_ad_favorites (ad_id);

CREATE INDEX IF NOT EXISTS idx_classified_ad_favorites_user_created
  ON public.classified_ad_favorites (user_id, created_at DESC);

ALTER TABLE public.classified_ad_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.classified_ad_favorites FORCE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.classified_ad_favorites FROM PUBLIC, anon;
GRANT SELECT, INSERT, DELETE ON TABLE public.classified_ad_favorites TO authenticated;

DROP POLICY IF EXISTS "Users can view own classified favorites" ON public.classified_ad_favorites;
CREATE POLICY "Users can view own classified favorites"
  ON public.classified_ad_favorites
  FOR SELECT
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can insert own classified favorites" ON public.classified_ad_favorites;
CREATE POLICY "Users can insert own classified favorites"
  ON public.classified_ad_favorites
  FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can delete own classified favorites" ON public.classified_ad_favorites;
CREATE POLICY "Users can delete own classified favorites"
  ON public.classified_ad_favorites
  FOR DELETE
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

-- ============================================================================
-- 3. Zaštita `favorites_count` od klijentske manipulacije
-- ============================================================================
CREATE OR REPLACE FUNCTION public.protect_classified_ad_administrative_columns()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_is_caller_admin BOOLEAN := public.is_admin_or_service_role();
  v_internal_metrics BOOLEAN := COALESCE(current_setting('app.internal_ad_metrics_update', true), '') = 'true';
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NOT v_is_caller_admin THEN
      NEW.is_featured := false;
      NEW.featured_until := NULL;
      NEW.is_urgent := false;
      NEW.reports_count := 0;
      NEW.call_clicks_count := 0;
      NEW.shares_count := 0;
      NEW.views_count := 0;
      NEW.favorites_count := 0;
    END IF;
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' THEN
    NEW.user_id := OLD.user_id;

    IF NOT v_is_caller_admin THEN
      IF (NEW.is_featured IS DISTINCT FROM OLD.is_featured) OR
         (NEW.is_urgent IS DISTINCT FROM OLD.is_urgent) OR
         (NEW.featured_until IS DISTINCT FROM OLD.featured_until) THEN
        RAISE EXCEPTION USING
          ERRCODE = '42501',
          MESSAGE = 'Samo administrator može menjati status istaknutosti ili hitnosti oglasa.';
      END IF;

      IF NOT v_internal_metrics THEN
        NEW.reports_count := OLD.reports_count;
        NEW.call_clicks_count := OLD.call_clicks_count;
        NEW.shares_count := OLD.shares_count;
        NEW.views_count := OLD.views_count;
        NEW.favorites_count := OLD.favorites_count;
      END IF;
    END IF;
    RETURN NEW;
  END IF;

  RETURN NEW;
END;
$$;

-- ============================================================================
-- 4. Automatsko održavanje `favorites_count` kroz triger
-- ============================================================================
CREATE OR REPLACE FUNCTION public.maintain_classified_ad_favorites_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM set_config('app.internal_ad_metrics_update', 'true', true);
  IF TG_OP = 'INSERT' THEN
    UPDATE public.classified_ads
    SET favorites_count = favorites_count + 1
    WHERE id = NEW.ad_id;
    PERFORM set_config('app.internal_ad_metrics_update', 'false', true);
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.classified_ads
    SET favorites_count = GREATEST(0, favorites_count - 1)
    WHERE id = OLD.ad_id;
    PERFORM set_config('app.internal_ad_metrics_update', 'false', true);
    RETURN OLD;
  END IF;
  PERFORM set_config('app.internal_ad_metrics_update', 'false', true);
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_maintain_classified_ad_favorites_count ON public.classified_ad_favorites;
CREATE TRIGGER trg_maintain_classified_ad_favorites_count
  AFTER INSERT OR DELETE ON public.classified_ad_favorites
  FOR EACH ROW
  EXECUTE FUNCTION public.maintain_classified_ad_favorites_count();

-- ============================================================================
-- 5. Dopuna `public.public_classified_ads` view-a kolonom `favorites_count`
-- ============================================================================
CREATE OR REPLACE VIEW public.public_classified_ads AS
SELECT
  ca.id,
  ca.user_id,
  ca.title,
  ca.description,
  ca.price,
  ca.currency,
  ca.price_type,
  ca.category_id,
  ca.condition,
  ca.images,
  ca.city,
  CASE
    WHEN (
      (SELECT auth.uid()) = ca.user_id
      OR (SELECT public.is_admin())
    )
    THEN ca.phone
    ELSE NULL
  END AS phone,
  ca.phone_public,
  ca.status,
  ca.views_count,
  ca.created_at,
  ca.updated_at,
  ca.last_view_at,
  ca.attributes,
  ca.is_featured,
  ca.featured_until,
  ca.is_urgent,
  ca.reports_count,
  ca.call_clicks_count,
  ca.shares_count,
  ca.seller_type,
  ca.favorites_count
FROM public.classified_ads ca
WHERE ca.status = 'active'
   OR (SELECT auth.uid()) = ca.user_id
   OR (SELECT public.is_admin());

ALTER VIEW public.public_classified_ads SET (security_invoker = false);
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.public_classified_ads FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.public_classified_ads TO anon, authenticated;
