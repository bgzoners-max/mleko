-- ==============================================================================
-- 20260917170000_secure_chat_images_and_storage_privacy.sql
-- R3-A: Zatvaranje bezbednosnog propusta privatnosti chat slika
--
-- 1. Postavlja bucket `chat-images` na `public = false`.
-- 2. Uklanja blanket public SELECT politiku i omogućava pristup isključivo
--    učesnicima razgovora (buyer_id ili seller_id) i administratorima.
-- 3. Sprečava neautorizovan upload u tuđe razgovore (konverzija u proveru učešća).
-- 4. Uklanja mogućnost uploada u legacy `chat/` folder javnog `product-images` bucketa.
-- ==============================================================================

-- 1. Učini `chat-images` bucket privatnim
UPDATE storage.buckets
SET public = false
WHERE id = 'chat-images';

-- 2. Ukloni nesigurnu blanket SELECT politiku
DROP POLICY IF EXISTS "Public read chat-images" ON storage.objects;
DROP POLICY IF EXISTS "Participants read chat-images" ON storage.objects;

-- 3. Dozvoli SELECT samo učesnicima razgovora ili administratorima
-- Putanja objekta: `<userId>/<conversationId>/<filename>`
-- (storage.foldername(name))[2] predstavlja conversation_id
CREATE POLICY "Participants read chat-images"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'chat-images'
    AND (
      EXISTS (
        SELECT 1 FROM public.conversations c
        WHERE c.id::text = (storage.foldername(name))[2]
          AND (c.buyer_id = (SELECT auth.uid()) OR c.seller_id = (SELECT auth.uid()))
      )
      OR public.is_admin()
    )
  );

-- 4. Ograniči INSERT: ulogovani korisnik sme da uploaduje samo u svoj folder i samo u razgovor gde je učesnik
DROP POLICY IF EXISTS "Authenticated upload chat-images" ON storage.objects;
CREATE POLICY "Authenticated upload chat-images"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'chat-images'
    AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
    AND EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id::text = (storage.foldername(name))[2]
        AND (c.buyer_id = (SELECT auth.uid()) OR c.seller_id = (SELECT auth.uid()))
    )
  );

-- 5. Ograniči UPDATE i DELETE na vlasnika fajla (ili admina za delete)
DROP POLICY IF EXISTS "Owner update chat-images" ON storage.objects;
CREATE POLICY "Owner update chat-images"
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'chat-images'
    AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
  )
  WITH CHECK (
    bucket_id = 'chat-images'
    AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
  );

DROP POLICY IF EXISTS "Owner delete chat-images" ON storage.objects;
CREATE POLICY "Owner delete chat-images"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'chat-images'
    AND (
      (storage.foldername(name))[1] = (SELECT auth.uid())::text
      OR public.is_admin()
    )
  );

-- 6. Spreči upload chat slika u javni `product-images` bucket
DROP POLICY IF EXISTS "Users upload own product images" ON storage.objects;
CREATE POLICY "Users upload own product images"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'product-images'
    AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
    AND (storage.foldername(name))[1] != 'chat'
  );

DROP POLICY IF EXISTS "Users update own product images" ON storage.objects;
CREATE POLICY "Users update own product images"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'product-images'
    AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
    AND (storage.foldername(name))[1] != 'chat'
  );

DROP POLICY IF EXISTS "Users delete own product images" ON storage.objects;
CREATE POLICY "Users delete own product images"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'product-images'
    AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
    AND (storage.foldername(name))[1] != 'chat'
  );
