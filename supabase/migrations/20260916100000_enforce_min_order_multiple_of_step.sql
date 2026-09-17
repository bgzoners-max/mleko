-- Fix existing data: align min_order_kg to the nearest multiple of order_step
-- We use GREATEST to ensure min_order_kg doesn't drop to 0, maintaining the order_step <= min_order_kg constraint.
UPDATE public.products
SET min_order_kg = GREATEST(ROUND(min_order_kg / order_step) * order_step, order_step)
WHERE abs(min_order_kg - (ROUND(min_order_kg / order_step) * order_step)) > 0.000001;

-- Add constraint to enforce alignment strictly for future inserts/updates
ALTER TABLE public.products
  ADD CONSTRAINT products_min_order_step_alignment_check
  CHECK (abs(min_order_kg - (ROUND(min_order_kg / order_step) * order_step)) <= 0.000001);
