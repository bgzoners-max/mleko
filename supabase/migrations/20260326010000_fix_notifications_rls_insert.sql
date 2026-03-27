-- Omogući backend sistemima da kreiraju notifikacije
-- Zadržavamo SELECT politiku da korisnici vide samo svoje
-- Dodajemo INSERT politiku za system/triggers

-- Prvo, hajde da vidimo šta imamo
DROP POLICY IF EXISTS "Users manage own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users see own notifications" ON public.notifications;

-- SELECT: Korisnici vide samo svoje notifikacije
CREATE POLICY "Users see own notifications"
  ON public.notifications FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- INSERT: Backend sistemi (trigger, Edge Functions) mogu da kreiraju notifikacije
-- Bez provere auth.uid() da backend može da kreira notifikacije za druge korisnike
CREATE POLICY "System can create notifications"
  ON public.notifications FOR INSERT
  TO authenticated, service_role
  WITH CHECK (true);

-- UPDATE: Samo korisnik može da ažurira svoje notifikacije (npr. mark as read)
CREATE POLICY "Users update own notifications"
  ON public.notifications FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- DELETE: Korisnik može da briše svoje notifikacije
CREATE POLICY "Users delete own notifications"
  ON public.notifications FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);
