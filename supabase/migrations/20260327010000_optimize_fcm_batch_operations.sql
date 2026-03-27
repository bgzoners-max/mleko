-- Optimizuj FCM batch operations za brže slanje push notifikacija
-- Dodaj indeks na token za brže lookup-e pri brisanju
CREATE INDEX IF NOT EXISTS idx_user_push_tokens_token
ON user_push_tokens(token);

-- Dodaj composite index za brže brisanja (token, user_id)
CREATE INDEX IF NOT EXISTS idx_user_push_tokens_token_user_id
ON user_push_tokens(token, user_id);

-- Dodaj indeks na user_id ako već ne postoji (za getToken)
CREATE INDEX IF NOT EXISTS idx_user_push_tokens_user_id_created
ON user_push_tokens(user_id, created_at DESC);

COMMENT ON INDEX idx_user_push_tokens_token IS 'Enables fast single token lookup and bulk delete operations in FCM batch processing';
COMMENT ON INDEX idx_user_push_tokens_token_user_id IS 'Composite index for efficient token cleanup during batch operations';
COMMENT ON INDEX idx_user_push_tokens_user_id_created IS 'Enables fast user token queries with temporal ordering for cleanup jobs';
