-- ============================================================================
-- Migracija: 20261030100000_fix_conversation_indexes_and_public_profiles.sql
-- Naziv: Popravka dupliranih indeksa razgovora, shares_count zaštite i vidljivosti javnih profila
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. UKLANJANJE NESKOPIRANIH DUPLIRANIH INDEKSA RAZGOVORA
--    U migraciji 20261007080000 kreirani su parcijalni indeksi sa `AND order_id IS NULL`
--    (idx_conversations_buyer_seller_product, idx_conversations_buyer_seller_ad,
--    idx_conversations_buyer_seller_general). U migraciji 20261024100000 greškom su
--    dodati neskopirani indeksi bez `order_id IS NULL` koji blokiraju više razgovora
--    po različitim porudžbinama za isti proizvod.
-- ----------------------------------------------------------------------------
DROP INDEX IF EXISTS public.idx_conversations_unique_buyer_seller_product;
DROP INDEX IF EXISTS public.idx_conversations_unique_buyer_seller_ad;
DROP INDEX IF EXISTS public.idx_conversations_unique_buyer_seller_general;

-- Osiguraj da parcijalni indeksi sa `AND order_id IS NULL` postoje
CREATE UNIQUE INDEX IF NOT EXISTS idx_conversations_order
  ON public.conversations (order_id)
  WHERE order_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_conversations_buyer_seller_product
  ON public.conversations (buyer_id, seller_id, product_id)
  WHERE product_id IS NOT NULL AND order_id IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_conversations_buyer_seller_ad
  ON public.conversations (buyer_id, seller_id, ad_id)
  WHERE ad_id IS NOT NULL AND order_id IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_conversations_buyer_seller_general
  ON public.conversations (buyer_id, seller_id)
  WHERE product_id IS NULL AND ad_id IS NULL AND order_id IS NULL;


-- ----------------------------------------------------------------------------
-- 2. AŽURIRANJE get_or_create_conversation RPC FUNKCIJE
--    Kada je p_order_id IS NOT NULL, Korak 2 ne sme da spoji novu porudžbinu
--    sa postojećim razgovorom koji već pripada drugoj porudžbini (mora proveriti order_id IS NULL).
-- ----------------------------------------------------------------------------
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

  -- 2. Proveri da li postoji opšti/predmetni razgovor (ako je p_order_id prosleđen,
  --    uzimamo u obzir samo razgovor gde je order_id IS NULL kako ne bismo pregazili drugu porudžbinu)
  IF p_product_id IS NOT NULL THEN
    SELECT id INTO v_conv_id
    FROM public.conversations
    WHERE buyer_id = p_buyer_id
      AND seller_id = p_seller_id
      AND product_id = p_product_id
      AND (p_order_id IS NULL OR order_id IS NULL)
    ORDER BY (order_id IS NULL) DESC, updated_at DESC
    LIMIT 1;
  ELSIF p_ad_id IS NOT NULL THEN
    SELECT id INTO v_conv_id
    FROM public.conversations
    WHERE buyer_id = p_buyer_id
      AND seller_id = p_seller_id
      AND ad_id = p_ad_id
      AND (p_order_id IS NULL OR order_id IS NULL)
    ORDER BY (order_id IS NULL) DESC, updated_at DESC
    LIMIT 1;
  ELSE
    SELECT id INTO v_conv_id
    FROM public.conversations
    WHERE buyer_id = p_buyer_id
      AND seller_id = p_seller_id
      AND product_id IS NULL
      AND ad_id IS NULL
      AND (p_order_id IS NULL OR order_id IS NULL)
    ORDER BY (order_id IS NULL) DESC, updated_at DESC
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

  -- 3. Atomska kreacija sa unique_violation zaštitom od konkurentnih upisa
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
    IF p_order_id IS NOT NULL THEN
      SELECT id INTO v_conv_id
      FROM public.conversations
      WHERE order_id = p_order_id
      LIMIT 1;
    END IF;

    IF v_conv_id IS NULL AND p_product_id IS NOT NULL THEN
      SELECT id INTO v_conv_id
      FROM public.conversations
      WHERE buyer_id = p_buyer_id
        AND seller_id = p_seller_id
        AND product_id = p_product_id
        AND (p_order_id IS NULL OR order_id IS NULL)
      LIMIT 1;
    ELSIF v_conv_id IS NULL AND p_ad_id IS NOT NULL THEN
      SELECT id INTO v_conv_id
      FROM public.conversations
      WHERE buyer_id = p_buyer_id
        AND seller_id = p_seller_id
        AND ad_id = p_ad_id
        AND (p_order_id IS NULL OR order_id IS NULL)
      LIMIT 1;
    ELSIF v_conv_id IS NULL THEN
      SELECT id INTO v_conv_id
      FROM public.conversations
      WHERE buyer_id = p_buyer_id
        AND seller_id = p_seller_id
        AND product_id IS NULL
        AND ad_id IS NULL
        AND (p_order_id IS NULL OR order_id IS NULL)
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


-- ----------------------------------------------------------------------------
-- 3. ZAŠTITA shares_count U protect_classified_ad_administrative_columns()
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.protect_classified_ad_administrative_columns()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_is_caller_admin BOOLEAN := public.is_admin_or_service_role();
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NOT v_is_caller_admin THEN
      NEW.is_featured := false;
      NEW.featured_until := NULL;
      NEW.is_urgent := false;
      NEW.reports_count := 0;
      NEW.call_clicks_count := 0;
      NEW.shares_count := 0;
      NEW.views_count := 0;
    END IF;
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' THEN
    -- Spreči otimanje vlasništva oglasa
    NEW.user_id := OLD.user_id;

    -- Samo administrator sme da menja is_featured, is_urgent ili featured_until
    IF NOT v_is_caller_admin THEN
      IF (NEW.is_featured IS DISTINCT FROM OLD.is_featured) OR
         (NEW.is_urgent IS DISTINCT FROM OLD.is_urgent) OR
         (NEW.featured_until IS DISTINCT FROM OLD.featured_until) THEN
        RAISE EXCEPTION USING
          ERRCODE = '42501',
          MESSAGE = 'Samo administrator može menjati status istaknutosti ili hitnosti oglasa.';
      END IF;

      -- Spreči vlasnika da lažira brojače pregleda, poziva, deljenja ili resetuje prijave
      NEW.reports_count := OLD.reports_count;
      NEW.call_clicks_count := OLD.call_clicks_count;
      NEW.shares_count := OLD.shares_count;
      NEW.views_count := OLD.views_count;
    END IF;
    RETURN NEW;
  END IF;

  RETURN NEW;
END;
$$;


-- ----------------------------------------------------------------------------
-- 4. PROFILES RLS & PUBLIC_PROFILES: Vidljivost autora recenzija i aktivnih oglašivača
--    Rešava problem gde su recenzije prikazivale generičko 'Kupac' umesto imena autora,
--    a pojedinačni mali oglasi fizičkih lica (role = 'buyer') imali null profil prodavca.
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Public can view sellers and order participants" ON public.profiles;
DROP POLICY IF EXISTS "profiles_select_authenticated_or_public" ON public.profiles;

CREATE POLICY "profiles_select_authenticated_or_public"
ON public.profiles
FOR SELECT
USING (
  -- Korisnik vidi sopstveni profil
  (SELECT auth.uid()) = id
  -- Administrator vidi sve profile
  OR (SELECT public.is_admin())
  -- Prodavci su javni radi prikaza na mapi i profilu prodavnice
  OR (role = 'seller' OR farm_name IS NOT NULL)
  -- Korisnici koji imaju aktivan mali oglas su vidljivi na kartici/detaljima oglasa
  OR EXISTS (
    SELECT 1 FROM public.classified_ads ca
    WHERE ca.user_id = public.profiles.id AND ca.status = 'active'
  )
  -- Autori javnih recenzija proizvoda su vidljivi radi prikaza imena uz recenziju
  OR EXISTS (
    SELECT 1 FROM public.reviews r
    WHERE r.buyer_id = public.profiles.id
  )
  -- Kupac je vidljiv prodavcu ako postoji porudžbina između njih
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

-- Ažuriranje public_profiles view-a sa istim pravilima vidljivosti
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
    SELECT 1 FROM public.classified_ads ca
    WHERE ca.user_id = p.id AND ca.status = 'active'
  )
  OR EXISTS (
    SELECT 1 FROM public.reviews r
    WHERE r.buyer_id = p.id
  )
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
