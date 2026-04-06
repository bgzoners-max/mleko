-- Admin flag na profiles
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS is_admin BOOLEAN NOT NULL DEFAULT false;

-- Admin može da čita sve tikete
DROP POLICY IF EXISTS "admin_select_all_tickets" ON support_tickets;
CREATE POLICY "admin_select_all_tickets" ON support_tickets
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );

-- Admin može da ažurira tikete (status, admin_note)
DROP POLICY IF EXISTS "admin_update_tickets" ON support_tickets;
CREATE POLICY "admin_update_tickets" ON support_tickets
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );
