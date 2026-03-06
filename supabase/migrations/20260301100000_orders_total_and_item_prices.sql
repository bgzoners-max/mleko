-- orders: ukupna suma porudžbine (za spec: total_amount)
ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS total_amount NUMERIC;

-- order_items: cena po jedinici i ukupno po stavci (za spec)
ALTER TABLE public.order_items
  ADD COLUMN IF NOT EXISTS unit_price NUMERIC;
ALTER TABLE public.order_items
  ADD COLUMN IF NOT EXISTS total_price NUMERIC;
