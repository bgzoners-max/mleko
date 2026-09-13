-- ============================================================================
-- Nivo 3: Baza podataka (Postgres/Supabase)
-- 3.1. Indeksi za notifications (već primenjeni u 20260912100000; IF NOT EXISTS osigurava idempotenciju)
-- 3.2. Indeks orders(product_id, status) i order_items indeksi
-- 3.3. Kompozitni indeks za paginaciju messages(conversation_id, created_at DESC, id DESC)
-- 3.4. conversation_typing TTL čišćenje i cron posao
-- 3.5. search_products_fts eliminacija duplog JOIN-a nad products
-- ============================================================================

-- 1. Indeksi nad notifications (3.1) ------------------------------------------
CREATE INDEX IF NOT EXISTS idx_notifications_user_created
  ON public.notifications (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_notifications_user_unread
  ON public.notifications (user_id)
  WHERE read_at IS NULL;

-- 2. Indeksi nad orders i order_items (3.2) -----------------------------------
CREATE INDEX IF NOT EXISTS idx_orders_product_status
  ON public.orders (product_id, status);

CREATE INDEX IF NOT EXISTS idx_order_items_product_id
  ON public.order_items (product_id);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id
  ON public.order_items (order_id);

-- 3. Kompozitni indeks za paginaciju poruka (3.3) -----------------------------
CREATE INDEX IF NOT EXISTS idx_messages_conversation_created
  ON public.messages (conversation_id, created_at DESC, id DESC);

-- 4. conversation_typing TTL čišćenje (3.4) -----------------------------------
CREATE OR REPLACE FUNCTION public.cleanup_stale_conversation_typing()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Brišemo redove starije od 1 sata ili one gde je korisnik završio kucanje
  DELETE FROM public.conversation_typing
  WHERE updated_at < NOW() - INTERVAL '1 hour'
     OR is_typing = false;
END;
$$;

GRANT EXECUTE ON FUNCTION public.cleanup_stale_conversation_typing() TO authenticated, service_role;

-- Integracija u generalni retention job
CREATE OR REPLACE FUNCTION public.archive_and_expire_orders()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public.handle_order_retention();
  PERFORM public.cleanup_stale_conversation_typing();
END;
$$;

-- Zakazivanje pg_cron posla (ako je pg_cron ekstenzija omogućena)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'cleanup_stale_conversation_typing_job') THEN
      PERFORM cron.unschedule('cleanup_stale_conversation_typing_job');
    END IF;

    PERFORM cron.schedule(
      'cleanup_stale_conversation_typing_job',
      '0 * * * *', -- svakih sat vremena
      'SELECT public.cleanup_stale_conversation_typing()'
    );
  END IF;
END $$;

-- 5. Optimizovan search_products_fts bez duplog spajanja products (3.5) -------
CREATE OR REPLACE FUNCTION public.search_products_fts(
  p_query             text,
  p_category          text    DEFAULT NULL,
  p_region            text    DEFAULT NULL,
  p_available_now     boolean DEFAULT NULL,
  p_exclude_seller_id uuid    DEFAULT NULL,
  p_limit             int     DEFAULT 20,
  p_offset            int     DEFAULT 0
)
RETURNS SETOF public.products_with_ratings
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
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
  LEFT JOIN public.public_profiles prof ON prof.id = p.seller_id
  WHERE
    p.search_vector @@ websearch_to_tsquery('simple', unaccent(p_query))     AND
    (p_category          IS NULL OR p.category     = p_category)             AND
    (p_region            IS NULL OR p.location     = p_region)               AND
    (p_available_now     IS NULL OR p.available_now = p_available_now)       AND
    (p_exclude_seller_id IS NULL OR p.seller_id   <> p_exclude_seller_id)
  ORDER BY
    ts_rank(p.search_vector, websearch_to_tsquery('simple', unaccent(p_query))) DESC,
    p.created_at DESC
  LIMIT  p_limit
  OFFSET p_offset;
$$;

GRANT EXECUTE ON FUNCTION public.search_products_fts TO anon, authenticated;
