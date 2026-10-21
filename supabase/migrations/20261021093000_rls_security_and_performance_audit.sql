-- ============================================================================
-- Migracija: 20261021093000_rls_security_and_performance_audit.sql
-- Naziv: Sveobuhvatna RLS revizija, bezbednost baze i InitPlan optimizacija
--
-- Obuhvat revizije:
-- 1. PRIVATNOST KORISNIKA (SEC-P1):
--    - Zaštita kolone `address` na `public.profiles` (REVOKE SELECT za anon/authenticated).
--    - Maskiranje adrese u `public.public_profiles` view-u (vidljiva samo vlasniku i adminu).
--
-- 2. SECURITY DEFINER OČVRŠĆAVANJE (SEC-P2):
--    - Dodavanje `SET search_path = public` i `STABLE` atributa na funkciju `public.is_admin()`.
--
-- 3. RLS PERFORMANSE (SEC-P3 - InitPlan keširanje):
--    - Zamenjen "naked" `auth.uid()` sa `(SELECT auth.uid())` u svim preostalim polisama,
--      što omogućava Postgres query optimizer-u jednokratno računanje identiteta po upitu
--      (InitPlan) umesto evaluacije po svakom skeniranom redu (10x-100x ubrzanje).
--
-- 4. ADMINISTRACIJA I MODERACIJA (SEC-P4):
--    - Dozvoljeno administratorima da brišu nedozvoljene proizvode (`products`)
--      i pregledaju sve podnete prijave za moderaciju (`classified_ad_reports`).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. PRIVATNOST: Zaštita adrese kupca (public.profiles i public_profiles view)
-- ----------------------------------------------------------------------------

-- 1.1 Oduzimanje direktnog SELECT prava nad kolonom address za nelicencirane uloge
REVOKE SELECT (address) ON public.profiles FROM anon, authenticated;

-- Osiguraj da prijavljeni korisnik može unositi i ažurirati svoju adresu
GRANT INSERT (address), UPDATE (address) ON public.profiles TO authenticated;

-- 1.2 Očvršćavanje funkcije is_admin() pre ažuriranja view-a
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = (SELECT auth.uid()) AND is_admin = true
  );
$$;

REVOKE ALL ON FUNCTION public.is_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated, service_role;

-- 1.3 Rekonstrukcija public_profiles view-a sa maskiranom adresom
CREATE OR REPLACE VIEW public.public_profiles AS
SELECT
  p.id,
  CASE WHEN ((SELECT auth.uid()) = p.id OR (SELECT public.is_admin())) THEN p.email ELSE NULL END AS email,
  CASE WHEN (p.phone_public OR (SELECT auth.uid()) = p.id OR (SELECT public.is_admin())) THEN p.phone ELSE NULL END AS phone,
  p.display_name,
  p.city,
  p.postal_code,
  p.role,
  p.is_guest,
  p.farm_name,
  p.location,
  p.profile_image_url,
  p.phone_public,
  p.is_verified,
  p.seller_story,
  p.farm_gallery_urls,
  p.seller_tags,
  p.seller_quick_replies,
  p.is_admin,
  p.lat,
  p.lng,
  p.created_at,
  CASE WHEN ((SELECT auth.uid()) = p.id OR (SELECT public.is_admin())) THEN p.address ELSE NULL END AS address
FROM public.profiles p;

GRANT SELECT ON public.public_profiles TO anon, authenticated;


-- ----------------------------------------------------------------------------
-- 2. PRODUCTS: InitPlan optimizacija i admin moderacija
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Products are viewable by everyone" ON public.products;
CREATE POLICY "Products are viewable by everyone" ON public.products
  FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "Authenticated users can create products" ON public.products;
CREATE POLICY "Authenticated users can create products" ON public.products
  FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = seller_id);

DROP POLICY IF EXISTS "Sellers can update own products" ON public.products;
CREATE POLICY "Sellers can update own products" ON public.products
  FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = seller_id OR (SELECT public.is_admin()))
  WITH CHECK ((SELECT auth.uid()) = seller_id OR (SELECT public.is_admin()));

DROP POLICY IF EXISTS "Sellers can delete own products" ON public.products;
CREATE POLICY "Sellers can delete own products" ON public.products
  FOR DELETE TO authenticated
  USING ((SELECT auth.uid()) = seller_id OR (SELECT public.is_admin()));


-- ----------------------------------------------------------------------------
-- 3. ORDER_ITEMS: InitPlan optimizacija
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Order items visible to buyer and seller" ON public.order_items;
CREATE POLICY "Order items visible to buyer and seller" ON public.order_items
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.orders o
      WHERE o.id = order_id
        AND ((SELECT auth.uid()) = o.buyer_id OR (SELECT auth.uid()) = o.seller_id OR (SELECT public.is_admin()))
    )
  );

DROP POLICY IF EXISTS "Buyers can insert order items" ON public.order_items;
CREATE POLICY "Buyers can insert order items" ON public.order_items
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.orders o
      WHERE o.id = order_id
        AND (SELECT auth.uid()) = o.buyer_id
    )
  );


-- ----------------------------------------------------------------------------
-- 4. CLASSIFIED_ADS: InitPlan optimizacija i eksplicitna uloga
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "classified_ads_read_active" ON public.classified_ads;
CREATE POLICY "classified_ads_read_active" ON public.classified_ads
  FOR SELECT
  USING (status = 'active' OR (SELECT auth.uid()) = user_id OR (SELECT public.is_admin()));

DROP POLICY IF EXISTS "classified_ads_insert_auth" ON public.classified_ads;
CREATE POLICY "classified_ads_insert_auth" ON public.classified_ads
  FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "classified_ads_update_owner" ON public.classified_ads;
CREATE POLICY "classified_ads_update_owner" ON public.classified_ads
  FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = user_id OR (SELECT public.is_admin()))
  WITH CHECK ((SELECT auth.uid()) = user_id OR (SELECT public.is_admin()));

DROP POLICY IF EXISTS "classified_ads_delete_owner" ON public.classified_ads;
CREATE POLICY "classified_ads_delete_owner" ON public.classified_ads
  FOR DELETE TO authenticated
  USING ((SELECT auth.uid()) = user_id OR (SELECT public.is_admin()));


-- ----------------------------------------------------------------------------
-- 5. CHAT & REALTIME: conversations, messages, typing, reactions
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Users see own conversations" ON public.conversations;
CREATE POLICY "Users see own conversations" ON public.conversations
  FOR ALL TO authenticated
  USING ((SELECT auth.uid()) = buyer_id OR (SELECT auth.uid()) = seller_id)
  WITH CHECK ((SELECT auth.uid()) = buyer_id OR (SELECT auth.uid()) = seller_id);

DROP POLICY IF EXISTS "Participants see messages" ON public.messages;
CREATE POLICY "Participants see messages" ON public.messages
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = conversation_id
        AND (c.buyer_id = (SELECT auth.uid()) OR c.seller_id = (SELECT auth.uid()))
    )
  );

DROP POLICY IF EXISTS "Participants insert messages" ON public.messages;
CREATE POLICY "Participants insert messages" ON public.messages
  FOR INSERT TO authenticated
  WITH CHECK (
    (SELECT auth.uid()) = sender_id
    AND EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = conversation_id
        AND (c.buyer_id = (SELECT auth.uid()) OR c.seller_id = (SELECT auth.uid()))
    )
  );

DROP POLICY IF EXISTS "Participants see typing state" ON public.conversation_typing;
CREATE POLICY "Participants see typing state" ON public.conversation_typing
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = conversation_id
        AND (c.buyer_id = (SELECT auth.uid()) OR c.seller_id = (SELECT auth.uid()))
    )
  );

DROP POLICY IF EXISTS "Participants upsert own typing state" ON public.conversation_typing;
CREATE POLICY "Participants upsert own typing state" ON public.conversation_typing
  FOR INSERT TO authenticated
  WITH CHECK (
    (SELECT auth.uid()) = user_id
    AND EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = conversation_id
        AND (c.buyer_id = (SELECT auth.uid()) OR c.seller_id = (SELECT auth.uid()))
    )
  );

DROP POLICY IF EXISTS "Participants update own typing state" ON public.conversation_typing;
CREATE POLICY "Participants update own typing state" ON public.conversation_typing
  FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Participants see reactions" ON public.message_reactions;
CREATE POLICY "Participants see reactions" ON public.message_reactions
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = conversation_id
        AND (c.buyer_id = (SELECT auth.uid()) OR c.seller_id = (SELECT auth.uid()))
    )
  );

DROP POLICY IF EXISTS "Participants manage own reactions" ON public.message_reactions;
CREATE POLICY "Participants manage own reactions" ON public.message_reactions
  FOR ALL TO authenticated
  USING (
    (SELECT auth.uid()) = user_id
    AND EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = conversation_id
        AND (c.buyer_id = (SELECT auth.uid()) OR c.seller_id = (SELECT auth.uid()))
    )
  )
  WITH CHECK (
    (SELECT auth.uid()) = user_id
    AND EXISTS (
      SELECT 1 FROM public.conversations c
      WHERE c.id = conversation_id
        AND (c.buyer_id = (SELECT auth.uid()) OR c.seller_id = (SELECT auth.uid()))
    )
  );


-- ----------------------------------------------------------------------------
-- 6. SUPPORT TICKETS & MESSAGES: InitPlan optimizacija
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "insert_own_ticket" ON public.support_tickets;
CREATE POLICY "insert_own_ticket" ON public.support_tickets
  FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "select_own_tickets" ON public.support_tickets;
CREATE POLICY "select_own_tickets" ON public.support_tickets
  FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "admin_select_all_tickets" ON public.support_tickets;
CREATE POLICY "admin_select_all_tickets" ON public.support_tickets
  FOR SELECT TO authenticated
  USING ((SELECT public.is_admin()));

DROP POLICY IF EXISTS "admin_update_tickets" ON public.support_tickets;
CREATE POLICY "admin_update_tickets" ON public.support_tickets
  FOR UPDATE TO authenticated
  USING ((SELECT public.is_admin()));

DROP POLICY IF EXISTS "user_select_ticket_messages" ON public.support_ticket_messages;
CREATE POLICY "user_select_ticket_messages" ON public.support_ticket_messages
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.support_tickets t
      WHERE t.id = ticket_id AND t.user_id = (SELECT auth.uid())
    )
  );

DROP POLICY IF EXISTS "user_insert_ticket_message" ON public.support_ticket_messages;
CREATE POLICY "user_insert_ticket_message" ON public.support_ticket_messages
  FOR INSERT TO authenticated
  WITH CHECK (
    sender_id = (SELECT auth.uid())
    AND sender_role = 'user'
    AND EXISTS (
      SELECT 1 FROM public.support_tickets t
      WHERE t.id = ticket_id AND t.user_id = (SELECT auth.uid())
        AND t.status <> 'zatvoren'
    )
  );

DROP POLICY IF EXISTS "admin_select_ticket_messages" ON public.support_ticket_messages;
CREATE POLICY "admin_select_ticket_messages" ON public.support_ticket_messages
  FOR SELECT TO authenticated
  USING ((SELECT public.is_admin()));

DROP POLICY IF EXISTS "admin_insert_ticket_message" ON public.support_ticket_messages;
CREATE POLICY "admin_insert_ticket_message" ON public.support_ticket_messages
  FOR INSERT TO authenticated
  WITH CHECK (
    sender_id = (SELECT auth.uid())
    AND sender_role = 'admin'
    AND (SELECT public.is_admin())
  );


-- ----------------------------------------------------------------------------
-- 7. KORISNIČKI RESURSI: favorites, favorite_sellers, push_tokens, user_prefs, notifications
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Users manage own favorites" ON public.favorites;
CREATE POLICY "Users manage own favorites" ON public.favorites
  FOR ALL TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users manage own favorite sellers" ON public.favorite_sellers;
CREATE POLICY "Users manage own favorite sellers" ON public.favorite_sellers
  FOR ALL TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users manage own push tokens" ON public.user_push_tokens;
CREATE POLICY "Users manage own push tokens" ON public.user_push_tokens
  FOR ALL TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users manage own conversation prefs" ON public.conversation_user_prefs;
CREATE POLICY "Users manage own conversation prefs" ON public.conversation_user_prefs
  FOR ALL TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users update own notifications" ON public.notifications;
CREATE POLICY "Users update own notifications" ON public.notifications
  FOR UPDATE TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users delete own notifications" ON public.notifications;
CREATE POLICY "Users delete own notifications" ON public.notifications
  FOR DELETE TO authenticated
  USING ((SELECT auth.uid()) = user_id);


-- ----------------------------------------------------------------------------
-- 8. TRUST, REVIEWS & REPORTS
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Buyers can insert own reviews" ON public.reviews;
CREATE POLICY "Buyers can insert own reviews" ON public.reviews
  FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = buyer_id);

DROP POLICY IF EXISTS "Sellers can insert buyer reviews" ON public.buyer_reviews;
CREATE POLICY "Sellers can insert buyer reviews" ON public.buyer_reviews
  FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = seller_id);

DROP POLICY IF EXISTS "classified_ad_reports_insert_own" ON public.classified_ad_reports;
CREATE POLICY "classified_ad_reports_insert_own" ON public.classified_ad_reports
  FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) = reporter_id);

DROP POLICY IF EXISTS "classified_ad_reports_select_own" ON public.classified_ad_reports;
CREATE POLICY "classified_ad_reports_select_own" ON public.classified_ad_reports
  FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = reporter_id OR (SELECT public.is_admin()));


-- ----------------------------------------------------------------------------
-- 9. DOSTAVA: seller_delivery_points, seller_delivery_slots, product_delivery_points
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Sellers manage own delivery points" ON public.seller_delivery_points;
CREATE POLICY "Sellers manage own delivery points" ON public.seller_delivery_points
  FOR ALL TO authenticated
  USING ((SELECT auth.uid()) = seller_id)
  WITH CHECK ((SELECT auth.uid()) = seller_id);

DROP POLICY IF EXISTS "Sellers manage own delivery slots" ON public.seller_delivery_slots;
CREATE POLICY "Sellers manage own delivery slots" ON public.seller_delivery_slots
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.seller_delivery_points p
      WHERE p.id = delivery_point_id AND p.seller_id = (SELECT auth.uid())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.seller_delivery_points p
      WHERE p.id = delivery_point_id AND p.seller_id = (SELECT auth.uid())
    )
  );

DROP POLICY IF EXISTS "Sellers manage own product delivery points" ON public.product_delivery_points;
CREATE POLICY "Sellers manage own product delivery points" ON public.product_delivery_points
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.products p
      WHERE p.id = product_id AND p.seller_id = (SELECT auth.uid())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.products p
      WHERE p.id = product_id AND p.seller_id = (SELECT auth.uid())
    )
  );

DROP POLICY IF EXISTS "Order participants can view status audit logs" ON public.order_status_audit_logs;
CREATE POLICY "Order participants can view status audit logs" ON public.order_status_audit_logs
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.orders o
      WHERE o.id = order_id
        AND ((SELECT auth.uid()) = o.buyer_id OR (SELECT auth.uid()) = o.seller_id OR (SELECT public.is_admin()))
    )
  );
