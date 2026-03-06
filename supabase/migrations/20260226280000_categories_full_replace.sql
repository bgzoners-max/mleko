-- Finalna hijerarhija kategorija sa slug-ovima (bez dijakritike za URL) i ispravnim nazivima (č, ć, š, đ, ž)
-- Zamenjuje postojeće kategorije

-- Dodaj slug kolonu ako ne postoji
ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS slug TEXT;

-- Obriši stare kategorije (products.category je TEXT, nema FK)
DELETE FROM public.categories;

-- Unique na slug (za URL i pretragu)
CREATE UNIQUE INDEX IF NOT EXISTS categories_slug_idx ON public.categories(slug) WHERE slug IS NOT NULL;

-- 1) Ubaci roditelje
WITH parents AS (
  INSERT INTO public.categories (id, name, slug, icon, "order", parent_id)
  VALUES
    (gen_random_uuid(), 'Mlečni proizvodi',        'mlecni-proizvodi',        '🥛',  10, NULL),
    (gen_random_uuid(), 'Suhomesnato',             'suhomesnato',             '🥩',  20, NULL),
    (gen_random_uuid(), 'Slatko i džemovi',        'slatko-i-dzemovi',        '🍯',  30, NULL),
    (gen_random_uuid(), 'Sokovi i pića',           'sokovi-i-pica',           '🧃',  40, NULL),
    (gen_random_uuid(), 'Zimnica i namazi',        'zimnica-i-namazi',        '🫙',  50, NULL),
    (gen_random_uuid(), 'Voće i povrće',           'voce-i-povrce',           '🥕',  60, NULL),
    (gen_random_uuid(), 'Pekarsko i testa',        'pekarsko-i-testa',        '🥖',  70, NULL),
    (gen_random_uuid(), 'Brašno i žitarice',       'brasno-i-zitarice',       '🌾',  80, NULL),
    (gen_random_uuid(), 'Jaja',                    'jaja',                    '🥚',  90, NULL),
    (gen_random_uuid(), 'Med i pčelarski',          'med-i-pcelarski',         '🐝', 100, NULL),
    (gen_random_uuid(), 'Začini i bilje',          'zacini-i-bilje',          '🌿', 110, NULL),
    (gen_random_uuid(), 'Prirodna kozmetika',      'prirodna-kozmetika',      '🧴', 120, NULL),
    (gen_random_uuid(), 'Gotova jela i delikatesi', 'gotova-jela-i-delikates', '🍲', 130, NULL),
    (gen_random_uuid(), 'Poklon paketi',           'poklon-paketi',           '🎁', 140, NULL)
  RETURNING id, slug
)
-- 2) Ubaci decu
INSERT INTO public.categories (id, name, slug, icon, "order", parent_id)
SELECT gen_random_uuid(), c.name, c.slug, c.icon, c.ord, p.id
FROM parents p
JOIN (VALUES
  ('mlecni-proizvodi','Mleko',                 'mleko',                 '🥛',  10),
  ('mlecni-proizvodi','Jogurt i kiselo mleko', 'jogurt-i-kiselo-mleko', '🥣',  20),
  ('mlecni-proizvodi','Sir',                   'sir',                   '🧀',  30),
  ('mlecni-proizvodi','Kajmak',                'kajmak',                '🧈',  40),
  ('mlecni-proizvodi','Pavlaka i namazi',      'pavlaka-i-namazi',      '🥄',  50),
  ('suhomesnato','Šunke i pršute',             'sunke-i-prsute',        '🍖',  10),
  ('suhomesnato','Kobasice',                   'kobasice',              '🌭',  20),
  ('suhomesnato','Slanina i panceta',          'slanina-i-panceta',     '🥓',  30),
  ('suhomesnato','Čvarci',                     'cvarci',                '🥩',  40),
  ('suhomesnato','Pečenice i vrat',            'pecenice-i-vrat',       '🍖',  50),
  ('slatko-i-dzemovi','Džemovi',               'dzemovi',               '🍓',  10),
  ('slatko-i-dzemovi','Slatko (tradicionalno)','slatko-tradicionalno', '🍒',  20),
  ('slatko-i-dzemovi','Marmelade',             'marmelade',             '🍊',  30),
  ('slatko-i-dzemovi','Med i namazi',          'med-i-namazi',          '🍯',  40),
  ('slatko-i-dzemovi','Slatkiši domaći',       'slatkisi-domaci',       '🍪',  50),
  ('sokovi-i-pica','Prirodni sokovi',          'prirodni-sokovi',       '🧃',  10),
  ('sokovi-i-pica','Sirupi',                   'sirupi',                '🍶',  20),
  ('sokovi-i-pica','Kompot i nektari',         'kompot-i-nektari',      '🍑',  30),
  ('sokovi-i-pica','Čajevi',                   'cajevi',                '🍵',  40),
  ('sokovi-i-pica','Domaći napitci',            'domaci-napici',         '🥤',  50),
  ('zimnica-i-namazi','Ajvar i ljutenica',     'ajvar-i-ljutenica',     '🌶️',  10),
  ('zimnica-i-namazi','Pinđur i namazi',       'pinjur-i-namazi',       '🫙',  20),
  ('zimnica-i-namazi','Kiselo povrće',         'kiselo-povrce',         '🥒',  30),
  ('zimnica-i-namazi','Turšija',               'tursija',               '🥗',  40),
  ('zimnica-i-namazi','Paradajz program',      'paradajz-program',      '🍅',  50),
  ('voce-i-povrce','Sveže voće',               'sveze-voce',            '🍎',  10),
  ('voce-i-povrce','Sveže povrće',             'sveze-povrce',          '🥦',  20),
  ('voce-i-povrce','Organsko',                 'organsko',              '🌱',  30),
  ('voce-i-povrce','Sezonsko',                 'sezonsko',              '🗓️',  40),
  ('pekarsko-i-testa','Hleb i pečiva',         'hleb-i-peciva',         '🥖',  10),
  ('pekarsko-i-testa','Pite i gibanice',       'pite-i-gibanice',       '🥧',  20),
  ('pekarsko-i-testa','Kolači domaći',         'kolaci-domaci',         '🍰',  30),
  ('pekarsko-i-testa','Testenina domaća',      'testenina-domaca',      '🍝',  40),
  ('brasno-i-zitarice','Brašno',               'brasno',                '🌾',  10),
  ('brasno-i-zitarice','Žitarice',             'zitarice',              '🌾',  20),
  ('brasno-i-zitarice','Mleveno i pahuljice',  'mleveno-i-pahuljice',   '🥣',  30),
  ('brasno-i-zitarice','Seme i orašasti',      'seme-i-orasasti',       '🥜',  40),
  ('jaja','Kokošija jaja',                     'kokosija-jaja',         '🥚',  10),
  ('jaja','Prepeličja jaja',                   'prepelicja-jaja',       '🥚',  20),
  ('med-i-pcelarski','Med',                    'med',                   '🍯',  10),
  ('med-i-pcelarski','Propolis i tinkture',    'propolis-i-tinkture',   '💧',  20),
  ('med-i-pcelarski','Vosak i sveće',          'vosak-i-svece',         '🕯️',  30),
  ('med-i-pcelarski','Polen i perga',          'polen-i-perga',         '🌼',  40),
  ('zacini-i-bilje','Začini',                  'zacini',                '🧂',  10),
  ('zacini-i-bilje','Lekovito bilje',          'lekovito-bilje',        '🌿',  20),
  ('zacini-i-bilje','Čajevi rasuti',           'cajevi-rasuti',         '🍵',  30),
  ('zacini-i-bilje','Ulje i sirće',            'ulje-i-sirce',           '🫒',  40),
  ('prirodna-kozmetika','Sapuni',              'sapuni',                '🧼',  10),
  ('prirodna-kozmetika','Melemi i kreme',      'melemi-i-kreme',        '🧴',  20),
  ('prirodna-kozmetika','Šamponi i losioni',   'samponi-i-losioni',     '🧴',  30),
  ('gotova-jela-i-delikates','Gotova jela',    'gotova-jela',           '🍲',  10),
  ('gotova-jela-i-delikates','Delikatesi',     'delikates',             '🧀',  20),
  ('poklon-paketi','Poklon setovi',            'poklon-setovi',         '🎁',  10),
  ('poklon-paketi','Korpe i kombinacije',      'korpe-i-kombinacije',   '🧺',  20)
) AS c(parent_slug, name, slug, icon, ord)
ON p.slug = c.parent_slug;
