-- Migracija: 20261024100000_get_or_create_conversation_rpc.sql
-- Sprečava duplikate razgovora i race conditions na DB nivou.

-- 1. Jedinstveni indeksi za razgovore
CREATE UNIQUE INDEX IF NOT EXISTS idx_conversations_unique_buyer_seller_product
ON public.conversations (buyer_id, seller_id, product_id)
WHERE product_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_conversations_unique_buyer_seller_ad
ON public.conversations (buyer_id, seller_id, ad_id)
WHERE ad_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_conversations_unique_buyer_seller_general
ON public.conversations (buyer_id, seller_id)
WHERE product_id IS NULL AND ad_id IS NULL;

-- 2. Atomska RPC funkcija za kreiranje ili pronalaženje razgovora bez race condition-a
CREATE OR REPLACE FUNCTION public.get_or_create_conversation(
  p_buyer_id UUID,
  p_seller_id UUID,
  p_product_id UUID DEFAULT NULL,
  p_ad_id UUID DEFAULT NULL,
  p_order_id UUID DEFAULT NULL,
  p_update_order_id BOOLEAN DEFAULT TRUE
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_conv_id UUID;
BEGIN
  IF p_buyer_id = p_seller_id THEN
    RAISE EXCEPTION 'Buyer and seller cannot be the same user';
  END IF;

  IF auth.uid() IS NOT NULL AND auth.uid() != p_buyer_id AND auth.uid() != p_seller_id THEN
    RAISE EXCEPTION 'Not authorized to create conversation for other users';
  END IF;

  -- 1. Ako je prosleđen order_id, proveri da li već postoji razgovor vezan za tu porudžbinu
  IF p_order_id IS NOT NULL THEN
    SELECT id INTO v_conv_id
    FROM public.conversations
    WHERE order_id = p_order_id
    LIMIT 1;

    IF v_conv_id IS NOT NULL THEN
      RETURN v_conv_id;
    END IF;
  END IF;

  -- 2. Proveri da li razgovor već postoji
  IF p_product_id IS NOT NULL THEN
    SELECT id INTO v_conv_id
    FROM public.conversations
    WHERE buyer_id = p_buyer_id
      AND seller_id = p_seller_id
      AND product_id = p_product_id
    LIMIT 1;
  ELSIF p_ad_id IS NOT NULL THEN
    SELECT id INTO v_conv_id
    FROM public.conversations
    WHERE buyer_id = p_buyer_id
      AND seller_id = p_seller_id
      AND ad_id = p_ad_id
    LIMIT 1;
  ELSE
    SELECT id INTO v_conv_id
    FROM public.conversations
    WHERE buyer_id = p_buyer_id
      AND seller_id = p_seller_id
      AND product_id IS NULL
      AND ad_id IS NULL
    LIMIT 1;
  END IF;

  IF v_conv_id IS NOT NULL THEN
    -- Ako je prosleđen order_id i dozvoljeno ažuriranje, postavi ako je trenutno NULL
    IF p_order_id IS NOT NULL AND p_update_order_id THEN
      UPDATE public.conversations
      SET order_id = p_order_id, updated_at = NOW()
      WHERE id = v_conv_id AND order_id IS NULL;
    END IF;
    RETURN v_conv_id;
  END IF;

  -- 3. Atomska kreacija sa ON CONFLICT / unique_violation zaštitom od konkurentnih upisa
  BEGIN
    INSERT INTO public.conversations (
      buyer_id,
      seller_id,
      product_id,
      ad_id,
      order_id,
      created_at,
      updated_at
    )
    VALUES (
      p_buyer_id,
      p_seller_id,
      p_product_id,
      p_ad_id,
      p_order_id,
      NOW(),
      NOW()
    )
    RETURNING id INTO v_conv_id;

    RETURN v_conv_id;
  EXCEPTION WHEN unique_violation THEN
    -- Ako je paralelna transakcija upravo kreirala isti razgovor
    IF p_product_id IS NOT NULL THEN
      SELECT id INTO v_conv_id
      FROM public.conversations
      WHERE buyer_id = p_buyer_id
        AND seller_id = p_seller_id
        AND product_id = p_product_id
      LIMIT 1;
    ELSIF p_ad_id IS NOT NULL THEN
      SELECT id INTO v_conv_id
      FROM public.conversations
      WHERE buyer_id = p_buyer_id
        AND seller_id = p_seller_id
        AND ad_id = p_ad_id
      LIMIT 1;
    ELSIF p_order_id IS NOT NULL THEN
      SELECT id INTO v_conv_id
      FROM public.conversations
      WHERE order_id = p_order_id
      LIMIT 1;
    ELSE
      SELECT id INTO v_conv_id
      FROM public.conversations
      WHERE buyer_id = p_buyer_id
        AND seller_id = p_seller_id
        AND product_id IS NULL
        AND ad_id IS NULL
      LIMIT 1;
    END IF;

    IF v_conv_id IS NOT NULL THEN
      RETURN v_conv_id;
    END IF;

    RAISE;
  END;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_or_create_conversation(UUID, UUID, UUID, UUID, UUID, BOOLEAN) TO authenticated;
