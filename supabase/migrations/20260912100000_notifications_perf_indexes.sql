-- ============================================================================
-- Performanse: indeksi za najčešće upite nad notifications
-- (Nivo 2 – optimizacija mrežnog/API sloja; stavka 2.3)
--
-- Aplikacija svaki čas radi:
--   1) SELECT ... WHERE user_id = ? ORDER BY created_at DESC LIMIT 50
--   2) COUNT ... WHERE user_id = ? AND read_at IS NULL
-- Bez indeksa ovi upiti rade SEQ SCAN kako tabela raste.
-- ============================================================================

-- 1) Lista notifikacija: user_id + created_at DESC (pokriva i LIMIT 50)
CREATE INDEX IF NOT EXISTS idx_notifications_user_created
  ON public.notifications (user_id, created_at DESC);

-- 2) Broj nepročitanih: parcijalni indeks omogućava index-only scan
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread
  ON public.notifications (user_id)
  WHERE read_at IS NULL;