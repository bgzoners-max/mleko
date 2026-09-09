-- ============================================================================
-- Migracija 20260909200000: Ispravke za preglede oglasa, moderaciju i push tajne
--
-- 1. increment_classified_ad_views:
--    - Omogućava anonimnim posetiocima (anon) beleženje pregleda
--    - Sprečava vlasnika oglasa da uvećava sopstveni brojač
--    - Uklanja globalni 60s blok koji je gušio legitimne istovremene posete
-- 2. admin_moderate_classified_ad:
--    - Proširenje dozvoljenih statusa na svih 5 iz CHECK constraint-a:
--      ('active', 'sold', 'archived', 'rejected', 'flagged')
-- 3. invoke_send_push:
--    - Podrška za Supabase Vault (vault.decrypted_secrets) uz fallback na edge_config
--      radi bezbedne rotacije anon/service ključeva van migracija
-- ============================================================================

-- 1) Poboljšana funkcija za brojanje pregleda oglasa
CREATE OR REPLACE FUNCTION public.increment_classified_ad_views(ad_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user  UUID := auth.uid();
  v_owner UUID;
  v_status TEXT;
BEGIN
  -- Pronađi vlasnika i status oglasa
  SELECT user_id, status
    INTO v_owner, v_status
  FROM public.classified_ads
  WHERE id = ad_id;

  IF NOT FOUND THEN
    RETURN;
  END IF;

  -- Samo aktivni oglasi dobijaju preglede
  IF v_status <> 'active' THEN
    RETURN;
  END IF;

  -- Vlasnik oglasa ne povećava sopstveni brojač pregleda
  IF v_user IS NOT NULL AND v_user = v_owner THEN
    RETURN;
  END IF;

  -- Inkrementiraj brojač i zabeleži vreme poslednjeg pregleda
  UPDATE public.classified_ads
  SET views_count = views_count + 1,
      last_view_at = now()
  WHERE id = ad_id;
END;
$$;

REVOKE ALL ON FUNCTION public.increment_classified_ad_views(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.increment_classified_ad_views(UUID) TO anon, authenticated, service_role;


-- 2) Proširena admin moderacija oglasa sa podrškom za 'sold' i 'flagged'
CREATE OR REPLACE FUNCTION public.admin_moderate_classified_ad(
    p_ad_id UUID,
    p_new_status TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Pristup odbijen: samo administrator može moderisati oglase.';
  END IF;

  IF p_new_status NOT IN ('active', 'sold', 'archived', 'rejected', 'flagged') THEN
    RAISE EXCEPTION 'Nevažeći status moderacije: %', p_new_status;
  END IF;

  UPDATE public.classified_ads
  SET status = p_new_status,
      updated_at = now()
  WHERE id = p_ad_id;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_moderate_classified_ad(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_moderate_classified_ad(UUID, TEXT) TO authenticated, service_role;


-- 3) invoke_send_push sa dinamičkim čitanjem tajni iz Supabase Vault-a
CREATE OR REPLACE FUNCTION public.invoke_send_push()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  base_url TEXT;
  anon_key TEXT;
  fn_url TEXT;
BEGIN
  -- Pokušaj čitanja iz Supabase Vault-a (omogućava rotaciju bez novih SQL migracija)
  BEGIN
    SELECT decrypted_secret INTO anon_key 
    FROM vault.decrypted_secrets 
    WHERE name = 'anon_key' 
    LIMIT 1;
  EXCEPTION WHEN OTHERS THEN
    anon_key := NULL;
  END;

  BEGIN
    SELECT decrypted_secret INTO base_url 
    FROM vault.decrypted_secrets 
    WHERE name = 'functions_base_url' 
    LIMIT 1;
  EXCEPTION WHEN OTHERS THEN
    base_url := NULL;
  END;

  -- Fallback na public.edge_config tabelu ako Vault nije konfigurisan
  IF base_url IS NULL OR base_url = '' THEN
    SELECT value INTO base_url FROM public.edge_config WHERE key = 'functions_base_url' LIMIT 1;
  END IF;

  IF anon_key IS NULL OR anon_key = '' THEN
    SELECT value INTO anon_key FROM public.edge_config WHERE key = 'anon_key' LIMIT 1;
  END IF;

  IF base_url IS NULL OR base_url = '' THEN
    RETURN NEW;
  END IF;

  fn_url := base_url || '/functions/v1/send-push';

  PERFORM net.http_post(
    url := fn_url,
    body := jsonb_build_object(
      'user_id', NEW.user_id,
      'title', COALESCE(NEW.title, ''),
      'body', COALESCE(NEW.body, ''),
      'type', COALESCE(NEW.type::text, ''),
      'order_id', CASE WHEN NEW.order_id IS NOT NULL THEN NEW.order_id::text ELSE '' END,
      'ticket_id', CASE WHEN NEW.ticket_id IS NOT NULL THEN NEW.ticket_id::text ELSE '' END,
      'conversation_id', CASE WHEN NEW.conversation_id IS NOT NULL THEN NEW.conversation_id::text ELSE '' END
    ),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || COALESCE(anon_key, ''),
      'apikey', COALESCE(anon_key, '')
    ),
    timeout_milliseconds := 5000
  );

  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'invoke_send_push: %', SQLERRM;
    RETURN NEW;
END;
$$;
