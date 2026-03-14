-- Enforce explicit product order step bounds in database.
-- Rule: order_step must be positive and cannot exceed min_order_kg.

UPDATE public.products
SET min_order_kg = 1
WHERE min_order_kg IS NULL OR min_order_kg <= 0;

UPDATE public.products
SET order_step = min_order_kg
WHERE order_step IS NULL OR order_step <= 0 OR order_step > min_order_kg;

ALTER TABLE public.products
  DROP CONSTRAINT IF EXISTS products_min_order_positive;

ALTER TABLE public.products
  ADD CONSTRAINT products_min_order_positive
  CHECK (min_order_kg > 0);

ALTER TABLE public.products
  DROP CONSTRAINT IF EXISTS products_order_step_lte_min_order;

ALTER TABLE public.products
  ADD CONSTRAINT products_order_step_lte_min_order
  CHECK (order_step <= min_order_kg);
