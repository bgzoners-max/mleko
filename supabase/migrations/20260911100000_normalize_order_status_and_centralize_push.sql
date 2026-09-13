-- ============================================================================
-- Migracija: Normalizacija Statusa Porudžbine (archived) i Centralizacija Push Logike
-- Datum: 2026-09-11
-- Opis:
--   1. Ažuriranje check constraint-a i triger funkcije (dozvola za migraciju 'arhivirano' -> 'archived').
--   2. Normalizacija postojećih porudžbina u bazi: 'arhivirano' -> 'archived'.
--   3. Kreiranje jedinstvene pomoćne funkcije public.send_push_notification().
--   4. Ažuriranje invoke_send_push trigera da koristi novu funkciju.
-- ============================================================================

-- ============================================================================
-- 1. Ažuriranje triger funkcije za tranzicije statusa (dozvoljava migraciju)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.enforce_order_status_transition()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_caller UUID;
  v_is_seller BOOLEAN := false;
  v_is_buyer BOOLEAN := false;
  v_allowed BOOLEAN := false;
BEGIN
  IF OLD.status = NEW.status THEN
    RETURN NEW;
  END IF;

  -- Dozvoli automatsku i jednokratnu normalizaciju 'arhivirano' -> 'archived'
  IF OLD.status = 'arhivirano' AND NEW.status = 'archived' THEN
    RETURN NEW;
  END IF;

  v_caller := auth.uid();

  -- Sistemski / service_role poziv (cron, background sync)
  IF v_caller IS NULL OR auth.role() = 'service_role' THEN
    v_allowed := CASE OLD.status
      WHEN 'sent' THEN NEW.status IN ('accepted', 'rejected')
      WHEN 'accepted' THEN NEW.status IN ('shipped', 'cancelled_by_seller')
      WHEN 'shipped' THEN NEW.status IN ('delivered', 'cancelled_by_seller')
      WHEN 'rejected' THEN NEW.status = 'archived'
      WHEN 'cancelled_by_seller' THEN NEW.status = 'archived'
      WHEN 'delivered' THEN NEW.status = 'archived'
      WHEN 'archived' THEN false
      ELSE false
    END;

    IF NOT v_allowed THEN
      RAISE EXCEPTION 'Nedozvoljena promena statusa porudžbine (sistem): % -> %',
        OLD.status, NEW.status
        USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
  END IF;

  v_is_seller := (v_caller = OLD.seller_id);
  v_is_buyer  := (v_caller = OLD.buyer_id);

  IF NOT v_is_seller AND NOT v_is_buyer THEN
    RAISE EXCEPTION 'Nemate dozvolu za izmenu ove porudžbine.'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  v_allowed := CASE OLD.status
    WHEN 'sent' THEN
      v_is_seller AND NEW.status IN ('accepted', 'rejected')
    WHEN 'accepted' THEN
      v_is_seller AND NEW.status IN ('shipped', 'cancelled_by_seller')
    WHEN 'shipped' THEN
      (v_is_seller AND NEW.status = 'cancelled_by_seller')
      OR
      (v_is_buyer AND NEW.status = 'delivered')
    WHEN 'rejected' THEN
      (v_is_seller OR v_is_buyer) AND NEW.status = 'archived'
    WHEN 'cancelled_by_seller' THEN
      (v_is_seller OR v_is_buyer) AND NEW.status = 'archived'
    WHEN 'delivered' THEN
      (v_is_seller OR v_is_buyer) AND NEW.status = 'archived'
    WHEN 'archived' THEN false
    ELSE false
  END;

  IF NOT v_allowed THEN
    RAISE EXCEPTION 'Nedozvoljena promena statusa porudžbine (%): % -> %',
      CASE WHEN v_is_seller THEN 'prodavac' ELSE 'kupac' END,
      OLD.status, NEW.status
      USING ERRCODE = 'check_violation',
      HINT = 'Dozvoljeno: sent->accepted/rejected; accepted->shipped/cancelled_by_seller; shipped->delivered/cancelled_by_seller; rejected/cancelled_by_seller/delivered->archived.';
  END IF;

  RETURN NEW;
END;
$$;

-- ============================================================================
-- 2. Normalizacija postojećih porudžbina u 'archived' i check constraint
-- ============================================================================

-- Normalizuj sve postojeće podatke
UPDATE public.orders
SET status = 'archived'
WHERE status = 'arhivirano';

-- Ažuriranje check constraint-a na orders tabeli
ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS orders_status_check;
ALTER TABLE public.orders ADD CONSTRAINT orders_status_check
  CHECK (status IN ('sent', 'accepted', 'shipped', 'rejected', 'delivered', 'cancelled_by_seller', 'archived'));

-- ============================================================================
-- 3. Centralizovana Funkcija za Slanje Push Obaveštenja
-- ============================================================================

CREATE OR REPLACE FUNCTION public.send_push_notification(
  p_user_id UUID,
  p_title TEXT,
  p_body TEXT,
  p_type TEXT,
  p_order_id TEXT DEFAULT '',
  p_ticket_id TEXT DEFAULT '',
  p_conversation_id TEXT DEFAULT '',
  p_data JSONB DEFAULT '{}'::jsonb
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  base_url TEXT;
  service_key TEXT;
  fn_url TEXT;
BEGIN
  IF p_user_id IS NULL THEN
    RETURN false;
  END IF;

  -- 1. Čitanje service_role_key isključivo iz Supabase Vault-a
  BEGIN
    SELECT decrypted_secret INTO service_key 
    FROM vault.decrypted_secrets 
    WHERE name = 'service_role_key' 
    LIMIT 1;
  EXCEPTION WHEN OTHERS THEN
    service_key := NULL;
  END;

  -- 2. Čitanje functions_base_url iz Vault-a ili non-secret edge_config fallback
  BEGIN
    SELECT decrypted_secret INTO base_url 
    FROM vault.decrypted_secrets 
    WHERE name = 'functions_base_url' 
    LIMIT 1;
  EXCEPTION WHEN OTHERS THEN
    base_url := NULL;
  END;

  IF base_url IS NULL OR base_url = '' THEN
    SELECT value INTO base_url FROM public.edge_config WHERE key = 'functions_base_url' LIMIT 1;
  END IF;

  IF service_key IS NULL OR service_key = '' OR base_url IS NULL OR base_url = '' THEN
    RAISE WARNING 'send_push_notification: Nedostaje konfiguracija (Vault service_role_key ili URL).';
    RETURN false;
  END IF;

  fn_url := base_url || '/functions/v1/send-push';

  PERFORM net.http_post(
    url := fn_url,
    body := jsonb_build_object(
      'user_id', p_user_id,
      'title', COALESCE(p_title, ''),
      'body', COALESCE(p_body, ''),
      'type', COALESCE(p_type, ''),
      'order_id', COALESCE(p_order_id, ''),
      'ticket_id', COALESCE(p_ticket_id, ''),
      'conversation_id', COALESCE(p_conversation_id, ''),
      'data', COALESCE(p_data, '{}'::jsonb)
    ),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || service_key
    ),
    timeout_milliseconds := 5000
  );

  RETURN true;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'send_push_notification greška: %', SQLERRM;
  RETURN false;
END;
$$;

REVOKE ALL ON FUNCTION public.send_push_notification(UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.send_push_notification(UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, JSONB) TO service_role;

-- ============================================================================
-- 4. Ažuriranje invoke_send_push da delegira na send_push_notification
-- ============================================================================

CREATE OR REPLACE FUNCTION public.invoke_send_push()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  PERFORM public.send_push_notification(
    p_user_id := NEW.user_id,
    p_title := COALESCE(NEW.title, ''),
    p_body := COALESCE(NEW.body, ''),
    p_type := COALESCE(NEW.type::text, ''),
    p_order_id := CASE WHEN NEW.order_id IS NOT NULL THEN NEW.order_id::text ELSE '' END,
    p_ticket_id := CASE WHEN NEW.ticket_id IS NOT NULL THEN NEW.ticket_id::text ELSE '' END,
    p_conversation_id := CASE WHEN NEW.conversation_id IS NOT NULL THEN NEW.conversation_id::text ELSE '' END
  );
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'invoke_send_push greška: %', SQLERRM;
  RETURN NEW;
END;
$$;
