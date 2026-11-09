-- ============================================================================
-- Migracija: 20261109210000_classified_categories_is_obsolete.sql
-- Naziv: Dodavanje kolone is_obsolete na classified_categories i filtriranje
-- ============================================================================

ALTER TABLE public.classified_categories
ADD COLUMN IF NOT EXISTS is_obsolete BOOLEAN NOT NULL DEFAULT false;

-- Obelezi neaktuelne i duplirane kategorije ako jos uvek postoje
UPDATE public.classified_categories
SET is_obsolete = true
WHERE id IN (
  'stocarstvo_zivotinje',
  'prodaja_kuca',
  'industrijski_placevi',
  'gume_felne',
  'auto_multimedija_navigacija',
  'stampaci_skeneri_toneri',
  'mrezna_oprema_ruteri',
  'memorije_hard_diskovi',
  'mali_kuhinjski_aparati',
  'aparati_za_kafu'
);

-- Osiguraj da rekurzivni view v_classified_categories automatski izostavlja neaktuelne kategorije
CREATE OR REPLACE VIEW public.v_classified_categories AS
WITH RECURSIVE category_tree AS (
    SELECT 
        id,
        name,
        icon_name,
        parent_id,
        sort_order,
        is_condition_applicable,
        is_obsolete,
        created_at
    FROM public.classified_categories
    WHERE parent_id IS NULL AND is_obsolete = false
    
    UNION ALL
    
    SELECT 
        c.id,
        c.name,
        c.icon_name,
        c.parent_id,
        c.sort_order,
        (ct.is_condition_applicable AND c.is_condition_applicable) AS is_condition_applicable,
        c.is_obsolete,
        c.created_at
    FROM public.classified_categories c
    INNER JOIN category_tree ct ON c.parent_id = ct.id
    WHERE c.is_obsolete = false
)
SELECT * FROM category_tree;

GRANT SELECT ON public.v_classified_categories TO anon, authenticated, service_role;

