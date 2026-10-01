-- Migracija: 20261001110000_scoped_item_conversations.sql
-- Omogućava zasebne razgovore za svaki proizvod ili predmet (mali oglas)
-- između istog para kupac–prodavac.

-- 1. Uklanjanje starog ograničenja 1-na-1 razgovora
ALTER TABLE public.conversations
  DROP CONSTRAINT IF EXISTS conversations_buyer_id_seller_id_key;

-- 2. Dodavanje referenci na konkretan proizvod ili oglas
ALTER TABLE public.conversations
  ADD COLUMN IF NOT EXISTS product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS ad_id UUID REFERENCES public.classified_ads(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_conversations_product_id ON public.conversations(product_id);
CREATE INDEX IF NOT EXISTS idx_conversations_ad_id ON public.conversations(ad_id);

-- 3. Retroaktivno popunjavanje product_id za postojeće razgovore vezane za porudžbinu
UPDATE public.conversations c
SET product_id = COALESCE(
  o.product_id,
  (SELECT oi.product_id FROM public.order_items oi WHERE oi.order_id = c.order_id LIMIT 1)
)
FROM public.orders o
WHERE c.order_id = o.id
  AND c.product_id IS NULL;

-- 4. Parcijalni jedinstveni indeksi:
-- a) Za konkretan proizvod: jedan čet po paru kupac-prodavac i proizvodu
CREATE UNIQUE INDEX IF NOT EXISTS idx_conversations_buyer_seller_product
  ON public.conversations (buyer_id, seller_id, product_id)
  WHERE product_id IS NOT NULL;

-- b) Za konkretan oglas: jedan čet po paru kupac-prodavac i oglasu
CREATE UNIQUE INDEX IF NOT EXISTS idx_conversations_buyer_seller_ad
  ON public.conversations (buyer_id, seller_id, ad_id)
  WHERE ad_id IS NOT NULL;

-- c) Za opšti/nasleđeni razgovor bez označenog predmeta
CREATE UNIQUE INDEX IF NOT EXISTS idx_conversations_buyer_seller_general
  ON public.conversations (buyer_id, seller_id)
  WHERE product_id IS NULL AND ad_id IS NULL;

-- 5. Ažuriranje funkcije get_conversations_for_user da vraća podatke o predmetu/proizvodu
CREATE OR REPLACE FUNCTION public.get_conversations_for_user(p_user_id UUID)
RETURNS JSONB
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    jsonb_agg(row_to_json(t)::jsonb ORDER BY (row_to_json(t) ->> 'updated_at') DESC),
    '[]'::jsonb
  )
  FROM (
    SELECT
      c.id,
      c.buyer_id,
      c.seller_id,
      c.order_id,
      c.product_id,
      c.ad_id,
      c.created_at,
      c.updated_at,
      COALESCE(
        CASE WHEN c.buyer_id = p_user_id
             THEN COALESCE(ps.farm_name, ps.display_name)
             ELSE COALESCE(pb.farm_name, pb.display_name)
        END,
        'Korisnik'
      )                                                                    AS other_party_name,
      CASE WHEN c.buyer_id = p_user_id
           THEN ps.profile_image_url
           ELSE pb.profile_image_url
      END                                                                  AS other_party_image_url,
      lm.body                                                              AS last_message_body,
      lm.created_at                                                        AS last_message_at,
      (SELECT COUNT(*)::int
         FROM public.messages m2
        WHERE m2.conversation_id = c.id
          AND m2.sender_id      != p_user_id
          AND m2.read_at         IS NULL)                                  AS unread_count,
      COALESCE(cup.is_favorite, false)                                     AS is_favorite,
      COALESCE(cup.hidden, false)                                          AS hidden,
      COALESCE(
        p.name,
        ad.title,
        (SELECT oi.product_name FROM public.order_items oi WHERE oi.order_id = c.order_id LIMIT 1),
        (SELECT o.product_name FROM public.orders o WHERE o.id = c.order_id)
      )                                                                    AS item_title,
      COALESCE(
        p.image_urls[1],
        ad.images[1]
      )                                                                    AS item_image_url,
      COALESCE(p.price_per_kg, ad.price)                                   AS item_price,
      COALESCE(p.unit_type, ad.currency)                                   AS item_unit,
      CASE
        WHEN c.product_id IS NOT NULL THEN 'product'
        WHEN c.ad_id IS NOT NULL THEN 'ad'
        WHEN c.order_id IS NOT NULL THEN 'order'
        ELSE NULL
      END                                                                  AS item_type
    FROM public.conversations c
    JOIN public.profiles pb ON pb.id = c.buyer_id
    JOIN public.profiles ps ON ps.id = c.seller_id
    LEFT JOIN public.products p ON p.id = c.product_id
    LEFT JOIN public.classified_ads ad ON ad.id = c.ad_id
    LEFT JOIN public.conversation_user_prefs cup
      ON cup.conversation_id = c.id AND cup.user_id = p_user_id
    LEFT JOIN LATERAL (
      SELECT body, created_at
        FROM public.messages
       WHERE conversation_id = c.id
       ORDER BY created_at DESC
       LIMIT 1
    ) lm ON true
    WHERE (c.buyer_id = p_user_id OR c.seller_id = p_user_id)
      AND p_user_id = auth.uid()
    ORDER BY c.updated_at DESC
    LIMIT 50
  ) t;
$$;

GRANT EXECUTE ON FUNCTION public.get_conversations_for_user(UUID) TO authenticated;

-- 6. Ažuriranje get_conversation_info_with_profile
DROP FUNCTION IF EXISTS public.get_conversation_info_with_profile(TEXT);
CREATE OR REPLACE FUNCTION public.get_conversation_info_with_profile(
  p_conversation_id TEXT
)
RETURNS TABLE (
  id TEXT,
  buyer_id TEXT,
  seller_id TEXT,
  order_id TEXT,
  buyer_name TEXT,
  seller_name TEXT,
  product_id TEXT,
  ad_id TEXT,
  item_title TEXT,
  item_image_url TEXT,
  item_price NUMERIC,
  item_unit TEXT,
  item_type TEXT
)
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id::text,
    c.buyer_id::text,
    c.seller_id::text,
    c.order_id::text,
    COALESCE(pb.farm_name, pb.display_name, 'Kupac')::text AS buyer_name,
    COALESCE(ps.farm_name, ps.display_name, 'Prodavac')::text AS seller_name,
    c.product_id::text,
    c.ad_id::text,
    COALESCE(
      p.name,
      ad.title,
      (SELECT oi.product_name FROM public.order_items oi WHERE oi.order_id = c.order_id LIMIT 1),
      (SELECT o.product_name FROM public.orders o WHERE o.id = c.order_id)
    )::text AS item_title,
    COALESCE(p.image_urls[1], ad.images[1])::text AS item_image_url,
    COALESCE(p.price_per_kg, ad.price)::numeric AS item_price,
    COALESCE(p.unit_type, ad.currency)::text AS item_unit,
    CASE
      WHEN c.product_id IS NOT NULL THEN 'product'
      WHEN c.ad_id IS NOT NULL THEN 'ad'
      WHEN c.order_id IS NOT NULL THEN 'order'
      ELSE NULL
    END::text AS item_type
  FROM public.conversations c
  LEFT JOIN public.profiles pb ON c.buyer_id = pb.id
  LEFT JOIN public.profiles ps ON c.seller_id = ps.id
  LEFT JOIN public.products p ON c.product_id = p.id
  LEFT JOIN public.classified_ads ad ON c.ad_id = ad.id
  WHERE c.id::text = p_conversation_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_conversation_info_with_profile(TEXT) TO authenticated;

-- 7. Ažuriranje funkcije get_seller_inbox sa podrškom za naziv i sliku proizvoda/oglasa
CREATE OR REPLACE FUNCTION public.get_seller_inbox(
  p_seller_id UUID,
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0
)
RETURNS JSONB
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH
  -- Konverzacije sa JOIN-ovima
  conv_rows AS (
    SELECT
      'conversation'::text AS item_type,
      c.updated_at AS sort_date,
      c.id AS conversation_id,
      c.order_id AS order_id,
      c.buyer_id AS buyer_id,
      c.product_id AS product_id,
      c.ad_id AS ad_id,
      COALESCE(pb.farm_name, pb.display_name, 'Kupac') AS other_party_name,
      pb.profile_image_url AS other_party_image_url,
      lm.body AS last_message_body,
      (SELECT COUNT(*)::int FROM messages m2
       WHERE m2.conversation_id = c.id
         AND m2.sender_id != p_seller_id
         AND m2.read_at IS NULL) AS unread_count,
      COALESCE(p.name, ad.title, o.product_name, oi_first.product_name) AS product_name,
      COALESCE(o.quantity_kg::float8, oi_first.quantity_kg::float8) AS quantity_kg,
      COALESCE(p.unit_type, ad.currency, o.unit_type, oi_first.unit_type) AS unit_type,
      o.status AS status,
      CASE o.status
        WHEN 'sent' THEN 'Poslato'
        WHEN 'accepted' THEN 'Prihvaćeno'
        WHEN 'rejected' THEN 'Odbijeno'
        WHEN 'delivered' THEN 'Isporučeno'
        WHEN 'cancelled_by_seller' THEN 'Otkazano'
        WHEN 'arhivirano' THEN 'Arhivirano'
        ELSE 'Poslato'
      END AS status_label,
      o.buyer_phone AS buyer_phone,
      o.note AS note,
      o.buyer_city AS buyer_city,
      o.buyer_address AS buyer_address
    FROM public.conversations c
    JOIN public.profiles pb ON pb.id = c.buyer_id
    LEFT JOIN public.products p ON p.id = c.product_id
    LEFT JOIN public.classified_ads ad ON ad.id = c.ad_id
    LEFT JOIN public.orders o ON o.id = c.order_id
    LEFT JOIN LATERAL (
      SELECT
        CASE WHEN (SELECT COUNT(*) FROM order_items WHERE order_id = c.order_id) > 1
             THEN (SELECT COUNT(*)::text FROM order_items WHERE order_id = c.order_id) || ' proizvoda'
             ELSE (SELECT product_name FROM order_items WHERE order_id = c.order_id LIMIT 1)
        END AS product_name,
        (SELECT quantity_kg FROM order_items WHERE order_id = c.order_id LIMIT 1) AS quantity_kg,
        (SELECT unit_type FROM order_items WHERE order_id = c.order_id LIMIT 1) AS unit_type
    ) oi_first ON c.order_id IS NOT NULL AND o.product_id IS NULL
    LEFT JOIN LATERAL (
      SELECT body FROM messages
      WHERE conversation_id = c.id
      ORDER BY created_at DESC
      LIMIT 1
    ) lm ON true
    WHERE c.seller_id = p_seller_id
  ),
  -- Porudžbine bez konverzacije
  order_ids_with_conv AS (
    SELECT DISTINCT order_id FROM public.conversations
    WHERE seller_id = p_seller_id AND order_id IS NOT NULL
  ),
  order_rows AS (
    SELECT
      'order'::text AS item_type,
      o.created_at AS sort_date,
      o.id AS order_id,
      NULL::uuid AS conversation_id,
      o.buyer_id AS buyer_id,
      COALESCE(o.product_id, (SELECT oi.product_id FROM public.order_items oi WHERE oi.order_id = o.id LIMIT 1)) AS product_id,
      NULL::uuid AS ad_id,
      COALESCE(pb.farm_name, pb.display_name, 'Kupac') AS other_party_name,
      pb.profile_image_url AS other_party_image_url,
      NULL::text AS last_message_body,
      0 AS unread_count,
      COALESCE(o.product_name, oi_first.product_name) AS product_name,
      COALESCE(o.quantity_kg::float8, oi_first.quantity_kg::float8) AS quantity_kg,
      COALESCE(o.unit_type, oi_first.unit_type) AS unit_type,
      o.status AS status,
      CASE o.status
        WHEN 'sent' THEN 'Poslato'
        WHEN 'accepted' THEN 'Prihvaćeno'
        WHEN 'rejected' THEN 'Odbijeno'
        WHEN 'delivered' THEN 'Isporučeno'
        WHEN 'cancelled_by_seller' THEN 'Otkazano'
        WHEN 'arhivirano' THEN 'Arhivirano'
        ELSE 'Poslato'
      END AS status_label,
      o.buyer_phone AS buyer_phone,
      o.note AS note,
      o.buyer_city AS buyer_city,
      o.buyer_address AS buyer_address
    FROM public.orders o
    JOIN public.profiles pb ON pb.id = o.buyer_id
    LEFT JOIN LATERAL (
      SELECT
        CASE WHEN (SELECT COUNT(*) FROM order_items WHERE order_id = o.id) > 1
             THEN (SELECT COUNT(*)::text FROM order_items WHERE order_id = o.id) || ' proizvoda'
             ELSE (SELECT product_name FROM order_items WHERE order_id = o.id LIMIT 1)
        END AS product_name,
        (SELECT quantity_kg FROM order_items WHERE order_id = o.id LIMIT 1) AS quantity_kg,
        (SELECT unit_type FROM order_items WHERE order_id = o.id LIMIT 1) AS unit_type
    ) oi_first ON o.product_id IS NULL
    WHERE o.seller_id = p_seller_id
      AND o.id NOT IN (SELECT order_id FROM order_ids_with_conv WHERE order_id IS NOT NULL)
  ),
  combined AS (
    SELECT * FROM conv_rows
    UNION ALL
    SELECT * FROM order_rows
  )
  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'type', item_type,
        'sort_date', to_char(sort_date, 'YYYY-MM-DD"T"HH24:MI:SS.MS'),
        'order_id', order_id,
        'conversation_id', conversation_id,
        'buyer_id', buyer_id,
        'product_id', product_id,
        'ad_id', ad_id,
        'other_party_name', other_party_name,
        'other_party_image_url', other_party_image_url,
        'product_name', product_name,
        'quantity_kg', quantity_kg,
        'unit_type', unit_type,
        'status', status,
        'last_message_body', last_message_body,
        'unread_count', unread_count,
        'status_label', status_label,
        'buyer_phone', buyer_phone,
        'note', note,
        'buyer_city', buyer_city,
        'buyer_address', buyer_address
      )
      ORDER BY sort_date DESC
    ),
    '[]'::jsonb
  )
  FROM (
    SELECT * FROM combined
    LIMIT p_limit OFFSET p_offset
  ) AS limited_combined;
$$;

GRANT EXECUTE ON FUNCTION public.get_seller_inbox(UUID, INT, INT) TO authenticated;

-- 8. Ažuriranje funkcije notify_new_message sa nazivom predmeta
CREATE OR REPLACE FUNCTION public.notify_new_message()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_buyer_id UUID;
  v_seller_id UUID;
  v_product_id UUID;
  v_ad_id UUID;
  v_recipient_id UUID;
  v_sender_name TEXT;
  v_item_name TEXT;
  v_title TEXT := 'Nova poruka 💬';
BEGIN
  SELECT buyer_id, seller_id, product_id, ad_id
  INTO v_buyer_id, v_seller_id, v_product_id, v_ad_id
  FROM public.conversations WHERE id = NEW.conversation_id;

  IF NEW.sender_id = v_buyer_id THEN
    v_recipient_id := v_seller_id;
  ELSE
    v_recipient_id := v_buyer_id;
  END IF;

  IF v_recipient_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT COALESCE(NULLIF(btrim(farm_name), ''), NULLIF(btrim(display_name), ''), 'Korisnik')
  INTO v_sender_name
  FROM public.profiles WHERE id = NEW.sender_id;

  IF v_product_id IS NOT NULL THEN
    SELECT name INTO v_item_name FROM public.products WHERE id = v_product_id;
  ELSIF v_ad_id IS NOT NULL THEN
    SELECT title INTO v_item_name FROM public.classified_ads WHERE id = v_ad_id;
  END IF;

  IF v_item_name IS NOT NULL AND length(btrim(v_item_name)) > 0 THEN
    v_title := 'Poruka: ' || LEFT(v_item_name, 35) || ' 💬';
  END IF;

  INSERT INTO public.notifications (user_id, type, title, body, conversation_id)
  VALUES (
    v_recipient_id,
    'new_message',
    v_title,
    COALESCE(v_sender_name, 'Korisnik') || ': ' || LEFT(NEW.body, 80),
    NEW.conversation_id
  )
  ON CONFLICT DO NOTHING;

  RETURN NEW;
END;
$$;
