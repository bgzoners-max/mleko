-- Chat enhancements: typing indicator, message reactions, seller response stats

-- 1) Typing state per conversation/user
CREATE TABLE IF NOT EXISTS public.conversation_typing (
  conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  is_typing BOOLEAN NOT NULL DEFAULT false,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (conversation_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_conversation_typing_updated_at
  ON public.conversation_typing(updated_at DESC);

ALTER TABLE public.conversation_typing ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Participants see typing state" ON public.conversation_typing;
CREATE POLICY "Participants see typing state"
  ON public.conversation_typing FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = conversation_id
        AND (c.buyer_id = auth.uid() OR c.seller_id = auth.uid())
    )
  );

DROP POLICY IF EXISTS "Participants upsert own typing state" ON public.conversation_typing;
CREATE POLICY "Participants upsert own typing state"
  ON public.conversation_typing FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = conversation_id
        AND (c.buyer_id = auth.uid() OR c.seller_id = auth.uid())
    )
  );

DROP POLICY IF EXISTS "Participants update own typing state" ON public.conversation_typing;
CREATE POLICY "Participants update own typing state"
  ON public.conversation_typing FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 2) Message reactions
CREATE TABLE IF NOT EXISTS public.message_reactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  message_id UUID NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reaction TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(message_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_message_reactions_conversation
  ON public.message_reactions(conversation_id);
CREATE INDEX IF NOT EXISTS idx_message_reactions_message
  ON public.message_reactions(message_id);

ALTER TABLE public.message_reactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Participants see reactions" ON public.message_reactions;
CREATE POLICY "Participants see reactions"
  ON public.message_reactions FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = conversation_id
        AND (c.buyer_id = auth.uid() OR c.seller_id = auth.uid())
    )
  );

DROP POLICY IF EXISTS "Participants manage own reactions" ON public.message_reactions;
CREATE POLICY "Participants manage own reactions"
  ON public.message_reactions FOR ALL
  TO authenticated
  USING (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = conversation_id
        AND (c.buyer_id = auth.uid() OR c.seller_id = auth.uid())
    )
  )
  WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = conversation_id
        AND (c.buyer_id = auth.uid() OR c.seller_id = auth.uid())
    )
  );

-- Keep updated_at fresh on reaction updates.
CREATE OR REPLACE FUNCTION public.touch_message_reaction_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_touch_message_reaction_updated_at ON public.message_reactions;
CREATE TRIGGER trg_touch_message_reaction_updated_at
  BEFORE UPDATE ON public.message_reactions
  FOR EACH ROW
  EXECUTE FUNCTION public.touch_message_reaction_updated_at();

-- 3) Seller response time stats (in minutes)
-- Measures first seller reply after buyer message in each conversation thread sequence.
CREATE OR REPLACE FUNCTION public.get_seller_response_time_stats(p_seller_id UUID)
RETURNS TABLE (
  sample_count INTEGER,
  avg_response_minutes NUMERIC,
  median_response_minutes NUMERIC,
  last_response_minutes NUMERIC
)
LANGUAGE sql
STABLE
AS $$
WITH seller_conversations AS (
  SELECT id
  FROM public.conversations
  WHERE seller_id = p_seller_id
),
buyer_messages AS (
  SELECT
    m.id,
    m.conversation_id,
    m.created_at
  FROM public.messages m
  JOIN public.conversations c ON c.id = m.conversation_id
  WHERE c.seller_id = p_seller_id
    AND m.sender_id = c.buyer_id
),
first_replies AS (
  SELECT
    bm.id AS buyer_message_id,
    bm.created_at AS buyer_created_at,
    (
      SELECT m2.created_at
      FROM public.messages m2
      JOIN public.conversations c2 ON c2.id = m2.conversation_id
      WHERE m2.conversation_id = bm.conversation_id
        AND m2.created_at > bm.created_at
        AND m2.sender_id = p_seller_id
      ORDER BY m2.created_at ASC
      LIMIT 1
    ) AS seller_reply_at
  FROM buyer_messages bm
),
durations AS (
  SELECT
    EXTRACT(EPOCH FROM (seller_reply_at - buyer_created_at)) / 60.0 AS minutes,
    seller_reply_at
  FROM first_replies
  WHERE seller_reply_at IS NOT NULL
)
SELECT
  COUNT(*)::INTEGER AS sample_count,
  ROUND(AVG(minutes)::NUMERIC, 1) AS avg_response_minutes,
  ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY minutes)::NUMERIC, 1) AS median_response_minutes,
  ROUND((SELECT minutes::NUMERIC FROM durations ORDER BY seller_reply_at DESC LIMIT 1), 1) AS last_response_minutes
FROM durations;
$$;
