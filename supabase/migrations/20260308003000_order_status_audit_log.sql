-- Audit trail for order status changes (who changed status and when).

CREATE TABLE IF NOT EXISTS public.order_status_audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  old_status TEXT NOT NULL,
  new_status TEXT NOT NULL,
  changed_by_role TEXT NOT NULL CHECK (changed_by_role IN ('buyer', 'seller', 'system')),
  changed_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_order_status_audit_logs_order_changed_at
  ON public.order_status_audit_logs (order_id, changed_at DESC);

ALTER TABLE public.order_status_audit_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Order participants can view status audit logs" ON public.order_status_audit_logs;
CREATE POLICY "Order participants can view status audit logs"
  ON public.order_status_audit_logs FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.orders o
      WHERE o.id = order_id
        AND (auth.uid() = o.buyer_id OR auth.uid() = o.seller_id)
    )
  );

GRANT SELECT ON public.order_status_audit_logs TO authenticated;

CREATE OR REPLACE FUNCTION public.log_order_status_change_audit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_actor_id UUID;
  v_actor_role TEXT;
BEGIN
  IF NEW.status IS NOT DISTINCT FROM OLD.status THEN
    RETURN NEW;
  END IF;

  v_actor_id := auth.uid();

  IF v_actor_id IS NOT NULL AND v_actor_id = NEW.buyer_id THEN
    v_actor_role := 'buyer';
  ELSIF v_actor_id IS NOT NULL AND v_actor_id = NEW.seller_id THEN
    v_actor_role := 'seller';
  ELSE
    v_actor_role := 'system';
  END IF;

  INSERT INTO public.order_status_audit_logs (
    order_id,
    old_status,
    new_status,
    changed_by_role,
    changed_by_user_id,
    changed_at
  )
  VALUES (
    NEW.id,
    OLD.status,
    NEW.status,
    v_actor_role,
    v_actor_id,
    NOW()
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_log_order_status_change_audit ON public.orders;
CREATE TRIGGER trg_log_order_status_change_audit
  AFTER UPDATE OF status ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.log_order_status_change_audit();
