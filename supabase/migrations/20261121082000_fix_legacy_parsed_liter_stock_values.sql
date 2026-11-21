-- Ispravka zaliha (available_kg) za proizvode u litrima (unit_type = 'L', min_order_kg >= 1)
-- kojima je stara heuristika parseQuantityL (val >= 50 -> val / 1000) pri čuvanju
-- podelila unete litre sa 1000 (npr. 500 L -> 0.5 L / 500 ml, 300 L -> 0.3 L, 200 L -> 0.2 L).

UPDATE public.products
SET available_kg = ROUND(available_kg * 1000, 3)
WHERE unit_type = 'L'
  AND min_order_kg >= 1
  AND available_kg > 0
  AND available_kg < 1;
