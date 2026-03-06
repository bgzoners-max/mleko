-- Odgovor prodavca na recenziju
-- seller_reply_at pamti kada je prvi put odgovoreno (nepromenjivo nakon snimanja)

ALTER TABLE public.reviews
  ADD COLUMN IF NOT EXISTS seller_reply    TEXT,
  ADD COLUMN IF NOT EXISTS seller_reply_at TIMESTAMPTZ;

-- RPC funkcija — jedino mesto gde se vrši izmena odgovora.
-- SECURITY DEFINER + ručne provere umesto UPDATE policy-a, jer trebamo
-- atomičnu validaciju "nije prošlo 24h od prvog odgovora".
CREATE OR REPLACE FUNCTION public.add_seller_reply(
  p_review_id UUID,
  p_reply     TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_seller_id      UUID;
  v_has_reply      BOOLEAN;
  v_reply_at       TIMESTAMPTZ;
BEGIN
  SELECT seller_id,
         seller_reply IS NOT NULL,
         seller_reply_at
  INTO   v_seller_id, v_has_reply, v_reply_at
  FROM   public.reviews
  WHERE  id = p_review_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'review_not_found';
  END IF;

  -- Samo vlasnik profila prodavca može odgovoriti
  IF v_seller_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'not_authorized';
  END IF;

  -- Izmena odgovora dozvoljena samo unutar 24h od prvog odgovora
  IF v_has_reply AND v_reply_at IS NOT NULL
     AND NOW() - v_reply_at > INTERVAL '24 hours'
  THEN
    RAISE EXCEPTION 'reply_not_editable_after_24h';
  END IF;

  UPDATE public.reviews
  SET
    seller_reply    = p_reply,
    -- Čuva originalni timestamp pri izmeni (ne pomiče rok od 24h)
    seller_reply_at = COALESCE(seller_reply_at, NOW())
  WHERE id = p_review_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.add_seller_reply(UUID, TEXT) TO authenticated;

-- Eksplicitno zabrani direktan UPDATE na seller_reply kolone svima
-- (sve izmene moraju ići kroz RPC funkciju)
DROP POLICY IF EXISTS "Seller can update own reply" ON public.reviews;
