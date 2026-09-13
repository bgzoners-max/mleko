-- Migracija za admin moderaciju prijavljenih oglasa (Faza 7)
-- Datum: 2026-09-11

-- 1. RLS politike za admine na tabeli classified_ad_reports
DROP POLICY IF EXISTS "classified_ad_reports_select_admin" ON public.classified_ad_reports;
CREATE POLICY "classified_ad_reports_select_admin"
ON public.classified_ad_reports
FOR SELECT
TO authenticated
USING (public.is_admin());

DROP POLICY IF EXISTS "classified_ad_reports_update_admin" ON public.classified_ad_reports;
CREATE POLICY "classified_ad_reports_update_admin"
ON public.classified_ad_reports
FOR UPDATE
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "classified_ad_reports_delete_admin" ON public.classified_ad_reports;
CREATE POLICY "classified_ad_reports_delete_admin"
ON public.classified_ad_reports
FOR DELETE
TO authenticated
USING (public.is_admin());

-- 2. Sigurna RPC funkcija za sprovođenje moderatorskih akcija
CREATE OR REPLACE FUNCTION public.moderate_classified_ad(
  p_report_id UUID,
  p_ad_id UUID,
  p_action TEXT,
  p_note TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller_id UUID := auth.uid();
  v_ad_title TEXT;
  v_seller_id UUID;
BEGIN
  -- Sigurnosna provera: samo administratori
  IF v_caller_id IS NULL OR NOT public.is_admin() THEN
    RAISE EXCEPTION 'Pristup odbijen: samo administratori mogu vršiti moderaciju oglasa.';
  END IF;

  -- Dohvati podatke o oglasu
  SELECT title, user_id INTO v_ad_title, v_seller_id
  FROM public.classified_ads
  WHERE id = p_ad_id;

  IF p_action = 'dismiss' THEN
    -- Odbacivanje prijave (npr. neosnovana prijava, oglas ostaje kakav jeste)
    UPDATE public.classified_ad_reports
    SET status = 'dismissed',
        resolved_at = now(),
        resolved_by = v_caller_id
    WHERE id = p_report_id;

    RETURN jsonb_build_object(
      'success', true,
      'action', 'dismiss',
      'report_id', p_report_id
    );

  ELSIF p_action = 'resolve_reviewed' THEN
    -- Oglas je pregledan i potvrđen kao ispravan
    UPDATE public.classified_ad_reports
    SET status = 'reviewed',
        resolved_at = now(),
        resolved_by = v_caller_id
    WHERE id = p_report_id;

    RETURN jsonb_build_object(
      'success', true,
      'action', 'resolve_reviewed',
      'report_id', p_report_id
    );

  ELSIF p_action = 'deactivate_ad' THEN
    -- Deaktivacija oglasa (status 'rejected') i rešavanje svih prijava za taj oglas
    UPDATE public.classified_ads
    SET status = 'rejected',
        updated_at = now()
    WHERE id = p_ad_id;

    UPDATE public.classified_ad_reports
    SET status = 'ad_removed',
        resolved_at = now(),
        resolved_by = v_caller_id
    WHERE ad_id = p_ad_id AND status = 'pending';

    -- Slanje sistemske notifikacije oglašivaču ako oglas i oglašivač postoje
    IF v_seller_id IS NOT NULL THEN
      INSERT INTO public.notifications (
        user_id,
        classified_ad_id,
        type,
        title,
        body
      ) VALUES (
        v_seller_id,
        p_ad_id,
        'classified_ad_moderation',
        'Vaš oglas je uklonjen nakon moderacije',
        COALESCE(
          p_note,
          'Vaš oglas "' || COALESCE(v_ad_title, 'nepoznat') || '" je uklonjen iz pretrage jer krši pravila i smernice platforme.'
        )
      );
    END IF;

    RETURN jsonb_build_object(
      'success', true,
      'action', 'deactivate_ad',
      'ad_id', p_ad_id
    );

  ELSE
    RAISE EXCEPTION 'Nepoznata moderatorska akcija: %', p_action;
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.moderate_classified_ad(UUID, UUID, TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.moderate_classified_ad(UUID, UUID, TEXT, TEXT) TO authenticated, service_role;
