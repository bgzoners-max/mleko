-- Omogući kaskadno/bezbedno brisanje proizvoda kada postoje istorijske stavke porudžbina
-- Kolona product_id u order_items ima strani ključ sa ON DELETE SET NULL, pa mora biti NULLABLE.
ALTER TABLE public.order_items ALTER COLUMN product_id DROP NOT NULL;
