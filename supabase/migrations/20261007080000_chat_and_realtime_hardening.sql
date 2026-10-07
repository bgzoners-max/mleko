-- Migracija: 20261007080000_chat_and_realtime_hardening.sql
-- Učvršćivanje Chat i Realtime arhitekture:
-- 1. Zaštita od self-conversations (buyer_id <> seller_id)
-- 2. Scoped razgovori vezani za porudžbinu (order_id) bez preskakanja zaglavlja i prepisivanja
-- 3. Bounded server-side RPC za označavanje poruka pročitanim (mark_conversation_read)

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Zaštita: buyer_id <> seller_id
-- ─────────────────────────────────────────────────────────────────────────────

-- Očisti eventualne stare nevažeće self-razgovore (ako postoje iz testova)
DELETE FROM public.conversations WHERE buyer_id = seller_id;

ALTER TABLE public.conversations
  DROP CONSTRAINT IF EXISTS chk_conversations_distinct_parties;

ALTER TABLE public.conversations
  ADD CONSTRAINT chk_conversations_distinct_parties
  CHECK (buyer_id <> seller_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Scoped indeksi razgovora (order_id, product_id, ad_id, general)
-- ─────────────────────────────────────────────────────────────────────────────

-- Ukloni stare indekse
DROP INDEX IF EXISTS public.idx_conversations_buyer_seller_product;
DROP INDEX IF EXISTS public.idx_conversations_buyer_seller_ad;
DROP INDEX IF EXISTS public.idx_conversations_buyer_seller_general;
DROP INDEX IF EXISTS public.idx_conversations_order;

-- Razreši eventualne duple zapise za isti order_id pre kreiranja UNIQUE indeksa
DO $$
BEGIN
  IF EXISTS (
    SELECT order_id FROM public.conversations
    WHERE order_id IS NOT NULL
    GROUP BY order_id HAVING COUNT(*) > 1
  ) THEN
    -- Preusmeri poruke sa starijih duplikata na najnoviji razgovor
    UPDATE public.messages m
    SET conversation_id = target.id
    FROM (
      SELECT DISTINCT ON (c.order_id) c.id, c.order_id
      FROM public.conversations c
      WHERE c.order_id IS NOT NULL
      ORDER BY c.order_id, c.updated_at DESC, c.id DESC
    ) target
    JOIN public.conversations dup ON dup.order_id = target.order_id
    WHERE m.conversation_id = dup.id AND dup.id <> target.id;

    -- Obriši višak duplikata
    DELETE FROM public.conversations dup
    USING (
      SELECT DISTINCT ON (c.order_id) c.id, c.order_id
      FROM public.conversations c
      WHERE c.order_id IS NOT NULL
      ORDER BY c.order_id, c.updated_at DESC, c.id DESC
    ) keeper
    WHERE dup.order_id = keeper.order_id AND dup.id <> keeper.id;
  END IF;
END $$;

-- a) Zaseban razgovor vezan za konkretnu porudžbinu (jedinstven po order_id)
CREATE UNIQUE INDEX IF NOT EXISTS idx_conversations_order
  ON public.conversations (order_id)
  WHERE order_id IS NOT NULL;

-- b) Razgovor vezan za proizvod (samo opšti upiti pre poručivanja, gde order_id IS NULL)
CREATE UNIQUE INDEX IF NOT EXISTS idx_conversations_buyer_seller_product
  ON public.conversations (buyer_id, seller_id, product_id)
  WHERE product_id IS NOT NULL AND order_id IS NULL;

-- c) Razgovor vezan za mali oglas (gde order_id IS NULL)
CREATE UNIQUE INDEX IF NOT EXISTS idx_conversations_buyer_seller_ad
  ON public.conversations (buyer_id, seller_id, ad_id)
  WHERE ad_id IS NOT NULL AND order_id IS NULL;

-- d) Opšti razgovor bez predmeta i bez porudžbine
CREATE UNIQUE INDEX IF NOT EXISTS idx_conversations_buyer_seller_general
  ON public.conversations (buyer_id, seller_id)
  WHERE product_id IS NULL AND ad_id IS NULL AND order_id IS NULL;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Server-side RPC za označavanje pročitanih poruka sa limitom
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.mark_conversation_read(
  p_conversation_id UUID,
  p_limit INT DEFAULT 200
)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_updated INT := 0;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Provera da je trenutno prijavljeni korisnik učesnik u razgovoru
  IF NOT EXISTS (
    SELECT 1 FROM public.conversations
    WHERE id = p_conversation_id
      AND (buyer_id = v_user_id OR seller_id = v_user_id)
  ) THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  -- Bounded set-based update poruka koje nisu poslate od strane trenutnog korisnika
  WITH to_update AS (
    SELECT id
    FROM public.messages
    WHERE conversation_id = p_conversation_id
      AND sender_id <> v_user_id
      AND read_at IS NULL
    ORDER BY created_at DESC
    LIMIT GREATEST(1, LEAST(p_limit, 1000))
  )
  UPDATE public.messages m
  SET read_at = NOW()
  FROM to_update
  WHERE m.id = to_update.id;

  GET DIAGNOSTICS v_updated = ROW_COUNT;
  RETURN v_updated;
END;
$$;

GRANT EXECUTE ON FUNCTION public.mark_conversation_read(UUID, INT) TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Ažuriranje funkcije get_conversations_for_user (prioritet order_id)
-- ─────────────────────────────────────────────────────────────────────────────

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
        (SELECT oi.product_name FROM public.order_items oi WHERE oi.order_id = c.order_id LIMIT 1),
        (SELECT o.product_name FROM public.orders o WHERE o.id = c.order_id),
        p.name,
        ad.title
      )                                                                    AS item_title,
      COALESCE(
        p.image_urls[1],
        ad.images[1]
      )                                                                    AS item_image_url,
      COALESCE(p.price_per_kg, ad.price)                                   AS item_price,
      COALESCE(p.unit_type, ad.currency)                                   AS item_unit,
      CASE
        WHEN c.order_id IS NOT NULL THEN 'order'
        WHEN c.product_id IS NOT NULL THEN 'product'
        WHEN c.ad_id IS NOT NULL THEN 'ad'
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
