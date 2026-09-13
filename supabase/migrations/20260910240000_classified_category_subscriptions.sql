-- ============================================================================
-- Migracija 20260910240000: Praćenje kategorija, sačuvane pretrage i obaveštenja
-- 
-- 1. Dodaje kolonu `classified_ad_id` u `notifications` tabelu radi deep-linkovanja.
-- 2. Kreira tabelu `classified_category_subscriptions` sa RLS politikama.
-- 3. Kreira SECURITY DEFINER funkciju i triger na `classified_ads` koji automatski
--    šalje obaveštenja i push pretplatnicima kada se pojavi odgovarajući oglas.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Proširenje notifications tabele za povezivanje sa oglasima
-- ----------------------------------------------------------------------------
ALTER TABLE public.notifications
ADD COLUMN IF NOT EXISTS classified_ad_id UUID REFERENCES public.classified_ads(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_notifications_classified_ad_id
ON public.notifications(classified_ad_id)
WHERE classified_ad_id IS NOT NULL;

-- ----------------------------------------------------------------------------
-- 2. Tabela za pretplate na kategorije i sačuvane pretrage
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.classified_category_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  category_id TEXT NOT NULL REFERENCES public.classified_categories(id) ON DELETE CASCADE,
  search_query TEXT,
  max_price NUMERIC,
  currency TEXT DEFAULT 'EUR',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_classified_subscription UNIQUE (user_id, category_id, search_query)
);

CREATE INDEX IF NOT EXISTS idx_classified_subscriptions_user 
  ON public.classified_category_subscriptions(user_id);

CREATE INDEX IF NOT EXISTS idx_classified_subscriptions_category 
  ON public.classified_category_subscriptions(category_id);

ALTER TABLE public.classified_category_subscriptions ENABLE ROW LEVEL SECURITY;

-- RLS Politike
DROP POLICY IF EXISTS "Users can view own subscriptions" ON public.classified_category_subscriptions;
CREATE POLICY "Users can view own subscriptions"
  ON public.classified_category_subscriptions FOR SELECT
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can create own subscriptions" ON public.classified_category_subscriptions;
CREATE POLICY "Users can create own subscriptions"
  ON public.classified_category_subscriptions FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can delete own subscriptions" ON public.classified_category_subscriptions;
CREATE POLICY "Users can delete own subscriptions"
  ON public.classified_category_subscriptions FOR DELETE
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

-- ----------------------------------------------------------------------------
-- 3. Triger funkcija za obaveštavanje pretplatnika o novim oglasima
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.notify_classified_subscribers_on_ad_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  cat_record RECORD;
  sub_record RECORD;
  ad_price_str TEXT;
  notif_title TEXT;
  notif_body TEXT;
BEGIN
  -- Obaveštenja šaljemo samo za aktivne nove oglase
  IF NEW.status <> 'active' THEN
    RETURN NEW;
  END IF;

  -- Naziv kategorije
  SELECT name INTO cat_record
  FROM public.classified_categories
  WHERE id = NEW.category_id
  LIMIT 1;

  IF NEW.price > 0 THEN
    ad_price_str := trim(to_char(NEW.price, '999,999,999')) || ' ' || NEW.currency;
  ELSE
    ad_price_str := 'Cena po dogovoru';
  END IF;

  notif_title := 'Novi oglas: ' || substring(NEW.title from 1 for 60);
  notif_body := 'U kategoriji ' || COALESCE(cat_record.name, 'Oglasi') || ' objavljen je oglas (' || ad_price_str || ').';

  -- Pronalazimo sve pretplatnike:
  -- 1. Korisnik ne sme biti autor oglasa
  -- 2. Pretplata se poklapa sa kategorijom oglasa ili njenim roditeljem
  -- 3. Ako je zadat search_query, proveravamo ILIKE u naslovu ili opisu
  -- 4. Ako je zadat max_price, cena oglasa ne sme biti veća
  FOR sub_record IN
    SELECT DISTINCT s.user_id
    FROM public.classified_category_subscriptions s
    WHERE s.user_id <> NEW.user_id
      AND (
        s.category_id = NEW.category_id
        OR EXISTS (
          SELECT 1 FROM public.classified_categories c
          WHERE c.id = NEW.category_id AND c.parent_id = s.category_id
        )
      )
      AND (
        s.search_query IS NULL 
        OR length(trim(s.search_query)) = 0 
        OR NEW.title ILIKE '%' || trim(s.search_query) || '%'
        OR NEW.description ILIKE '%' || trim(s.search_query) || '%'
      )
      AND (
        s.max_price IS NULL 
        OR s.max_price <= 0 
        OR (NEW.price > 0 AND NEW.price <= s.max_price)
      )
  LOOP
    -- Ubacivanje u notifications (triger invoke_send_push na notifications tabeli automatski šalje push)
    INSERT INTO public.notifications (
      user_id,
      type,
      title,
      body,
      classified_ad_id
    ) VALUES (
      sub_record.user_id,
      'classified_saved_search',
      notif_title,
      notif_body,
      NEW.id
    );
  END LOOP;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_classified_ad_notify_subscribers ON public.classified_ads;
CREATE TRIGGER trg_classified_ad_notify_subscribers
  AFTER INSERT ON public.classified_ads
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_classified_subscribers_on_ad_insert();
