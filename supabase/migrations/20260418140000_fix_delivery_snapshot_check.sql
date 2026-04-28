-- Fix orders_delivery_snapshot_required_check to allow courier and pickup
-- without requiring delivery snapshot fields (which are only needed for seller_delivery).

ALTER TABLE public.orders
  DROP CONSTRAINT IF EXISTS orders_delivery_snapshot_required_check;

ALTER TABLE public.orders
  ADD CONSTRAINT orders_delivery_snapshot_required_check
  CHECK (
    delivery_method IN ('agreement', 'courier', 'pickup')
    OR (
      delivery_method = 'seller_delivery'
      AND delivery_city IS NOT NULL
      AND delivery_point_label IS NOT NULL
      AND delivery_address IS NOT NULL
      AND delivery_weekday IS NOT NULL
      AND delivery_time_from IS NOT NULL
      AND delivery_time_to IS NOT NULL
    )
  );
