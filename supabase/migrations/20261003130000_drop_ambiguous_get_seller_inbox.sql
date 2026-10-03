-- Uklanjanje zastarele verzije funkcije sa jednim argumentom
-- kako bi se sprečila PGRST203 ambiguous function greška u PostgREST-u.
-- Aktivna funkcija je get_seller_inbox(p_seller_id UUID, p_limit INT DEFAULT 20, p_offset INT DEFAULT 0).

DROP FUNCTION IF EXISTS public.get_seller_inbox(UUID);
