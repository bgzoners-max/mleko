-- Statistika prodavca: broj porudžbina, prosečna ocena, prosečno vreme odgovora
-- Sve se računa na nivou baze (COUNT, AVG) — bez iteracije na klijentu.

CREATE OR REPLACE FUNCTION public.get_seller_stats(p_seller_id UUID)
RETURNS JSON
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH
    -- Broj isporučenih porudžbina
    order_stats AS (
      SELECT COUNT(*)::int AS delivered_count
      FROM public.orders
      WHERE seller_id = p_seller_id
        AND status = 'delivered'
    ),

    -- Prosečna ocena i broj recenzija
    rating_stats AS (
      SELECT
        COUNT(*)::int                          AS review_count,
        ROUND(AVG(rating)::numeric, 1)::float  AS avg_rating
      FROM public.reviews
      WHERE seller_id = p_seller_id
    ),

    -- Prva porudžbina svakog kupca prema ovom prodavcu
    first_orders AS (
      SELECT DISTINCT ON (buyer_id)
        buyer_id,
        created_at AS order_created_at
      FROM public.orders
      WHERE seller_id = p_seller_id
      ORDER BY buyer_id, created_at ASC
    ),

    -- Prva poruka prodavca u razgovoru sa svakim kupcem
    first_replies AS (
      SELECT
        c.buyer_id,
        MIN(m.created_at) AS first_reply_at
      FROM public.conversations c
      JOIN public.messages m
        ON m.conversation_id = c.id
       AND m.sender_id       = p_seller_id
      WHERE c.seller_id = p_seller_id
      GROUP BY c.buyer_id
    ),

    -- Razlika u satima (samo pozitivne, max 7 dana da se filtriraju outlieri)
    response_times AS (
      SELECT
        EXTRACT(EPOCH FROM (fr.first_reply_at - fo.order_created_at)) / 3600.0 AS hours
      FROM first_orders fo
      JOIN first_replies fr ON fr.buyer_id = fo.buyer_id
      WHERE fr.first_reply_at > fo.order_created_at
        AND EXTRACT(EPOCH FROM (fr.first_reply_at - fo.order_created_at)) / 3600.0 < 168
    )

  SELECT json_build_object(
    'orders_count',        (SELECT delivered_count FROM order_stats),
    'avg_rating',          (SELECT avg_rating       FROM rating_stats),
    'review_count',        (SELECT review_count     FROM rating_stats),
    'avg_response_hours',  (SELECT AVG(hours)::float FROM response_times)
  );
$$;

-- Dostupno i anonimnim korisnicima (profil prodavca je javan)
GRANT EXECUTE ON FUNCTION public.get_seller_stats(UUID) TO anon, authenticated;
