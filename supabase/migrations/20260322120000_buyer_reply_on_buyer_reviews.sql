-- Odgovor kupca na recenziju prodavca (jedan odgovor, izmena do 24h kao kod add_seller_reply)

ALTER TABLE public.buyer_reviews
  ADD COLUMN IF NOT EXISTS buyer_reply    TEXT,
  ADD COLUMN IF NOT EXISTS buyer_reply_at TIMESTAMPTZ;

CREATE OR REPLACE FUNCTION public.add_buyer_reply(
  p_review_id UUID,
  p_reply     TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_buyer_id      UUID;
  v_has_reply     BOOLEAN;
  v_reply_at      TIMESTAMPTZ;
BEGIN
  IF p_reply IS NULL OR trim(p_reply) = '' THEN
    RAISE EXCEPTION 'empty_reply';
  END IF;

  SELECT buyer_id,
         buyer_reply IS NOT NULL AND trim(buyer_reply) <> '',
         buyer_reply_at
  INTO   v_buyer_id, v_has_reply, v_reply_at
  FROM   public.buyer_reviews
  WHERE  id = p_review_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'review_not_found';
  END IF;

  IF v_buyer_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'not_authorized';
  END IF;

  IF v_has_reply AND v_reply_at IS NOT NULL
     AND NOW() - v_reply_at > INTERVAL '24 hours'
  THEN
    RAISE EXCEPTION 'reply_not_editable_after_24h';
  END IF;

  UPDATE public.buyer_reviews
  SET
    buyer_reply    = trim(p_reply),
    buyer_reply_at = COALESCE(buyer_reply_at, NOW())
  WHERE id = p_review_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.add_buyer_reply(UUID, TEXT) TO authenticated;
