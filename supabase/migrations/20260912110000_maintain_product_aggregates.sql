-- ============================================================================
-- Performanse: ODRŽAVANI AGREGATI umesto N+1 u products_with_ratings
-- (Nivo 2 – optimizacija mrežnog/API sloja; stavka 2.2)
--
-- PROBLEM (pre): products_with_ratings view je za SVAKI red proizvoda pozivao
--   get_product_order_count(p.id)  -> COUNT nad orders po proizvodu
--   is_seller_verified(p.seller_id)-> lookup po profilu
-- Za LIMIT 20 stranu to je bilo 20+ dodatnih upita (N+1 u bazi), a get_home_products
-- je svaki put agregirao CELE orders i reviews.
--
-- REŠENJE: dve trigger-održavane tabele (product_order_summary,
--   product_review_summary) + JOIN umesto funkcija po redu.
--   - product_order_summary se održava na INSERT/UPDATE/DELETE orders i order_items
--     (broji se status IN ('accepted','delivered')).
--   - product_review_summary se održava na svaku izmenu redova reviews.
--   - Seller verifikacija umesto funkcije dolazi iz public_profiles (već postoji
--     privacy view sa is_verified, dostupan anon).
--
-- NAPOMENA: zadržane su i stare funkcije get_product_order_count/is_seller_verified
-- radi kompatibilnosti, ali više nisu deo view-a.
-- ============================================================================

-- 1. Tabele agregata ----------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.product_order_summary (
  product_id UUID PRIMARY KEY REFERENCES public.products(id) ON DELETE CASCADE,
  order_count BIGINT NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS public.product_review_summary (
  product_id UUID PRIMARY KEY REFERENCES public.products(id) ON DELETE CASCADE,
  review_count BIGINT NOT NULL DEFAULT 0,
  avg_rating NUMERIC NOT NULL DEFAULT 0
);

-- Brz ORDER BY order_count DESC u get_home_products
CREATE INDEX IF NOT EXISTS idx_product_order_summary_count
  ON public.product_order_summary (order_count DESC);

CREATE INDEX IF NOT EXISTS idx_product_review_summary_rating
  ON public.product_review_summary (avg_rating DESC, review_count DESC);

-- View products_with_ratings je security_invoker -> tabelama mora biti dostupan
-- i anon/authenticated ulogama (bez RLS – sadrže samo javne agregate).
GRANT SELECT ON public.product_order_summary TO anon, authenticated;
GRANT SELECT ON public.product_review_summary TO anon, authenticated;

-- 2. Backfill (pre nego se trigeri pokrenu) ----------------------------------

-- 2a) Multi-item porudžbine (order_items JOIN orders)
INSERT INTO public.product_order_summary (product_id, order_count)
SELECT oi.product_id, COUNT(DISTINCT oi.order_id)::bigint
FROM public.order_items oi
JOIN public.orders o ON o.id = oi.order_id
WHERE o.status IN ('accepted', 'delivered')
GROUP BY oi.product_id
ON CONFLICT (product_id)
DO UPDATE SET order_count = EXCLUDED.order_count;

-- 2b) Legacy single-item porudžbine (orders.product_id) bez order_items redova
INSERT INTO public.product_order_summary (product_id, order_count)
SELECT o.product_id, COUNT(*)::bigint
FROM public.orders o
WHERE o.product_id IS NOT NULL
  AND o.status IN ('accepted', 'delivered')
  AND NOT EXISTS (
    SELECT 1 FROM public.order_items oi WHERE oi.order_id = o.id
  )
GROUP BY o.product_id
ON CONFLICT (product_id)
DO UPDATE SET order_count = public.product_order_summary.order_count + EXCLUDED.order_count;

-- 2c) Recenzije
INSERT INTO public.product_review_summary (product_id, review_count, avg_rating)
SELECT product_id, COUNT(*)::bigint, AVG(rating)::numeric
FROM public.reviews
WHERE product_id IS NOT NULL
GROUP BY product_id
ON CONFLICT (product_id)
DO UPDATE SET
  review_count = EXCLUDED.review_count,
  avg_rating = EXCLUDED.avg_rating;

-- 3. Održavanje product_order_summary ----------------------------------------

-- Pomoćna funkcija: primeni delta (1 ili -1) na sve proizvode jedne porudžbine.
CREATE OR REPLACE FUNCTION public.adjust_product_order_summary(p_order_id UUID, p_delta BIGINT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_has_items BOOLEAN;
BEGIN
  IF p_delta = 0 THEN
    RETURN;
  END IF;

  SELECT EXISTS(SELECT 1 FROM public.order_items WHERE order_id = p_order_id) INTO v_has_items;

  IF v_has_items THEN
    -- Multi-item porudžbina
    INSERT INTO public.product_order_summary (product_id, order_count)
    SELECT DISTINCT oi.product_id, p_delta
    FROM public.order_items oi
    WHERE oi.order_id = p_order_id
    ON CONFLICT (product_id)
    DO UPDATE SET order_count = public.product_order_summary.order_count + EXCLUDED.order_count;

    -- Očisti nulte brojače da tabela ostane kompaktna
    DELETE FROM public.product_order_summary s
    WHERE s.order_count <= 0
      AND EXISTS (
        SELECT 1 FROM public.order_items oi
        WHERE oi.order_id = p_order_id AND oi.product_id = s.product_id
      );
  ELSE
    -- Legacy single-item porudžbina
    INSERT INTO public.product_order_summary (product_id, order_count)
    SELECT o.product_id, p_delta
    FROM public.orders o
    WHERE o.id = p_order_id AND o.product_id IS NOT NULL
    ON CONFLICT (product_id)
    DO UPDATE SET order_count = public.product_order_summary.order_count + EXCLUDED.order_count;

    DELETE FROM public.product_order_summary s
    WHERE s.order_count <= 0
      AND EXISTS (
        SELECT 1 FROM public.orders o
        WHERE o.id = p_order_id AND o.product_id = s.product_id
      );
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.maintain_product_order_summary()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_old_counted BOOLEAN;
  v_new_counted BOOLEAN;
  v_delta BIGINT;
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.status IN ('accepted', 'delivered') THEN
      PERFORM public.adjust_product_order_summary(NEW.id, 1);
    END IF;

  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
      v_old_counted := OLD.status IN ('accepted', 'delivered');
      v_new_counted := NEW.status IN ('accepted', 'delivered');
      IF v_old_counted <> v_new_counted THEN
        IF v_new_counted THEN
          v_delta := 1;
        ELSE
          v_delta := -1;
        END IF;
        PERFORM public.adjust_product_order_summary(NEW.id, v_delta);
      END IF;
    END IF;

  ELSIF TG_OP = 'DELETE' THEN
    IF OLD.status IN ('accepted', 'delivered') THEN
      PERFORM public.adjust_product_order_summary(OLD.id, -1);
    END IF;
  END IF;

  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_maintain_product_order_summary ON public.orders;
CREATE TRIGGER trg_maintain_product_order_summary
  AFTER INSERT OR UPDATE OR DELETE ON public.orders
  FOR EACH ROW EXECUTE FUNCTION public.maintain_product_order_summary();

CREATE OR REPLACE FUNCTION public.maintain_order_items_summary()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_status TEXT;
BEGIN
  IF TG_OP = 'INSERT' THEN
    SELECT status INTO v_status FROM public.orders WHERE id = NEW.order_id;
    IF v_status IN ('accepted', 'delivered') THEN
      INSERT INTO public.product_order_summary (product_id, order_count)
      VALUES (NEW.product_id, 1)
      ON CONFLICT (product_id)
      DO UPDATE SET order_count = public.product_order_summary.order_count + 1;
    END IF;
  ELSIF TG_OP = 'DELETE' THEN
    SELECT status INTO v_status FROM public.orders WHERE id = OLD.order_id;
    IF v_status IN ('accepted', 'delivered') THEN
      UPDATE public.product_order_summary
      SET order_count = order_count - 1
      WHERE product_id = OLD.product_id;

      DELETE FROM public.product_order_summary WHERE product_id = OLD.product_id AND order_count <= 0;
    END IF;
  END IF;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_maintain_order_items_summary ON public.order_items;
CREATE TRIGGER trg_maintain_order_items_summary
  AFTER INSERT OR DELETE ON public.order_items
  FOR EACH ROW EXECUTE FUNCTION public.maintain_order_items_summary();

-- 4. Održavanje product_review_summary ---------------------------------------

CREATE OR REPLACE FUNCTION public.recompute_product_review_summary(p_product_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count BIGINT;
  v_avg   NUMERIC;
BEGIN
  IF p_product_id IS NULL THEN
    RETURN;
  END IF;

  SELECT COUNT(*), COALESCE(AVG(rating), 0)::numeric
  INTO v_count, v_avg
  FROM public.reviews
  WHERE product_id = p_product_id;

  IF v_count = 0 THEN
    DELETE FROM public.product_review_summary WHERE product_id = p_product_id;
  ELSE
    INSERT INTO public.product_review_summary (product_id, review_count, avg_rating)
    VALUES (p_product_id, v_count, v_avg)
    ON CONFLICT (product_id)
    DO UPDATE SET
      review_count = EXCLUDED.review_count,
      avg_rating = EXCLUDED.avg_rating;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.maintain_product_review_summary()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP IN ('INSERT', 'UPDATE') AND NEW.product_id IS NOT NULL THEN
    PERFORM public.recompute_product_review_summary(NEW.product_id);
  END IF;

  IF TG_OP IN ('UPDATE', 'DELETE')
      AND OLD.product_id IS NOT NULL
      AND (TG_OP = 'DELETE' OR NEW.product_id IS DISTINCT FROM OLD.product_id) THEN
    PERFORM public.recompute_product_review_summary(OLD.product_id);
  END IF;

  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_maintain_product_review_summary ON public.reviews;
CREATE TRIGGER trg_maintain_product_review_summary
  AFTER INSERT OR UPDATE OR DELETE ON public.reviews
  FOR EACH ROW EXECUTE FUNCTION public.maintain_product_review_summary();

-- 5. products_with_ratings – BEZ N+1 -----------------------------------------

CREATE OR REPLACE VIEW public.products_with_ratings
WITH (security_invoker = on)
AS
SELECT
  p.id,
  p.seller_id,
  p.category,
  p.name,
  p.price_per_kg,
  p.min_order_kg,
  p.order_step,
  p.available_kg,
  p.unit_type,
  p.description,
  p.image_urls,
  p.pickup_options,
  p.location,
  p.is_domestic,
  p.available_now,
  p.delivery_mode,
  p.created_at,
  COALESCE(r.avg_rating, 0)::numeric   AS avg_rating,
  COALESCE(r.review_count, 0)::bigint  AS review_count,
  COALESCE(o.order_count, 0)::bigint   AS order_count,
  COALESCE(prof.is_verified, false)    AS seller_is_verified
FROM public.products p
LEFT JOIN public.product_review_summary r ON r.product_id = p.id
LEFT JOIN public.product_order_summary o ON o.product_id = p.id
LEFT JOIN public.public_profiles prof ON prof.id = p.seller_id;

GRANT SELECT ON public.products_with_ratings TO anon, authenticated;

-- 6. get_home_products – koristi agregate i vraća i ratinge -------------------

DROP FUNCTION IF EXISTS public.get_home_products(int, text, text);
CREATE OR REPLACE FUNCTION public.get_home_products(
  p_limit int DEFAULT 50,
  p_region text DEFAULT NULL,
  p_category text DEFAULT NULL
)
RETURNS TABLE (
  id uuid,
  seller_id uuid,
  category text,
  name text,
  price_per_kg numeric,
  min_order_kg numeric,
  available_kg numeric,
  description text,
  image_urls text[],
  pickup_options text[],
  location text,
  is_domestic boolean,
  available_now boolean,
  created_at timestamptz,
  order_count bigint,
  avg_rating numeric,
  review_count bigint
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    p.id, p.seller_id, p.category, p.name, p.price_per_kg, p.min_order_kg,
    p.available_kg, p.description, p.image_urls, p.pickup_options, p.location,
    p.is_domestic, p.available_now, p.created_at,
    COALESCE(o.order_count, 0)::bigint  AS order_count,
    COALESCE(r.avg_rating, 0)::numeric  AS avg_rating,
    COALESCE(r.review_count, 0)::bigint AS review_count
  FROM public.products p
  LEFT JOIN public.product_order_summary o ON o.product_id = p.id
  LEFT JOIN public.product_review_summary r ON r.product_id = p.id
  WHERE (p_region IS NULL OR p_region = '' OR p.location = p_region)
    AND (p_category IS NULL OR p_category = '' OR p.category = p_category)
  ORDER BY
    (p.created_at >= NOW() - INTERVAL '14 days') DESC,
    COALESCE(r.avg_rating, 0) DESC,
    COALESCE(o.order_count, 0) DESC,
    p.created_at DESC
  LIMIT GREATEST(1, LEAST(p_limit, 100));
$$;

GRANT EXECUTE ON FUNCTION public.get_home_products(INTEGER, TEXT, TEXT) TO anon, authenticated;

-- 7. Retention job: uskladi sumarne brojače PRE batch brisanja orders ---------

CREATE OR REPLACE FUNCTION public.handle_order_retention()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Arhiviranje: samo status 'sent', starije od 30 dana
  UPDATE public.orders
  SET status = 'arhivirano',
      archived_at = now()
  WHERE status = 'sent'
    AND created_at <= now() - interval '30 days';

  -- Uskladi sumarni brojač pre nego što redovi orders budu obrisani
  UPDATE public.product_order_summary s
  SET order_count = s.order_count - 1
  FROM (
    SELECT DISTINCT oi.product_id
    FROM public.order_items oi
    JOIN public.orders o ON o.id = oi.order_id
    WHERE o.expires_at IS NOT NULL AND o.expires_at <= now()
      AND o.status IN ('accepted', 'delivered')
  ) x
  WHERE s.product_id = x.product_id;

  DELETE FROM public.product_order_summary s WHERE s.order_count <= 0;

  -- Brisanje: expires_at <= sada (order_items se brišu CASCADE)
  DELETE FROM public.orders
  WHERE expires_at <= now();
END;
$$;

-- Zadržavamo wrapper koga pg_cron može da poziva
CREATE OR REPLACE FUNCTION public.archive_and_expire_orders()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public.handle_order_retention();
END;
$$;