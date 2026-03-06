-- Ispravi nazive kategorija – dodaj dijakritiku (č, ć, š, đ, ž) za prikaz u aplikaciji
-- Slug ostaje bez dijakritike zbog URL-a

UPDATE public.categories SET name = 'Mlečni proizvodi' WHERE slug = 'mlecni-proizvodi';
UPDATE public.categories SET name = 'Slatko i džemovi' WHERE slug = 'slatko-i-dzemovi';
UPDATE public.categories SET name = 'Sokovi i pića' WHERE slug = 'sokovi-i-pica';
UPDATE public.categories SET name = 'Voće i povrće' WHERE slug = 'voce-i-povrce';
UPDATE public.categories SET name = 'Brašno i žitarice' WHERE slug = 'brasno-i-zitarice';
UPDATE public.categories SET name = 'Med i pčelarski' WHERE slug = 'med-i-pcelarski';
UPDATE public.categories SET name = 'Začini i bilje' WHERE slug = 'zacini-i-bilje';

UPDATE public.categories SET name = 'Šunke i pršute' WHERE slug = 'sunke-i-prsute';
UPDATE public.categories SET name = 'Pečenice i vrat' WHERE slug = 'pecenice-i-vrat';
UPDATE public.categories SET name = 'Džemovi' WHERE slug = 'dzemovi';
UPDATE public.categories SET name = 'Slatkiši domaći' WHERE slug = 'slatkisi-domaci';
UPDATE public.categories SET name = 'Čajevi' WHERE slug = 'cajevi';
UPDATE public.categories SET name = 'Domaći napitci' WHERE slug = 'domaci-napici';
UPDATE public.categories SET name = 'Kiselo povrće' WHERE slug = 'kiselo-povrce';
UPDATE public.categories SET name = 'Sveže voće' WHERE slug = 'sveze-voce';
UPDATE public.categories SET name = 'Sveže povrće' WHERE slug = 'sveze-povrce';
UPDATE public.categories SET name = 'Hleb i pečiva' WHERE slug = 'hleb-i-peciva';
UPDATE public.categories SET name = 'Kolači domaći' WHERE slug = 'kolaci-domaci';
UPDATE public.categories SET name = 'Testenina domaća' WHERE slug = 'testenina-domaca';
UPDATE public.categories SET name = 'Brašno' WHERE slug = 'brasno';
UPDATE public.categories SET name = 'Žitarice' WHERE slug = 'zitarice';
UPDATE public.categories SET name = 'Seme i orašasti' WHERE slug = 'seme-i-orasasti';
UPDATE public.categories SET name = 'Kokošija jaja' WHERE slug = 'kokosija-jaja';
UPDATE public.categories SET name = 'Prepeličja jaja' WHERE slug = 'prepelicja-jaja';
UPDATE public.categories SET name = 'Vosak i sveće' WHERE slug = 'vosak-i-svece';
UPDATE public.categories SET name = 'Začini' WHERE slug = 'zacini';
UPDATE public.categories SET name = 'Čajevi rasuti' WHERE slug = 'cajevi-rasuti';
UPDATE public.categories SET name = 'Ulje i sirće' WHERE slug = 'ulje-i-sirce';
UPDATE public.categories SET name = 'Šamponi i losioni' WHERE slug = 'samponi-i-losioni';
UPDATE public.categories SET name = 'Čvarci' WHERE slug = 'cvarci';
UPDATE public.categories SET name = 'Pinđur i namazi' WHERE slug = 'pinjur-i-namazi';
UPDATE public.categories SET name = 'Turšija' WHERE slug = 'tursija';
UPDATE public.categories SET name = 'Gotova jela i delikatesi' WHERE slug = 'gotova-jela-i-delikates';
UPDATE public.categories SET name = 'Delikatesi' WHERE slug = 'delikates';
