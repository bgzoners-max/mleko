-- Migration: 20260917180000_secure_push_health_views_and_rpc.sql
-- R3-B: Zaštita push-health view-ova i funkcija (ograničenje pristupa isključivo administratorima)

-- 1. Oduzmi SELECT / ALL na view-ovima od anon, authenticated i PUBLIC
REVOKE ALL ON public.push_health_dashboard FROM PUBLIC, anon, authenticated;
REVOKE ALL ON public.push_health_user_issues FROM PUBLIC, anon, authenticated;

-- Osiguraj pristup za service_role
GRANT SELECT ON public.push_health_dashboard TO service_role;
GRANT SELECT ON public.push_health_user_issues TO service_role;

-- 2. Oduzmi direktno izvršavanje osnovnih push health funkcija
REVOKE EXECUTE ON FUNCTION public.push_health_summary() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.push_health_summary() TO service_role;

REVOKE EXECUTE ON FUNCTION public.push_user_health(UUID) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.push_user_health(UUID) TO service_role;

-- 3. Kreiraj SECURITY DEFINER RPC funkciju za push_health_dashboard dostupnu samo administratorima
CREATE OR REPLACE FUNCTION public.admin_get_push_health_dashboard()
RETURNS SETOF public.push_health_dashboard
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Sigurnosna provera: samo ulogovani administratori
  IF auth.uid() IS NULL OR NOT public.is_admin() THEN
    RAISE EXCEPTION 'Pristup odbijen: samo administratori mogu pristupiti push health dijagnostici.';
  END IF;

  RETURN QUERY
  SELECT *
  FROM public.push_health_dashboard;
END;
$$;

-- 4. Kreiraj SECURITY DEFINER RPC funkciju za push_health_user_issues dostupnu samo administratorima
CREATE OR REPLACE FUNCTION public.admin_get_push_health_user_issues()
RETURNS SETOF public.push_health_user_issues
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Sigurnosna provera: samo ulogovani administratori
  IF auth.uid() IS NULL OR NOT public.is_admin() THEN
    RAISE EXCEPTION 'Pristup odbijen: samo administratori mogu pristupiti podacima o problemima sa push notifikacijama korisnika.';
  END IF;

  RETURN QUERY
  SELECT *
  FROM public.push_health_user_issues
  ORDER BY latest_notification_at DESC NULLS LAST;
END;
$$;

-- 5. Dozvole na RPC funkcijama: zabrani PUBLIC, dozvoli samo authenticated i service_role
REVOKE ALL ON FUNCTION public.admin_get_push_health_dashboard() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_get_push_health_dashboard() TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.admin_get_push_health_user_issues() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_get_push_health_user_issues() TO authenticated, service_role;

COMMENT ON FUNCTION public.admin_get_push_health_dashboard() IS
'Bezbedni RPC za push health dashboard: proverava da li je pozivalac administrator pre vraćanja metrika.';

COMMENT ON FUNCTION public.admin_get_push_health_user_issues() IS
'Bezbedni RPC za push health probleme korisnika: proverava da li je pozivalac administrator pre vraćanja podataka.';
