-- Kreiranje Storage bucket-a za profiles, product-images i farm-gallery
-- Bez ovih bucket-a aplikacija vraća "Bucket not found" (404)

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('profiles', 'profiles', true, 5242880, ARRAY['image/jpeg', 'image/png']),
  ('product-images', 'product-images', true, 5242880, ARRAY['image/jpeg', 'image/png']),
  ('farm-gallery', 'farm-gallery', true, 5242880, ARRAY['image/jpeg', 'image/png'])
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;
