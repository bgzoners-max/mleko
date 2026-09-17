-- ============================================================================
-- Usklađivanje: Prirodni korak za komadne proizvode (unit_type = 'kom')
-- Datum: 2026-09-17
--
-- PROBLEM:
-- Heuristički korak 10 za unit_type = 'kom' sprečava naručivanje manjih ili
-- fleksibilnih količina (npr. 6 jaja, 1 kokoška, 1 tegla/komad) i može dovesti
-- do kršenja constraint-a (min_order_kg deljivo sa order_step i order_step <= min_order_kg).
--
-- REŠENJE:
-- `order_step = LEAST(1, min_order_kg)`:
--   - min_order_kg >= 1 -> step = 1 (prirodni korak od 1 komada),
--   - min_order_kg  < 1 -> step = min_order_kg (poštuje CHECK order_step <= min_order_kg).
--
-- NAPOMENA o alignment CHECK-u: `products_min_order_step_alignment_check`
-- (dodat u 20260916100000) zahteva da min_order_kg bude tačan umnožak
-- order_step-a. Za necelobrojni min_order_kg >= 1 (npr. 3.5), step = 1 bi taj
-- CHECK kršio, ali takva (min, step) kombinacija ne može postojati u stanju u
-- kom se ova migracija izvršava: 20260916100000 je prethodno uskladila podatke
-- i aktivirala validirani CHECK, pa WHERE ovde u konzistentnom stanju ne hvata
-- nijednu liniju. Ipak, ako se nađe nekonzistentna linija, poslednji DO blok
-- prekida migraciju uz jasnu poruku (umesto tihog kvara ili enigmatične
-- constraint greške).
-- ============================================================================

UPDATE public.products
SET order_step = LEAST(1, min_order_kg)
WHERE unit_type = 'kom'
  AND order_step > 0
  AND min_order_kg > 0
  AND (
    order_step > min_order_kg
    OR abs(min_order_kg - (ROUND(min_order_kg / order_step) * order_step)) > 0.000001
  );

-- Konačni integritetni ček: ako i dalje postoji kom proizvod koji ne zadovoljava
-- constraint-e (npr. zbog nevalidne postojeće vrednosti), migracija se prekida
-- uz jasnu poruku, a transakcija se vraća u početno stanje.
DO $$
DECLARE
  v_problems INT;
BEGIN
  SELECT count(*)
    INTO v_problems
    FROM public.products
   WHERE unit_type = 'kom'
     AND (
       order_step <= 0
       OR min_order_kg <= 0
       OR order_step > min_order_kg
       OR CASE
            WHEN order_step > 0 THEN
              abs(min_order_kg - (ROUND(min_order_kg / order_step) * order_step)) > 0.000001
            ELSE TRUE
          END
     );

  IF v_problems > 0 THEN
    RAISE EXCEPTION
      'Prekid migracije: % kom proizvoda ne zadovoljava order_step/min_order_kg constraint-e.',
      v_problems;
  END IF;
END;
$$;
