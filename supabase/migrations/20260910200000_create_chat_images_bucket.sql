-- ==============================================================================
-- 20260910200000_create_chat_images_bucket.sql
-- Izdvajanje chat slika u namenski bucket `chat-images`
-- Omogućava nezavisne RLS politike, lakše upravljanje kvotama i bezbedno čišćenje.
-- ==============================================================================

-- 1. Kreiraj `chat-images` bucket ako ne postoji
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'chat-images',
  'chat-images',
  true,
  5242880, -- 5 MB
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- 2. Ukloni eventualne prethodne politike za chat-images
DROP POLICY IF EXISTS "Public read chat-images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated upload chat-images" ON storage.objects;
DROP POLICY IF EXISTS "Owner update chat-images" ON storage.objects;
DROP POLICY IF EXISTS "Owner delete chat-images" ON storage.objects;

-- 3. RLS politike za `chat-images`:
-- Čitanje je javno (slike u chatu se dele preko javnih URL-ova)
CREATE POLICY "Public read chat-images"
  ON storage.objects
  FOR SELECT
  USING (bucket_id = 'chat-images');

-- Upload je strogo ograničen: prvi segment putanje MORA biti ID ulogovanog korisnika
-- Primer: `<auth.uid()>/<conversationId>/<filename>.jpg`
CREATE POLICY "Authenticated upload chat-images"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'chat-images'
    AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
  );

-- Ažuriranje i brisanje dozvoljeno samo vlasniku foldera
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

CREATE POLICY "Owner delete chat-images"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'chat-images'
    AND (storage.foldername(name))[1] = (SELECT auth.uid())::text
  );
