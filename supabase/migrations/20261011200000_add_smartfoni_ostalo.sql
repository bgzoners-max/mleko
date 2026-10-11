-- ============================================================================
-- Migracija: Dodavanje "Ostale marke" za Pametne telefone (smartfoni)
-- Omogućava postavljanje oglasa za brendove koji nisu na eksplicitnom spisku,
-- čuvajući pravilo da oglas uvek ide do krajnjeg lista (leaf čvora).
-- ============================================================================

INSERT INTO public.classified_categories (id, name, icon_name, parent_id, sort_order)
VALUES
    ('smartfoni_ostalo', 'Ostale marke', 'smartphone', 'smartfoni', 999)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    icon_name = EXCLUDED.icon_name,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order;
