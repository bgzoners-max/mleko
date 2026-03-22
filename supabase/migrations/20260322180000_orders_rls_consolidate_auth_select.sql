-- Performance: izbegavati direktan auth.uid() u RLS izrazima (per-row eval).
-- Koristi se (SELECT auth.uid()) — preporuka Supabase Database Advisor.
-- Konsolidacija: jedna permissive UPDATE politika za učesnike (kupac ili prodavac),
-- umesto više odvojenih UPDATE politika za istu ulogu.

-- Ukloni sve poznate varijante (rep + moguća imena sa hosta / Dashboard-a).
DROP POLICY IF EXISTS "Buyers and sellers can view their orders" ON public.orders;
DROP POLICY IF EXISTS "Authenticated users can create orders" ON public.orders;
DROP POLICY IF EXISTS "Sellers can update order status" ON public.orders;
DROP POLICY IF EXISTS "Buyers can update own orders" ON public.orders;
DROP POLICY IF EXISTS "Buyers can archive their orders" ON public.orders;

CREATE POLICY "Buyers and sellers can view their orders" ON public.orders
  FOR SELECT TO authenticated
  USING (
    (SELECT auth.uid()) = buyer_id OR (SELECT auth.uid()) = seller_id
  );

CREATE POLICY "Authenticated users can create orders" ON public.orders
  FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = buyer_id);

-- Jedna UPDATE politika: i kupac i prodavac (poslovna pravila i dalje na triggerima).
CREATE POLICY "Participants can update their orders" ON public.orders
  FOR UPDATE TO authenticated
  USING (
    (SELECT auth.uid()) = buyer_id OR (SELECT auth.uid()) = seller_id
  )
  WITH CHECK (
    (SELECT auth.uid()) = buyer_id OR (SELECT auth.uid()) = seller_id
  );
