-- Paket 3: Atomična registracija push tokena (SECURITY DEFINER RPC) i admin uvid u porudžbine
-- 1. Rešava problem na deljenim uređajima gde RLS na user_push_tokens tiho blokira
--    brisanje tokena prethodnog korisnika (što zatim ruši upsert zbog UNIQUE(token)).
-- 2. Omogućava administratorima pregled svih porudžbina (npr. admin dashboard statistika)
--    bez otvaranja pristupa ostalim korisnicima.

-- ============================================================================
-- 1. SECURITY DEFINER RPC za atomičnu registraciju push tokena
-- ============================================================================
CREATE OR REPLACE FUNCTION public.register_push_token(
  p_installation_id TEXT,
  p_token TEXT,
  p_platform TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_installation_id TEXT := btrim(COALESCE(p_installation_id, ''));
  v_token TEXT := btrim(COALESCE(p_token, ''));
  v_platform TEXT := lower(btrim(COALESCE(p_platform, '')));
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF v_installation_id = '' OR length(v_installation_id) > 256 THEN
    RAISE EXCEPTION 'Invalid installation_id';
  END IF;

  IF v_token = '' OR length(v_token) > 4096 THEN
    RAISE EXCEPTION 'Invalid push token';
  END IF;

  IF v_platform NOT IN ('android', 'ios', 'web') THEN
    RAISE EXCEPTION 'Invalid push platform';
  END IF;

  -- Ukloni stare zapise za ovu instalaciju drugih korisnika kao i bilo koji stari zapis
  -- koji drži identičan FCM token (npr. promena naloga ili reinstalacija aplikacije).
  DELETE FROM public.user_push_tokens
  WHERE (installation_id = v_installation_id AND user_id <> v_uid)
     OR (token = v_token AND (user_id <> v_uid OR installation_id <> v_installation_id));

  -- Atomični upsert tokena za aktivnog korisnika i trenutnu instalaciju.
  INSERT INTO public.user_push_tokens (
    user_id,
    installation_id,
    token,
    platform,
    updated_at
  )
  VALUES (
    v_uid,
    v_installation_id,
    v_token,
    v_platform,
    NOW()
  )
  ON CONFLICT (user_id, installation_id)
  DO UPDATE SET
    token = EXCLUDED.token,
    platform = EXCLUDED.platform,
    updated_at = NOW();
END;
$$;

REVOKE ALL ON FUNCTION public.register_push_token(TEXT, TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.register_push_token(TEXT, TEXT, TEXT) TO authenticated, service_role;

-- ============================================================================
-- 2. Admin SELECT uvid na public.orders (za admin panel i metrike)
-- ============================================================================
DROP POLICY IF EXISTS "Buyers and sellers can view their orders" ON public.orders;

CREATE POLICY "Buyers and sellers can view their orders" ON public.orders
  FOR SELECT TO authenticated
  USING (
    (SELECT auth.uid()) = buyer_id
    OR (SELECT auth.uid()) = seller_id
    OR (SELECT public.is_admin())
  );
