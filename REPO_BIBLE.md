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

Podržane jedinice u bazi i aplikaciji (prema bazi `CHECK (unit_type IN ('kg','L','kom','veza','pak'))`):

- `kg` — težina (podrazumevano)
- `L` — tečnost (litri)
- `kom` — komadni artikli (npr. pakovanje jaja, tegle, pogače)
- `veza` — svež zeleniš i vezice (mladi luk, peršun, sremuš, rotkvice)
- `pak` — standardna pakovanja (pečurke, sušeno voće, čajevi)

Pravila za jedinice:
- `g` je zastarelo (legacy) i pri parsiranju u `ProductModel.fromJson` automatski se normalizuje u `kg` (npr. `0.1 kg`).
- Pravilo za komadne i vezane artikle (`kom`, `veza`, `pak`): `order_step` je obavezno celobrojan (tipično `1`), a minimalna količina i koraci su celi brojevi bez decimala.

## 4. Order Step Rules

`order_step` je eksplicitna vrednost po proizvodu (u bazi `NOT NULL`).

Pravila:

- nema hardkodovanja koraka po jedinici, kategoriji ili nazivu
- UI koristi `product.order_step` iz baze
- backend validira po `product.order_step` iz baze
- `order_step > 0`
- `order_step <= min_quantity` (baza ima `CHECK (order_step <= min_quantity)`)

### Kategorija Kačkavalj

Za proizvode iz kategorije `Kačkavalj` preporučeni korak porudžbine je:

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

Minimalna količina i korak poručivanja dolaze isključivo od prodavca kroz model proizvoda (`min_order_kg` i `order_step`).

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
  - U modelu aplikacije `ProductModel.isAvailable => availableNow`.
  - Ako je `available_now = false`, backend funkcija `create_order_with_items` strogo odbija kreiranje porudžbine (`product % is currently unavailable`), a UI prikazuje bedž `Rasprodato` i onemogućava dodavanje u korpu.
- Polje `available_kg` u modelu proizvoda ima **informativni karakter** za gazdinstvo i kupca (`hasStockInfo => availableKg > 0`).
  - Backend svesno **ne** vrši blokadu porudžbine poređenjem `quantity <= available_kg` niti automatski dekrementira zalihu, jer bi to blokiralo legitimne narudžbine kod proizvođača koji proizvode po zahtevu ili ne ažuriraju brojno stanje u realnom vremenu.
  - Ako je `available_now = true`, a `available_kg = 0`, proizvod je **„Dostupno po porudžbini”** (kupac može normalno da naruči).
  - Ako je `available_now = true` i `available_kg > 0`, UI prikazuje informativno stanje: **„Na stanju (X)”**.
- **Maksimalna količina na stepperu (`maxQuantity`):**
  - Predstavlja ergonomski UI limit biranja količine (`QuantityEngine.resolveMaxQuantity`), a ne restriktivno sečenje na `available_kg`. Kupac ne sme biti veštački blokiran da naruči 5 kg sira ako je prodavac u polju zalihe naveo 2 kg ili 0 kg.
- Konačnu potvrdu količine, termina i isporuke prodavac vrši prihvatanjem porudžbine (`accepted`) ili dogovorom sa kupcem kroz chat/poziv.

