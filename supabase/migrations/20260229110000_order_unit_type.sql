-- Jedinica u porudžbini (kg ili L) za prikaz količine
ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS unit_type text NOT NULL DEFAULT 'kg'
  CHECK (unit_type IN ('kg', 'L'));

ALTER TABLE public.order_items
  ADD COLUMN IF NOT EXISTS unit_type text NOT NULL DEFAULT 'kg'
  CHECK (unit_type IN ('kg', 'L'));
