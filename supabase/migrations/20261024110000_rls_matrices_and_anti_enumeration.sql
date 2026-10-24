-- ============================================================================
-- Migracija: 20261024110000_rls_matrices_and_anti_enumeration.sql
-- Naziv: RLS matrice, FORCE RLS na svim tabelama i anti-enumeration zaštita
--
-- 1. FORCE ROW LEVEL SECURITY (SEC-2.1):
--    Aktivira FORCE ROW LEVEL SECURITY na svim tabelama koje sadrže privatne
--    i osetljive podatke korisnika (garancija da se RLS primenjuje i za table ownere).
--
-- 2. ENUMERATION ATTACK ZAŠTITA (SEC-2.3):
--    - Zamena "Profiles are viewable by all users" (USING true) na public.profiles
--      striktnom polisom: anonimni i obični korisnici vide samo prodavce (katalog/mapa)
--      i sopstveni profil, dok su kupci skriveni osim za partnere u porudžbini/četu.
--    - Ažuriranje public_profiles view-a sa istim bezbednosnim filterom.
--    - Namenska RPC funkcija get_public_profile(p_user_id) sa restriktivnim poljima.
--
-- 3. SECURITY DEFINER OČVRŠĆAVANJE RPC FUNKCIJA (SEC-2.3):
--    - get_seller_inbox: dodata provera da pozivalac mora biti p_seller_id ili admin.
--    - get_conversation_info_with_profile: proverava da je pozivalac učesnik razgovora.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. FORCE ROW LEVEL SECURITY na svim tabelama sa privatnim podacima
-- ----------------------------------------------------------------------------
ALTER TABLE public.user_push_tokens FORCE ROW LEVEL SECURITY;
ALTER TABLE public.conversations FORCE ROW LEVEL SECURITY;
ALTER TABLE public.messages FORCE ROW LEVEL SECURITY;
ALTER TABLE public.conversation_typing FORCE ROW LEVEL SECURITY;
ALTER TABLE public.message_reactions FORCE ROW LEVEL SECURITY;
ALTER TABLE public.conversation_user_prefs FORCE ROW LEVEL SECURITY;
ALTER TABLE public.profiles FORCE ROW LEVEL SECURITY;
ALTER TABLE public.orders FORCE ROW LEVEL SECURITY;
ALTER TABLE public.order_items FORCE ROW LEVEL SECURITY;
ALTER TABLE public.order_status_audit_logs FORCE ROW LEVEL SECURITY;
ALTER TABLE public.notifications FORCE ROW LEVEL SECURITY;
ALTER TABLE public.support_tickets FORCE ROW LEVEL SECURITY;
ALTER TABLE public.support_ticket_messages FORCE ROW LEVEL SECURITY;
ALTER TABLE public.favorites FORCE ROW LEVEL SECURITY;
ALTER TABLE public.favorite_sellers FORCE ROW LEVEL SECURITY;
ALTER TABLE public.classified_ad_reports FORCE ROW LEVEL SECURITY;
ALTER TABLE public.classified_category_subscriptions FORCE ROW LEVEL SECURITY;
ALTER TABLE public.classified_ad_views FORCE ROW LEVEL SECURITY;
ALTER TABLE public.reviews FORCE ROW LEVEL SECURITY;
ALTER TABLE public.buyer_reviews FORCE ROW LEVEL SECURITY;
ALTER TABLE public.seller_delivery_points FORCE ROW LEVEL SECURITY;
ALTER TABLE public.seller_delivery_slots FORCE ROW LEVEL SECURITY;
ALTER TABLE public.product_delivery_points FORCE ROW LEVEL SECURITY;
ALTER TABLE public.push_delivery_logs FORCE ROW LEVEL SECURITY;


-- ----------------------------------------------------------------------------
-- 2. PROFILES: Anti-enumeration zaštita na tabeli public.profiles
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Profiles are viewable by all users" ON public.profiles;
DROP POLICY IF EXISTS "Profiles are viewable by authenticated users" ON public.profiles;
DROP POLICY IF EXISTS "Public can view sellers and order participants" ON public.profiles;

CREATE POLICY "Public can view sellers and order participants"
ON public.profiles
FOR SELECT
USING (
  -- Korisnik vidi sopstveni profil
  (SELECT auth.uid()) = id
  -- Administrator vidi sve profile
  OR (SELECT public.is_admin())
  -- Prodavci su javni radi prikaza na mapi i profilu prodavnice
  OR (role = 'seller' OR farm_name IS NOT NULL)
  -- Kupac je vidljiv prodavcu samo ako postoji porudžbina između njih
  OR EXISTS (
    SELECT 1 FROM public.orders o
    WHERE o.buyer_id = public.profiles.id AND o.seller_id = (SELECT auth.uid())
  )
  -- Korisnik je vidljiv drugom korisniku ako imaju otvoren razgovor
  OR EXISTS (
    SELECT 1 FROM public.conversations c
    WHERE (c.buyer_id = public.profiles.id AND c.seller_id = (SELECT auth.uid()))
       OR (c.seller_id = public.profiles.id AND c.buyer_id = (SELECT auth.uid()))
  )
);


-- ----------------------------------------------------------------------------
-- 3. PUBLIC_PROFILES: Ažuriranje view-a sa anti-enumeration filterom
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.public_profiles AS
SELECT
  p.id,
  CASE WHEN ((SELECT auth.uid()) = p.id OR (SELECT public.is_admin())) THEN p.email ELSE NULL END AS email,
  CASE WHEN (p.phone_public OR (SELECT auth.uid()) = p.id OR (SELECT public.is_admin())) THEN p.phone ELSE NULL END AS phone,
  p.display_name,
  p.city,
  p.postal_code,
  p.role,
  p.is_guest,
  p.farm_name,
  p.location,
  p.profile_image_url,
  p.phone_public,
  p.is_verified,
  p.seller_story,
  p.farm_gallery_urls,
  p.seller_tags,
  p.seller_quick_replies,
  p.is_admin,
  p.lat,
  p.lng,
  p.created_at,
  CASE WHEN ((SELECT auth.uid()) = p.id OR (SELECT public.is_admin())) THEN p.address ELSE NULL END AS address
FROM public.profiles p
WHERE (
  (SELECT auth.uid()) = p.id
  OR (SELECT public.is_admin())
  OR (p.role = 'seller' OR p.farm_name IS NOT NULL)
  OR EXISTS (
    SELECT 1 FROM public.orders o
    WHERE o.buyer_id = p.id AND o.seller_id = (SELECT auth.uid())
  )
  OR EXISTS (
    SELECT 1 FROM public.conversations c
    WHERE (c.buyer_id = p.id AND c.seller_id = (SELECT auth.uid()))
       OR (c.seller_id = p.id AND c.buyer_id = (SELECT auth.uid()))
  )
);

ALTER VIEW public.public_profiles SET (security_invoker = false);
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.public_profiles FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.public_profiles TO anon, authenticated;


-- ----------------------------------------------------------------------------
-- 4. RPC: Bezbedan dohvat javnog profila (bez curenja adrese, telefona i emaila)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_public_profile(p_user_id UUID)
RETURNS JSONB
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT jsonb_build_object(
    'id', p.id,
    'display_name', p.display_name,
    'farm_name', p.farm_name,
    'profile_image_url', p.profile_image_url,
    'role', p.role,
    'is_verified', p.is_verified,
    'city', p.city
  )
  FROM public.profiles p
  WHERE p.id = p_user_id
    AND (
      p.role = 'seller'
      OR p.farm_name IS NOT NULL
      OR (SELECT auth.uid()) = p.id
      OR (SELECT public.is_admin())
    );
$$;

REVOKE ALL ON FUNCTION public.get_public_profile(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_public_profile(UUID) TO anon, authenticated;


-- ----------------------------------------------------------------------------
-- 5. OČVRŠĆAVANJE RPC FUNKCIJA: get_seller_inbox i get_conversation_info_with_profile
-- ----------------------------------------------------------------------------

-- 5.1 get_seller_inbox sa striktnom autorizacijom prodavca
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
  -- Verifikacija autorizacije: pozivalac mora biti p_seller_id ili administrator
  auth_check AS (
    SELECT (p_seller_id = (SELECT auth.uid()) OR (SELECT public.is_admin())) AS is_allowed
  ),
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
      (SELECT COUNT(*)::int FROM public.messages m2
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
    CROSS JOIN auth_check ac
    JOIN public.profiles pb ON pb.id = c.buyer_id
    LEFT JOIN public.products p ON p.id = c.product_id
    LEFT JOIN public.classified_ads ad ON ad.id = c.ad_id
    LEFT JOIN public.orders o ON o.id = c.order_id
    LEFT JOIN LATERAL (
      SELECT
        CASE WHEN (SELECT COUNT(*) FROM public.order_items WHERE order_id = c.order_id) > 1
             THEN (SELECT COUNT(*)::text FROM public.order_items WHERE order_id = c.order_id) || ' proizvoda'
             ELSE (SELECT product_name FROM public.order_items WHERE order_id = c.order_id LIMIT 1)
        END AS product_name,
        (SELECT quantity_kg FROM public.order_items WHERE order_id = c.order_id LIMIT 1) AS quantity_kg,
        (SELECT unit_type FROM public.order_items WHERE order_id = c.order_id LIMIT 1) AS unit_type
    ) oi_first ON c.order_id IS NOT NULL AND o.product_id IS NULL
    LEFT JOIN LATERAL (
      SELECT body FROM public.messages
      WHERE conversation_id = c.id
      ORDER BY created_at DESC
      LIMIT 1
    ) lm ON true
    WHERE ac.is_allowed = true
      AND c.seller_id = p_seller_id
  ),
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
    CROSS JOIN auth_check ac
    JOIN public.profiles pb ON pb.id = o.buyer_id
    LEFT JOIN LATERAL (
      SELECT
        CASE WHEN (SELECT COUNT(*) FROM public.order_items WHERE order_id = o.id) > 1
             THEN (SELECT COUNT(*)::text FROM public.order_items WHERE order_id = o.id) || ' proizvoda'
             ELSE (SELECT product_name FROM public.order_items WHERE order_id = o.id LIMIT 1)
        END AS product_name,
        (SELECT quantity_kg FROM public.order_items WHERE order_id = o.id LIMIT 1) AS quantity_kg,
        (SELECT unit_type FROM public.order_items WHERE order_id = o.id LIMIT 1) AS unit_type
    ) oi_first ON o.product_id IS NULL
    WHERE ac.is_allowed = true
      AND o.seller_id = p_seller_id
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


-- 5.2 get_conversation_info_with_profile sa proverom učesnika
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
SECURITY DEFINER
SET search_path = public
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
  WHERE c.id::text = p_conversation_id
    AND (
      c.buyer_id = (SELECT auth.uid())
      OR c.seller_id = (SELECT auth.uid())
      OR (SELECT public.is_admin())
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_conversation_info_with_profile(TEXT) TO authenticated;
