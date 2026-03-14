-- Data autofix based on audit_product_ordering suggestions.
-- Safe scope:
-- 1) Fix invalid step where order_step > min_quantity by clamping to min_quantity.
-- 2) Apply unit/min/step suggestion only for rows explicitly flagged with unit mismatch.

WITH audit AS (
  SELECT *
  FROM public.audit_product_ordering(5000)
),
step_fix AS (
  UPDATE public.products p
  SET order_step = p.min_order_kg
  FROM audit a
  WHERE a.product_id = p.id
    AND 'order_step>min_quantity' = ANY (a.issues)
    AND p.min_order_kg > 0
    AND p.order_step > p.min_order_kg
  RETURNING p.id
)
SELECT COUNT(*) AS fixed_steps
FROM step_fix;

WITH audit AS (
  SELECT *
  FROM public.audit_product_ordering(5000)
),
unit_fix AS (
  UPDATE public.products p
  SET
    unit_type = a.suggested_unit,
    min_order_kg = a.suggested_min,
    order_step = a.suggested_step
  FROM audit a
  WHERE a.product_id = p.id
    AND 'unit_differs_from_suggestion' = ANY (a.issues)
    AND a.suggested_unit IN ('kg', 'L', 'g', 'kom')
    AND a.suggested_min > 0
    AND a.suggested_step > 0
  RETURNING p.id
)
SELECT COUNT(*) AS fixed_units
FROM unit_fix;
