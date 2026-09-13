# NAŠE SELO - PRODUCT BIBLE (SIMPLIFIED RULES)

Ovaj dokument je kanon za pravila proizvoda, količina i poručivanja.
Ako postoji razlika između implementacije i ovog dokumenta, prati se ovaj dokument.

## 1. Core Philosophy

Marketplace mora biti jednostavan za prodavce.

Zato:

- Prodavac određuje:
	- minimalnu količinu porudžbine
	- korak porudžbine (`order_step`)

Time UI ostaje predvidiv i kupac uvek dobija prirodne količine.

## 2. Core Product Model

Svaki proizvod ima:

- `name`
- `category`
- `unit`
- `price`
- `min_quantity`
- `order_step`

`order_step` je obavezan podatak u bazi i ne sme biti hardkodovan po jedinici/kategoriji.

## 3. Units

Podržane jedinice:

- `kg`
- `L`
- `kom`

## 4. Order Step Rules

`order_step` je eksplicitna vrednost po proizvodu.

Pravila:

- nema hardkodovanja koraka po jedinici, kategoriji ili nazivu
- UI koristi `product.order_step` iz baze
- backend validira po `product.order_step` iz baze
- `order_step > 0`
- `order_step <= min_quantity`

### Kategorija Kačkavalj

Za proizvode iz kategorije `Kačkavalj` korak porudžbine je:

- `order_step = 0.1 kg` (100 g)

UI i backend i dalje moraju koristiti vrednost iz baze (`product.order_step`).

## 5. Packaging Rules

Pakovanje je informativno za kupca.

### Tegle

Koriste se za:

- `ajvar`
- `džem`
- `pekmez`
- `med`
- `turšiju`

Standardne veličine:

- `200 ml`
- `370 ml`
- `720 ml`
- `1000 ml`

### Flaše

Koriste se za:

- `sok`
- `sirup`
- `mleko`
- `rakiju`

Standardne veličine:

- `0.5 L`
- `1 L`
- `2 L`

## 6. Honey Rule

Med se prodaje u:

- `kg`

Ne u litrima.

Primer:

- `med bagrem`
- `unit: kg`
- `min_quantity: 0.5`

Koraci:

- zavise od konkretnog `order_step` postavljenog na proizvodu

## 7. UI Quantity Generation

UI generiše količine:

```text
quantity = min_quantity

while quantity <= max_limit:
		quantity += order_step
```

## 8. Backend Validation

Backend mora proveriti:

- `quantity >= min_quantity`
- `quantity % order_step == valid`
- `order_step > 0`
- `order_step <= min_quantity`

## 9. UX Goal

Kupac nikada ne sme videti nelogične količine poput:

- `0.83 kg`
- `1.37 kg`

Prihvatljive vrednosti su:

- `0.1`
- `0.25`
- `0.5`
- `1`
- `2`

## 10. Design Goal

Sistem mora biti:

- jednostavan za prodavce
- predvidiv za kupce
- lak za implementaciju

Minimalna količina dolazi od prodavca, a koraci dolaze iz sistemskih pravila.
Minimalna količina i korak dolaze od prodavca kroz model proizvoda.

## Arhitektonski savet

Centralizuj validaciju količine (`isValidQuantity`, `normalizeQuantity`), ali ne i izračunavanje koraka iz heuristika.
Korak je podatak (`order_step`) koji se čita sa proizvoda.

## Sledeći korak

Preporuka: jedinstveni quantity engine (30-40 linija) koji pokriva:

- validaciju i normalizaciju količine

Taj engine treba koristiti svuda (checkout, cart, seller preview, backend validacija), uz `order_step` iz baze.

## 11. Inventory & Availability Philosophy (Upit vs. Magacin)

Marketplace „Naše Selo” povezuje kupce sa malim lokalnim proizvođačima hrane.

Zato važi kanonsko pravilo:

- **Porudžbina je direktan upit/zahtev (`status = 'sent'`), a ne automatska magacinska rezervacija.**
- Poljoprivrednici robu često pripremaju po prijemu porudžbine (muža mleka, branje plodova, sveže pripremanje, pravljenje sira).
- Glavni i autoritativni prekidač dostupnosti je `products.available_now` (boolean):
  - Ako je `available_now = false`, backend funkcija `create_order_with_items` strogo odbija kreiranje porudžbine (`product % is currently unavailable`).
- Polje `available_kg` u modelu proizvoda ima **informativni karakter** za gazdinstvo i kupca. Backend svesno **ne** vrši blokadu porudžbine poređenjem `quantity <= available_kg` niti automatski dekrementira zalihu, jer bi to blokiralo legitimne narudžbine kod proizvođača koji proizvode po zahtevu ili ne ažuriraju brojno stanje u realnom vremenu.
- Konačnu potvrdu količine, termina i isporuke prodavac vrši prihvatanjem porudžbine (`accepted`) ili dogovorom sa kupcem kroz chat/poziv.

