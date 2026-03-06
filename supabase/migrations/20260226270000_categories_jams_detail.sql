-- Obogaćena hijerarhija: Slatko i džemovi + Sokovi i pića (Džemovi, slatka i sokovi)

-- ========== SLATKO I DŽEMOVI ==========
INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Slatko i džemovi', 'eco', 10, c.id
FROM public.categories c
WHERE c.name = 'Džemovi, slatka i sokovi' AND c.parent_id IS NULL
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Slatko i džemovi' AND parent_id = c.id);

-- Džemovi
INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Džemovi', 'eco', 1, sc.id
FROM public.categories sc
WHERE sc.name = 'Slatko i džemovi' AND sc.parent_id IN (SELECT id FROM public.categories WHERE name = 'Džemovi, slatka i sokovi' AND parent_id IS NULL)
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Džemovi' AND parent_id = sc.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Džem od šljive', 'eco', 1, sub.id
FROM public.categories sub WHERE sub.name = 'Džemovi' AND sub.parent_id IN (SELECT id FROM public.categories WHERE name = 'Slatko i džemovi')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Džem od šljive' AND parent_id = sub.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Džem od kajsije', 'eco', 2, sub.id
FROM public.categories sub WHERE sub.name = 'Džemovi' AND sub.parent_id IN (SELECT id FROM public.categories WHERE name = 'Slatko i džemovi')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Džem od kajsije' AND parent_id = sub.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Džem od jagode', 'eco', 3, sub.id
FROM public.categories sub WHERE sub.name = 'Džemovi' AND sub.parent_id IN (SELECT id FROM public.categories WHERE name = 'Slatko i džemovi')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Džem od jagode' AND parent_id = sub.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Džem bez šećera', 'eco', 4, sub.id
FROM public.categories sub WHERE sub.name = 'Džemovi' AND sub.parent_id IN (SELECT id FROM public.categories WHERE name = 'Slatko i džemovi')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Džem bez šećera' AND parent_id = sub.id);

-- Slatko (tradicionalno)
INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Slatko (tradicionalno)', 'eco', 2, sc.id
FROM public.categories sc WHERE sc.name = 'Slatko i džemovi' AND sc.parent_id IN (SELECT id FROM public.categories WHERE name = 'Džemovi, slatka i sokovi' AND parent_id IS NULL)
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Slatko (tradicionalno)' AND parent_id = sc.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Slatko od višnje', 'eco', 1, sub.id
FROM public.categories sub WHERE sub.name = 'Slatko (tradicionalno)' AND sub.parent_id IN (SELECT id FROM public.categories WHERE name = 'Slatko i džemovi')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Slatko od višnje' AND parent_id = sub.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Slatko od smokve', 'eco', 2, sub.id
FROM public.categories sub WHERE sub.name = 'Slatko (tradicionalno)' AND sub.parent_id IN (SELECT id FROM public.categories WHERE name = 'Slatko i džemovi')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Slatko od smokve' AND parent_id = sub.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Slatko od šumskih jagoda', 'eco', 3, sub.id
FROM public.categories sub WHERE sub.name = 'Slatko (tradicionalno)' AND sub.parent_id IN (SELECT id FROM public.categories WHERE name = 'Slatko i džemovi')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Slatko od šumskih jagoda' AND parent_id = sub.id);

-- Marmelade
INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Marmelade', 'eco', 3, sc.id
FROM public.categories sc WHERE sc.name = 'Slatko i džemovi' AND sc.parent_id IN (SELECT id FROM public.categories WHERE name = 'Džemovi, slatka i sokovi' AND parent_id IS NULL)
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Marmelade' AND parent_id = sc.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Marmelada od šipka', 'eco', 1, sub.id
FROM public.categories sub WHERE sub.name = 'Marmelade' AND sub.parent_id IN (SELECT id FROM public.categories WHERE name = 'Slatko i džemovi')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Marmelada od šipka' AND parent_id = sub.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Citrus marmelada', 'eco', 2, sub.id
FROM public.categories sub WHERE sub.name = 'Marmelade' AND sub.parent_id IN (SELECT id FROM public.categories WHERE name = 'Slatko i džemovi')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Citrus marmelada' AND parent_id = sub.id);

-- Med i proizvodi od meda
INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Med i proizvodi od meda', 'eco', 4, sc.id
FROM public.categories sc WHERE sc.name = 'Slatko i džemovi' AND sc.parent_id IN (SELECT id FROM public.categories WHERE name = 'Džemovi, slatka i sokovi' AND parent_id IS NULL)
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Med i proizvodi od meda' AND parent_id = sc.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Bagremov med', 'eco', 1, sub.id
FROM public.categories sub WHERE sub.name = 'Med i proizvodi od meda' AND sub.parent_id IN (SELECT id FROM public.categories WHERE name = 'Slatko i džemovi')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Bagremov med' AND parent_id = sub.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Livadski med', 'eco', 2, sub.id
FROM public.categories sub WHERE sub.name = 'Med i proizvodi od meda' AND sub.parent_id IN (SELECT id FROM public.categories WHERE name = 'Slatko i džemovi')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Livadski med' AND parent_id = sub.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Med sa orasima', 'eco', 3, sub.id
FROM public.categories sub WHERE sub.name = 'Med i proizvodi od meda' AND sub.parent_id IN (SELECT id FROM public.categories WHERE name = 'Slatko i džemovi')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Med sa orasima' AND parent_id = sub.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Propolis', 'eco', 4, sub.id
FROM public.categories sub WHERE sub.name = 'Med i proizvodi od meda' AND sub.parent_id IN (SELECT id FROM public.categories WHERE name = 'Slatko i džemovi')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Propolis' AND parent_id = sub.id);

-- Namazi
INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Namazi', 'eco', 5, sc.id
FROM public.categories sc WHERE sc.name = 'Slatko i džemovi' AND sc.parent_id IN (SELECT id FROM public.categories WHERE name = 'Džemovi, slatka i sokovi' AND parent_id IS NULL)
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Namazi' AND parent_id = sc.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Ajvar', 'eco', 1, sub.id
FROM public.categories sub WHERE sub.name = 'Namazi' AND sub.parent_id IN (SELECT id FROM public.categories WHERE name = 'Slatko i džemovi')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Ajvar' AND parent_id = sub.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Ljutenica', 'eco', 2, sub.id
FROM public.categories sub WHERE sub.name = 'Namazi' AND sub.parent_id IN (SELECT id FROM public.categories WHERE name = 'Slatko i džemovi')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Ljutenica' AND parent_id = sub.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Pinđur', 'eco', 3, sub.id
FROM public.categories sub WHERE sub.name = 'Namazi' AND sub.parent_id IN (SELECT id FROM public.categories WHERE name = 'Slatko i džemovi')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Pinđur' AND parent_id = sub.id);

-- ========== SOKOVI I PIĆA ==========
INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Sokovi i pića', 'eco', 11, c.id
FROM public.categories c
WHERE c.name = 'Džemovi, slatka i sokovi' AND c.parent_id IS NULL
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Sokovi i pića' AND parent_id = c.id);

-- Prirodni sokovi
INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Prirodni sokovi', 'eco', 1, sc.id
FROM public.categories sc WHERE sc.name = 'Sokovi i pića' AND sc.parent_id IN (SELECT id FROM public.categories WHERE name = 'Džemovi, slatka i sokovi' AND parent_id IS NULL)
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Prirodni sokovi' AND parent_id = sc.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Sok od jabuke', 'eco', 1, sub.id
FROM public.categories sub WHERE sub.name = 'Prirodni sokovi' AND sub.parent_id IN (SELECT id FROM public.categories WHERE name = 'Sokovi i pića')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Sok od jabuke' AND parent_id = sub.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Sok od maline', 'eco', 2, sub.id
FROM public.categories sub WHERE sub.name = 'Prirodni sokovi' AND sub.parent_id IN (SELECT id FROM public.categories WHERE name = 'Sokovi i pića')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Sok od maline' AND parent_id = sub.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Sok od aronije', 'eco', 3, sub.id
FROM public.categories sub WHERE sub.name = 'Prirodni sokovi' AND sub.parent_id IN (SELECT id FROM public.categories WHERE name = 'Sokovi i pića')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Sok od aronije' AND parent_id = sub.id);

-- Sirupi (pod Sokovi i pića)
INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Sirupi', 'eco', 2, sc.id
FROM public.categories sc WHERE sc.name = 'Sokovi i pića' AND sc.parent_id IN (SELECT id FROM public.categories WHERE name = 'Džemovi, slatka i sokovi' AND parent_id IS NULL)
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Sirupi' AND parent_id = sc.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Sirup od zove', 'eco', 1, sub.id
FROM public.categories sub WHERE sub.name = 'Sirupi' AND sub.parent_id IN (SELECT id FROM public.categories WHERE name = 'Sokovi i pića')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Sirup od zove' AND parent_id = sub.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Sirup od maline', 'eco', 2, sub.id
FROM public.categories sub WHERE sub.name = 'Sirupi' AND sub.parent_id IN (SELECT id FROM public.categories WHERE name = 'Sokovi i pića')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Sirup od maline' AND parent_id = sub.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Sirup od nane', 'eco', 3, sub.id
FROM public.categories sub WHERE sub.name = 'Sirupi' AND sub.parent_id IN (SELECT id FROM public.categories WHERE name = 'Sokovi i pića')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Sirup od nane' AND parent_id = sub.id);

-- Hladno ceđeni sokovi (list)
INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Hladno ceđeni sokovi', 'eco', 3, sc.id
FROM public.categories sc WHERE sc.name = 'Sokovi i pića' AND sc.parent_id IN (SELECT id FROM public.categories WHERE name = 'Džemovi, slatka i sokovi' AND parent_id IS NULL)
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Hladno ceđeni sokovi' AND parent_id = sc.id);

-- Domaći napici
INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Domaći napici', 'eco', 4, sc.id
FROM public.categories sc WHERE sc.name = 'Sokovi i pića' AND sc.parent_id IN (SELECT id FROM public.categories WHERE name = 'Džemovi, slatka i sokovi' AND parent_id IS NULL)
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Domaći napici' AND parent_id = sc.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Kompot', 'eco', 1, sub.id
FROM public.categories sub WHERE sub.name = 'Domaći napici' AND sub.parent_id IN (SELECT id FROM public.categories WHERE name = 'Sokovi i pića')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Kompot' AND parent_id = sub.id);

INSERT INTO public.categories (id, name, icon, "order", parent_id)
SELECT gen_random_uuid(), 'Voćni nektar', 'eco', 2, sub.id
FROM public.categories sub WHERE sub.name = 'Domaći napici' AND sub.parent_id IN (SELECT id FROM public.categories WHERE name = 'Sokovi i pića')
  AND NOT EXISTS (SELECT 1 FROM public.categories WHERE name = 'Voćni nektar' AND parent_id = sub.id);
