-- Ažuriraj category text field na proizvodima nakon preimenovanja kategorija

-- Proizvodi koji su bili u "Jogurt i kiselo mleko" -> premjesti u "Jogurt"
-- (korisnik može ručno premjestiti kiselo-mleko proizvode u "Kiselo mleko")
UPDATE public.products
SET category = 'Jogurt'
WHERE category = 'Jogurt i kiselo mleko';

-- Proizvodi koji su bili u "Pavlaka i namazi" -> premjesti u "Namazi"
UPDATE public.products
SET category = 'Namazi'
WHERE category = 'Pavlaka i namazi';
