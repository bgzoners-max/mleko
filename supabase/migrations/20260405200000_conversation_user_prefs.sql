-- Conversation user preferences: favorites & hidden per user per conversation
-- Fixes: set_conversation_user_prefs RPC and is_favorite/hidden missing from DB

CREATE TABLE IF NOT EXISTS public.conversation_user_prefs (
  conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  is_favorite     BOOLEAN NOT NULL DEFAULT false,
  hidden          BOOLEAN NOT NULL DEFAULT false,
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (conversation_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_conv_user_prefs_user
  ON public.conversation_user_prefs(user_id);

ALTER TABLE public.conversation_user_prefs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage own conversation prefs" ON public.conversation_user_prefs;
CREATE POLICY "Users manage own conversation prefs"
  ON public.conversation_user_prefs FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ─── RPC: set_conversation_user_prefs ────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.set_conversation_user_prefs(
  p_conversation_id UUID,
  p_is_favorite     BOOLEAN DEFAULT NULL,
  p_hidden          BOOLEAN DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Verify caller participates in the conversation
  IF NOT EXISTS (
    SELECT 1 FROM public.conversations
    WHERE id = p_conversation_id
      AND (buyer_id = auth.uid() OR seller_id = auth.uid())
  ) THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  INSERT INTO public.conversation_user_prefs (conversation_id, user_id, is_favorite, hidden, updated_at)
  VALUES (
    p_conversation_id,
    auth.uid(),
    COALESCE(p_is_favorite, false),
    COALESCE(p_hidden, false),
    NOW()
  )
  ON CONFLICT (conversation_id, user_id) DO UPDATE SET
    is_favorite = COALESCE(p_is_favorite, conversation_user_prefs.is_favorite),
    hidden      = COALESCE(p_hidden,      conversation_user_prefs.hidden),
    updated_at  = NOW();
END;
$$;

GRANT EXECUTE ON FUNCTION public.set_conversation_user_prefs(UUID, BOOLEAN, BOOLEAN) TO authenticated;

-- ─── Update get_conversations_for_user to include is_favorite and hidden ─────

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
         FROM messages m2
        WHERE m2.conversation_id = c.id
          AND m2.sender_id      != p_user_id
          AND m2.read_at         IS NULL)                                  AS unread_count,
      COALESCE(cup.is_favorite, false)                                     AS is_favorite,
      COALESCE(cup.hidden, false)                                          AS hidden
    FROM conversations c
    JOIN profiles pb ON pb.id = c.buyer_id
    JOIN profiles ps ON ps.id = c.seller_id
    LEFT JOIN conversation_user_prefs cup
      ON cup.conversation_id = c.id AND cup.user_id = p_user_id
    LEFT JOIN LATERAL (
      SELECT body, created_at
        FROM messages
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
