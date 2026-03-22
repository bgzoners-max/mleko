-- Kupac mora moći UPDATE (ručno arhiviranje, itd.). Do sada je postojala samo prodavčeva UPDATE politika.
DROP POLICY IF EXISTS "Buyers can update own orders" ON public.orders;
CREATE POLICY "Buyers can update own orders" ON public.orders
  FOR UPDATE TO authenticated
  USING (auth.uid() = buyer_id)
  WITH CHECK (auth.uid() = buyer_id);
