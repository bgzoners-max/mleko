-- Admin flag na profiles
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS is_admin BOOLEAN NOT NULL DEFAULT false;

-- Funkcija za brzu proveru admin statusa
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND is_admin = true
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Eksplicitne permisije za funkciju (Best practice)
REVOKE ALL ON FUNCTION public.is_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated, service_role;

-- Admin može da čita sve tikete
DROP POLICY IF EXISTS "admin_select_all_tickets" ON support_tickets;
CREATE POLICY "admin_select_all_tickets" ON support_tickets
  FOR SELECT USING (public.is_admin());

-- Admin može da ažurira tikete (status, admin_note)
DROP POLICY IF EXISTS "admin_update_tickets" ON support_tickets;
CREATE POLICY "admin_update_tickets" ON support_tickets
  FOR UPDATE USING (public.is_admin());
