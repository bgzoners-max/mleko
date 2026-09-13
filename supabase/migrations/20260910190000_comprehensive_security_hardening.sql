-- ============================================================================
-- Migration: 20260910190000_comprehensive_security_hardening.sql
-- Description:
--   1. Storage Security (P0 & P1):
--      - Remove overly permissive storage policies on product-images.
--      - Enforce owner prefix (auth.uid()) on uploads.
--      - Add FOR DELETE and FOR UPDATE policies for product-images, farm-gallery, profiles.
--   2. Chat Conversations Security (P1):
--      - Replace FOR ALL policy on conversations with granular SELECT, INSERT, UPDATE.
--      - Eliminate client-side DELETE on conversations to prevent cascade deletion of messages.
--   3. Chat Messages Security (P1):
--      - Prevent modifying body, sender_id, created_at, conversation_id (enforce_message_update_restrictions).
--      - Restrict messages UPDATE strictly to read_at by recipients.
--      - Add FOR DELETE policy allowing only sender to delete own messages.
--   4. Order Status Transition Role Security (P1-P2):
--      - Enforce role validation in enforce_order_status_transition().
--      - Buyer cannot accept, reject, ship, or cancel as seller.
--      - Seller cannot mark as delivered (only buyer confirms receipt).
--      - Lock buyer_id and seller_id from being mutated via UPDATE.
--      - Support both 'arhivirano' and 'archived' in check constraint.
--   5. Classified Ad Views Race Condition & Cleanup (P2):
--      - Make increment_classified_ad_views fully atomic (eliminates race condition).
--      - Add probabilistic periodic cleanup of classified_ad_views (>14 days).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. STORAGE POLICIES HARDENING (P0 & P1)
-- ----------------------------------------------------------------------------

-- Ukloni sve stare/nesigurne politike sa storage.objects
DROP POLICY IF EXISTS "Allow product image uploads 16wiy3a_0" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated upload product-images" ON storage.objects;
DROP POLICY IF EXISTS "Public read product-images" ON storage.objects;
DROP POLICY IF EXISTS "Public read profiles" ON storage.objects;
DROP POLICY IF EXISTS "Public read farm-gallery" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated upload profiles" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated update profiles" ON storage.objects;
DROP POLICY IF EXISTS "Sellers upload own farm gallery" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own product images" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own product images" ON storage.objects;
DROP POLICY IF EXISTS "Sellers can delete own farm gallery images" ON storage.objects;
DROP POLICY IF EXISTS "Sellers can update own farm gallery" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own profile image" ON storage.objects;

-- 1.1 Javni SELECT za sve public buckete
CREATE POLICY "Public read product-images"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'product-images');

CREATE POLICY "Public read profiles"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'profiles');

CREATE POLICY "Public read farm-gallery"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'farm-gallery');

-- 1.2 Profiles (vlasnik uređuje samo svoj userId.jpg)
CREATE POLICY "Users upload own profile image"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'profiles'
    AND name = ((select auth.uid())::text || '.jpg')
  );

CREATE POLICY "Users update own profile image"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'profiles'
    AND name = ((select auth.uid())::text || '.jpg')
  );

CREATE POLICY "Users delete own profile image"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'profiles'
    AND name = ((select auth.uid())::text || '.jpg')
  );

-- 1.3 Farm Gallery (prodavac postavlja u folder userId/...)
CREATE POLICY "Sellers upload own farm gallery"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'farm-gallery'
    AND (storage.foldername(name))[1] = (select auth.uid())::text
  );

CREATE POLICY "Sellers update own farm gallery"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'farm-gallery'
    AND (storage.foldername(name))[1] = (select auth.uid())::text
  );

CREATE POLICY "Sellers delete own farm gallery"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'farm-gallery'
    AND (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- 1.4 Product Images & Chat Images (P0 & P1)
-- Dozvoljava upload samo u sopstveni folder:
-- - Slike proizvoda: <userId>/<name>
-- - Slike u chatu: <userId>/chat/<convId>/<name>
-- - Backward compatibility za postojeće: chat/<convId>/<userId>/<name>
CREATE POLICY "Users upload own product images"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'product-images'
    AND (
      (storage.foldername(name))[1] = (select auth.uid())::text
      OR (
        (storage.foldername(name))[1] = 'chat'
        AND (storage.foldername(name))[3] = (select auth.uid())::text
      )
    )
  );

CREATE POLICY "Users update own product images"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'product-images'
    AND (
      (storage.foldername(name))[1] = (select auth.uid())::text
      OR (
        (storage.foldername(name))[1] = 'chat'
        AND (storage.foldername(name))[3] = (select auth.uid())::text
      )
    )
  );

CREATE POLICY "Users delete own product images"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'product-images'
    AND (
      (storage.foldername(name))[1] = (select auth.uid())::text
      OR (
        (storage.foldername(name))[1] = 'chat'
        AND (storage.foldername(name))[3] = (select auth.uid())::text
      )
    )
  );

-- ----------------------------------------------------------------------------
-- 2. CONVERSATIONS RLS (P1)
-- ----------------------------------------------------------------------------

-- Ukloni politiku FOR ALL koja je dozvoljavala DELETE i kaskadno brisanje poruka
DROP POLICY IF EXISTS "Users see own conversations" ON public.conversations;
DROP POLICY IF EXISTS "Users insert own conversations" ON public.conversations;
DROP POLICY IF EXISTS "Users update own conversations" ON public.conversations;

CREATE POLICY "Users see own conversations"
  ON public.conversations FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = buyer_id OR (select auth.uid()) = seller_id);

CREATE POLICY "Users insert own conversations"
  ON public.conversations FOR INSERT
  TO authenticated
  WITH CHECK ((select auth.uid()) = buyer_id OR (select auth.uid()) = seller_id);

CREATE POLICY "Users update own conversations"
  ON public.conversations FOR UPDATE
  TO authenticated
  USING ((select auth.uid()) = buyer_id OR (select auth.uid()) = seller_id)
  WITH CHECK ((select auth.uid()) = buyer_id OR (select auth.uid()) = seller_id);

-- Napomena: Nema FOR DELETE politike – klijenti ne mogu obrisati razgovor i kaskadno uništiti poruke.

-- ----------------------------------------------------------------------------
-- 3. MESSAGES UPDATE RESTRICTIONS (P1)
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.enforce_message_update_restrictions()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Strogo zabranjeno menjanje ID-ja, konverzacije, pošiljaoca, teksta i datuma kreiranja
  IF NEW.id <> OLD.id 
     OR NEW.conversation_id <> OLD.conversation_id 
     OR NEW.sender_id <> OLD.sender_id 
     OR NEW.body <> OLD.body 
     OR NEW.created_at <> OLD.created_at THEN
    RAISE EXCEPTION USING
      ERRCODE = '42501',
      MESSAGE = 'Nije dozvoljena izmena poruke ili njenih metapodataka. Dozvoljeno je samo azuriranje read_at.';
  END IF;

  -- Pošiljalac ne sme sam sebi da označi poruku kao pročitanu
  IF OLD.sender_id = (select auth.uid()) AND NEW.read_at IS DISTINCT FROM OLD.read_at THEN
    RAISE EXCEPTION USING
      ERRCODE = '42501',
      MESSAGE = 'Posiljalac ne moze oznaciti sopstvenu poruku kao procitanu.';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_message_update_restrictions ON public.messages;
CREATE TRIGGER trg_enforce_message_update_restrictions
  BEFORE UPDATE ON public.messages
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_message_update_restrictions();

-- Ažuriraj RLS politiku za UPDATE poruka
DROP POLICY IF EXISTS "Participants update read_at" ON public.messages;
CREATE POLICY "Participants update read_at"
  ON public.messages FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = conversation_id AND (c.buyer_id = (select auth.uid()) OR c.seller_id = (select auth.uid()))
    )
  )
  WITH CHECK (
    sender_id <> (select auth.uid())
  );

-- Dozvoli pošiljaocu da obriše sopstvenu poruku ako aplikacija pozove deleteMessage
DROP POLICY IF EXISTS "Senders can delete own messages" ON public.messages;
CREATE POLICY "Senders can delete own messages"
  ON public.messages FOR DELETE
  TO authenticated
  USING (sender_id = (select auth.uid()));

-- ----------------------------------------------------------------------------
-- 4. ORDER STATUS TRANSITION ROLE CHECK (P1-P2)
-- ----------------------------------------------------------------------------

-- Omogući i 'arhivirano' i 'archived' u constraint-u radi potpune kompatibilnosti
ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS orders_status_check;
ALTER TABLE public.orders ADD CONSTRAINT orders_status_check 
  CHECK (status IN ('sent', 'accepted', 'shipped', 'rejected', 'delivered', 'cancelled_by_seller', 'arhivirano', 'archived'));

CREATE OR REPLACE FUNCTION public.enforce_order_status_transition()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_allowed BOOLEAN := false;
  v_uid UUID := auth.uid();
  v_is_seller BOOLEAN := false;
  v_is_buyer BOOLEAN := false;
BEGIN
  -- 1. Zabrana izmene ključnih učesnika porudžbine kroz UPDATE
  IF NEW.buyer_id <> OLD.buyer_id OR NEW.seller_id <> OLD.seller_id THEN
    RAISE EXCEPTION USING
      ERRCODE = '42501',
      MESSAGE = 'Nije dozvoljeno menjati kupca ili prodavca porudzbine.';
  END IF;

  IF NEW.status IS NOT DISTINCT FROM OLD.status THEN
    RETURN NEW;
  END IF;

  -- 2. Identifikacija uloge
  IF v_uid IS NOT NULL THEN
    v_is_seller := (v_uid = OLD.seller_id);
    v_is_buyer := (v_uid = OLD.buyer_id);

    IF NOT (v_is_seller OR v_is_buyer) THEN
      RAISE EXCEPTION USING
        ERRCODE = '42501',
        MESSAGE = 'Samo kupac ili prodavac ove porudzbine mogu menjati njen status.',
        DETAIL = format('uid=%s, seller_id=%s, buyer_id=%s', v_uid, OLD.seller_id, OLD.buyer_id);
    END IF;
  ELSE
    -- Sistemski / service_role poziv (cron, background sync)
    v_is_seller := true;
    v_is_buyer := true;
  END IF;

  -- 3. Stroga kontrola dozvoljenih tranzicija po ulogama
  v_allowed := CASE OLD.status
    WHEN 'sent' THEN 
      -- Samo prodavac sme da prihvati ili odbije porudžbinu
      v_is_seller AND NEW.status IN ('accepted', 'rejected')
    WHEN 'accepted' THEN 
      -- Samo prodavac sme da pošalje ili otkaže
      v_is_seller AND NEW.status IN ('shipped', 'cancelled_by_seller')
    WHEN 'shipped' THEN 
      -- Samo kupac potvrđuje isporuku; prodavac može da otkaže u izuzetnim okolnostima
      (v_is_buyer AND NEW.status = 'delivered') OR
      (v_is_seller AND NEW.status = 'cancelled_by_seller')
    WHEN 'rejected' THEN 
      -- I kupac i prodavac mogu arhivirati odbijenu porudžbinu
      (v_is_seller OR v_is_buyer) AND NEW.status IN ('arhivirano', 'archived')
    WHEN 'cancelled_by_seller' THEN 
      -- I kupac i prodavac mogu arhivirati otkazanu porudžbinu
      (v_is_seller OR v_is_buyer) AND NEW.status IN ('arhivirano', 'archived')
    WHEN 'delivered' THEN 
      -- I kupac i prodavac mogu arhivirati isporučenu porudžbinu
      (v_is_seller OR v_is_buyer) AND NEW.status IN ('arhivirano', 'archived')
    WHEN 'arhivirano' THEN false
    WHEN 'archived' THEN false
    ELSE false
  END;

  IF NOT v_allowed THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'Nedozvoljena tranzicija statusa porudzbine za vasu ulogu.',
      DETAIL = format('order_id=%s, old_status=%s, new_status=%s, is_seller=%s, is_buyer=%s',
                      NEW.id, OLD.status, NEW.status, v_is_seller, v_is_buyer),
      HINT = 'Prodavac prihvata/salje/otkazuje; kupac potvrdjuje prijem (shipped->delivered).';
  END IF;

  RETURN NEW;
END;
$$;

-- ----------------------------------------------------------------------------
-- 5. ATOMIC CLASSIFIED AD VIEWS & CLEANUP (P2)
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.increment_classified_ad_views(
  ad_id UUID,
  p_viewer_id TEXT DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user UUID := auth.uid();
  v_owner UUID;
  v_status TEXT;
  v_headers JSONB;
  v_ua TEXT;
  v_ip TEXT;
  v_viewer_hash TEXT;
  v_inserted_count INT := 0;
BEGIN
  -- 1. Pronađi vlasnika i status oglasa
  SELECT user_id, status
    INTO v_owner, v_status
  FROM public.classified_ads
  WHERE id = ad_id;

  IF NOT FOUND THEN
    RETURN;
  END IF;

  -- 2. Samo aktivni oglasi dobijaju preglede
  IF v_status <> 'active' THEN
    RETURN;
  END IF;

  -- 3. Vlasnik oglasa ne povećava sopstveni brojač pregleda
  IF v_user IS NOT NULL AND v_user = v_owner THEN
    RETURN;
  END IF;

  -- 4. Detekcija User-Agent-a i blokada botova/crawlere/scrapers/social previewera
  BEGIN
    v_headers := current_setting('request.headers', true)::jsonb;
    v_ua := lower(COALESCE(v_headers->>'user-agent', ''));
  EXCEPTION WHEN OTHERS THEN
    v_headers := '{}'::jsonb;
    v_ua := '';
  END;

  IF v_ua ~* '(bot|crawl|spider|slurp|curl|wget|python|scrapy|aiohttp|httpx|headless|chrome-lighthouse|lighthouse|preview|scraper|facebookexternalhit|whatsapp|telegrambot|discordbot|slackbot|archive\.org|semrush|ahrefs|bingbot|googlebot|yandex|bytespider)' THEN
    RETURN;
  END IF;

  IF p_viewer_id IS NOT NULL AND p_viewer_id ~* '^(bot|spider|crawler)' THEN
    RETURN;
  END IF;

  -- 5. Odredi identifikator posetioca (viewer_hash)
  IF v_user IS NOT NULL THEN
    v_viewer_hash := 'usr:' || v_user::text;
  ELSIF p_viewer_id IS NOT NULL AND length(trim(p_viewer_id)) > 0 THEN
    v_viewer_hash := 'dev:' || md5(trim(p_viewer_id));
  ELSE
    v_ip := COALESCE(
      v_headers->>'cf-connecting-ip',
      v_headers->>'x-real-ip',
      split_part(v_headers->>'x-forwarded-for', ',', 1),
      'unknown'
    );
    v_viewer_hash := 'ip_ua:' || md5(v_ip || ':' || v_ua);
  END IF;

  -- 6. Atomska deduplikacija: ubaci novi zapis ili osveži samo ako je stariji od 24h
  -- Koristi se atomski INSERT ... ON CONFLICT DO UPDATE WHERE ... RETURNING
  WITH inserted_or_updated AS (
    INSERT INTO public.classified_ad_views (ad_id, viewer_hash, last_viewed_at)
    VALUES (increment_classified_ad_views.ad_id, v_viewer_hash, now())
    ON CONFLICT (ad_id, viewer_hash)
    DO UPDATE SET last_viewed_at = now()
    WHERE classified_ad_views.last_viewed_at <= now() - INTERVAL '24 hours'
    RETURNING ad_id
  )
  SELECT count(*) INTO v_inserted_count FROM inserted_or_updated;

  -- 7. Inkrementiraj stvarni brojač pregleda samo ako je prozor od 24h istekao
  IF v_inserted_count > 0 THEN
    UPDATE public.classified_ads
    SET views_count = views_count + 1,
        last_view_at = now()
    WHERE id = increment_classified_ad_views.ad_id;
  END IF;

  -- 8. Periodično čišćenje starih unosa (1% šanse pri svakom pozivu za sprečavanje neograničenog rasta tabele)
  IF random() < 0.01 THEN
    DELETE FROM public.classified_ad_views
    WHERE last_viewed_at < now() - INTERVAL '14 days';
  END IF;
END;
$$;
