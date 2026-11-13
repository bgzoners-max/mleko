-- ============================================================================
-- Paket 3 (P2) — Indeksi na stranim ključevima i SET search_path za funkcije
-- ============================================================================

-- 1. Nedostajući indeksi na čestim FK / JOIN / cascade kolonama
CREATE INDEX IF NOT EXISTS idx_notifications_order_id
  ON public.notifications (order_id)
  WHERE order_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_notifications_ticket_id
  ON public.notifications (ticket_id)
  WHERE ticket_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_notifications_conversation_id
  ON public.notifications (conversation_id)
  WHERE conversation_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_reviews_seller_id
  ON public.reviews (seller_id);

CREATE INDEX IF NOT EXISTS idx_reviews_product_id
  ON public.reviews (product_id)
  WHERE product_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_reviews_order_id
  ON public.reviews (order_id)
  WHERE order_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_messages_sender_id
  ON public.messages (sender_id);

CREATE INDEX IF NOT EXISTS idx_orders_delivery_point_id
  ON public.orders (delivery_point_id)
  WHERE delivery_point_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_favorite_sellers_seller_id
  ON public.favorite_sellers (seller_id);

CREATE INDEX IF NOT EXISTS idx_classified_categories_parent_id
  ON public.classified_categories (parent_id)
  WHERE parent_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_support_ticket_messages_sender_id
  ON public.support_ticket_messages (sender_id);

-- 2. Eksplicitan search_path za preostale SECURITY INVOKER funkcije
ALTER FUNCTION public.conversation_updated_on_message()
  SET search_path = public;

ALTER FUNCTION public.touch_message_reaction_updated_at()
  SET search_path = public;

ALTER FUNCTION public.get_seller_response_time_stats(UUID)
  SET search_path = public;

ALTER FUNCTION public.normalize_listing_key(TEXT)
  SET search_path = public;

ALTER FUNCTION public.update_support_ticket_updated_at()
  SET search_path = public;

ALTER FUNCTION public.immutable_unaccent(TEXT)
  SET search_path = public, extensions;

ALTER FUNCTION public.normalize_search_text(TEXT)
  SET search_path = public, extensions;

