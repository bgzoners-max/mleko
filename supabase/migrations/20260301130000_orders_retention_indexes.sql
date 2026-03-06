-- Indeksi za brzo arhiviranje, brisanje i listanje porudžbina (100k+ redova)
-- =============================================================================
-- Za produkciju bez locka: pokreni indekse ručno sa CONCURRENTLY (van migracije).

-- 1) Arhiviranje: UPDATE ... WHERE status = 'sent' AND created_at <= ...
CREATE INDEX IF NOT EXISTS idx_orders_status_created_at
  ON public.orders (status, created_at)
  WHERE status = 'sent';

-- 2) Brisanje isteklih: DELETE ... WHERE expires_at <= now()
CREATE INDEX IF NOT EXISTS idx_orders_expires_at
  ON public.orders (expires_at);

-- 3) Listanje po kupcu: buyer_id + status + created_at DESC
CREATE INDEX IF NOT EXISTS idx_orders_buyer_status_created
  ON public.orders (buyer_id, status, created_at DESC);

-- 4) Listanje po prodavcu: seller_id + status + created_at DESC
CREATE INDEX IF NOT EXISTS idx_orders_seller_status_created
  ON public.orders (seller_id, status, created_at DESC);
