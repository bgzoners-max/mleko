-- Enforce 100g ordering step for kackavalj products.
-- Rule: order_step = 0.1 kg when unit is kg and min_order_kg >= 0.1.

UPDATE public.products
SET order_step = 0.1
WHERE unit_type = 'kg'
  AND min_order_kg >= 0.1
  AND (
    lower(category) LIKE '%ka%kavalj%'
    OR lower(name) LIKE '%ka%kavalj%'
  );
