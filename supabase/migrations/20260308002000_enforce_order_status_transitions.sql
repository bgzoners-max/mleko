-- Enforce forward-only order status transitions at DB level.
-- Prevents invalid backward jumps and stale/racy updates.

CREATE OR REPLACE FUNCTION public.enforce_order_status_transition()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
  v_allowed BOOLEAN := false;
BEGIN
  IF NEW.status IS NOT DISTINCT FROM OLD.status THEN
    RETURN NEW;
  END IF;

  v_allowed := CASE OLD.status
    WHEN 'sent' THEN NEW.status IN ('accepted', 'rejected')
    WHEN 'accepted' THEN NEW.status IN ('shipped', 'cancelled_by_seller')
    WHEN 'shipped' THEN NEW.status IN ('delivered', 'cancelled_by_seller')
    WHEN 'rejected' THEN NEW.status = 'arhivirano'
    WHEN 'cancelled_by_seller' THEN NEW.status = 'arhivirano'
    WHEN 'delivered' THEN NEW.status = 'arhivirano'
    WHEN 'arhivirano' THEN false
    ELSE false
  END;

  IF NOT v_allowed THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'Nedozvoljena tranzicija statusa porudzbine.',
      DETAIL = format('order_id=%s, old_status=%s, new_status=%s', NEW.id, OLD.status, NEW.status),
      HINT = 'Dozvoljeno: sent->accepted/rejected; accepted->shipped/cancelled_by_seller; shipped->delivered/cancelled_by_seller; rejected/cancelled_by_seller/delivered->arhivirano.';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enforce_order_status_transition ON public.orders;
CREATE TRIGGER trg_enforce_order_status_transition
  BEFORE UPDATE OF status ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_order_status_transition();
