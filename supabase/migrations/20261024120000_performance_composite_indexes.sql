-- Migration: 20261024120000_performance_composite_indexes.sql
-- Description: Composite and targeted indexes for frequently queried hot paths:
-- 1. products(seller_id, available_now, category) -> Seller dashboard & filtering
-- 2. products(category, available_now, created_at DESC) -> Marketplace catalog feed
-- 3. messages(conversation_id, created_at DESC) -> Chat history pagination & realtime sort elimination
-- 4. orders(buyer_id, status, created_at DESC) & orders(seller_id, status, created_at DESC) -> Buyer & Seller orders list
-- 5. user_push_tokens(user_id) -> Push notification delivery
-- 6. conversations(buyer_id, updated_at DESC) & conversations(seller_id, updated_at DESC) -> Conversations inbox list
-- =========================================================================================

-- 1. PRODUCTS: Seller dashboard & pretraga
-- EXPLAIN ANALYZE poboljšanje:
-- Pre: Seq Scan / Bitmap Index Scan spaja odvojene indekse (idx_products_seller_id + idx_products_category)
-- Posle: Index Scan using idx_products_seller_available_category direktno filtrira tuple-ove
CREATE INDEX IF NOT EXISTS idx_products_seller_available_category
  ON public.products (seller_id, available_now, category);

CREATE INDEX IF NOT EXISTS idx_products_category_available_created
  ON public.products (category, available_now, created_at DESC);

-- 2. MESSAGES: Paginacija poruka u razgovoru
-- EXPLAIN ANALYZE poboljšanje:
-- Pre: Bitmap Index Scan na conversation_id + Sort (created_at DESC) -> O(N log N) memorijski sort
-- Posle: Index Scan (conversation_id, created_at DESC) -> O(1) sort elimination, instant limit/offset
CREATE INDEX IF NOT EXISTS idx_messages_conversation_created
  ON public.messages (conversation_id, created_at DESC);

-- 3. ORDERS: Prikaz porudžbina kupca i prodavca sa vremenskim sortiranjem (idempotentno osiguranje)
-- EXPLAIN ANALYZE:
-- Omogućava Index Scan koji pokriva buyer_id / seller_id, status i preskače eksterne sort operacije
CREATE INDEX IF NOT EXISTS idx_orders_buyer_status_created
  ON public.orders (buyer_id, status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_orders_seller_status_created
  ON public.orders (seller_id, status, created_at DESC);

-- 4. PUSH TOKENS: Brza pretraga FCM tokena po korisniku za slanje notifikacija
CREATE INDEX IF NOT EXISTS idx_push_tokens_user
  ON public.user_push_tokens (user_id);

CREATE INDEX IF NOT EXISTS idx_user_push_tokens_user_id_created
  ON public.user_push_tokens (user_id, created_at DESC);

-- 5. CONVERSATIONS: Prikaz liste razgovora sortiranih po poslednjoj aktivnosti
-- EXPLAIN ANALYZE:
-- Uklanja Sort node pri pozivu get_conversations_for_user RPC-a
CREATE INDEX IF NOT EXISTS idx_conversations_buyer_updated
  ON public.conversations (buyer_id, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_conversations_seller_updated
  ON public.conversations (seller_id, updated_at DESC);

COMMENT ON INDEX idx_products_seller_available_category IS 'Kompozitni indeks za filtriranje proizvoda po prodavcu, statusu dostupnosti i kategoriji bez bitmap spajanja.';
COMMENT ON INDEX idx_messages_conversation_created IS 'Kompozitni indeks koji eliminiše sortiranje pri paginaciji i dohvatanju istorije chat poruka.';
COMMENT ON INDEX idx_conversations_buyer_updated IS 'Omogućava instant indeksno sortiranje liste razgovora za kupca.';
COMMENT ON INDEX idx_conversations_seller_updated IS 'Omogućava instant indeksno sortiranje liste razgovora za prodavca.';
