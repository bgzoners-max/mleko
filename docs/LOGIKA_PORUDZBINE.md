# Logika cele porudžbine

Od izbora proizvoda do arhiviranja i brisanja.

---

## 1. Aktivna porudžbina (u memoriji, pre slanja)

- **Jedan draft po prodavcu** – u memoriji (CartProvider) i/ili SharedPreferences.
- **Ne upisuje se u bazu** dok kupac ne klikne „Pošalji porudžbinu”.

### Modeli (Flutter)

```dart
// Jedna stavka
class ActiveOrderItem {
  final String productId;
  final String name;
  final double unitPrice;
  double quantity;
  double get total => unitPrice * quantity;
}

// Aktivna porudžbina kod jednog prodavca
class ActiveOrder {
  final String sellerId;
  final String sellerName;
  final List<ActiveOrderItem> items;
  double get totalAmount => items.fold(0, (sum, item) => sum + item.total);
}
```

### CartProvider (draft po prodavcu)

- **Struktura:** `Map<sellerId, Map<productId, quantity>>`
- **addForSeller(sellerId, productId, quantity):**
  - Ako proizvod već postoji u draftu tog prodavca → povećaj količinu.
  - Inače → dodaj novu stavku.
- **setQuantityForSeller** / **removeFromSeller** / **clearSeller**
- **getSellerDraft(sellerId)** → mapa productId → quantity
- **getProductsBySeller(sellerId)** → učitava proizvode i vraća listu (product, quantity) za prikaz i checkout

---

## 2. UI tok (kupac)

1. **Stranica prodavca (SellerProfileScreen)**  
   - Lista proizvoda, u AppBar-u „Porudžbina (n)” ako ima stavki u draftu.  
   - Klik na proizvod → BottomSheet (količina +/-) → „Dodaj u porudžbinu” → `CartProvider.addForSeller`.  
   - SnackBar: „Proizvod je dodat u porudžbinu.” + akcija „Pregled” → navigacija na pregled.

2. **Pregled porudžbine (CheckoutMultiScreen)**  
   - Učitava stavke iz CartProvider za tog prodavca.  
   - Naslov: „Porudžbina kod: [Ime domaćinstva]”, sekcija „Tvoje odabrano”.  
   - Moguće menjanje količine i brisanje stavki (ažurira se i CartProvider).  
   - Ukupno za proizvode, napomena o dostavi.  
   - Dugme „Pošalji porudžbinu prodavcu” → slanje u bazu.

---

## 3. Slanje porudžbine (upis u bazu)

**OrdersService.createOrderWithItems**

- Računa `total_amount` iz stavki.
- **orders:** insert jedan red:
  - `buyer_id`, `seller_id`, `total_amount`, `note`, `buyer_city`, `buyer_phone`, `prefer_call`
  - `status = 'sent'`
  - `archived_at = null`
  - `expires_at = now() + 12 meseci` (365 dana u aplikaciji; u bazi DEFAULT takođe postavlja ako nije poslato)
- **order_items:** insert N redova za tu porudžbinu:
  - `order_id`, `product_id`, `product_name`, `quantity_kg`, `unit_type`, `unit_price`, `total_price`
- Nakon uspeha: `CartProvider.clearSeller(sellerId)`, prelaz na listu porudžbina.

Napomena: kolona `prefer_call` i dalje postoji u bazi radi kompatibilnosti, ali **više se ne koristi u aplikaciji** – kupac nigde ne bira „Pozovi me / Pošalji poruku”. Prodavac uvek dobija sve kontakt podatke (telefon, grad, adresa, napomena) i **sam odlučuje da li će kupca pozvati ili poslati poruku**.

---

## 4. Baza (Supabase)

### Tabela `orders`

| Kolona        | Tip         | Napomena                                      |
|---------------|-------------|-----------------------------------------------|
| id            | uuid        | PK                                            |
| buyer_id      | uuid        |                                               |
| seller_id     | uuid        | Jedna porudžbina = jedan prodavac             |
| total_amount  | numeric     |                                               |
| status        | text        | vrednosti u bazi: sent, accepted, rejected, delivered, cancelled_by_seller, arhivirano |
| created_at    | timestamptz |                                               |
| archived_at   | timestamptz | nullable; setuje se pri arhiviranju           |
| expires_at    | timestamptz | NOT NULL, DEFAULT now() + 12 meseci           |
| note, buyer_city, buyer_phone, prefer_call, ... | Kolona `prefer_call` više se ne koristi u aplikaciji (ostavljena je u bazi samo zbog kompatibilnosti). | |

### Tabela `order_items`

| Kolona       | Tip     |
|--------------|---------|
| id           | uuid    |
| order_id     | uuid    | FK → orders(id) **ON DELETE CASCADE** |
| product_id   | uuid    |
| product_name | text    |
| quantity_kg   | numeric |
| unit_type    | text    |
| unit_price   | numeric |
| total_price  | numeric |

---

## 5. Statusi porudžbine (u bazi i u aplikaciji)

| U bazi            | U aplikaciji (OrderStatus) | Prikaz          |
|-------------------|----------------------------|-----------------|
| sent              | OrderStatus.sent           | Poslato         |
| accepted          | OrderStatus.accepted       | Prihvaćeno      |
| rejected          | OrderStatus.rejected       | Odbijeno        |
| delivered         | OrderStatus.delivered      | Isporučeno      |
| cancelled_by_seller | OrderStatus.cancelledBySeller | Otkazano    |
| arhivirano        | OrderStatus.archived       | Arhivirano      |

- **Aktivne** u aplikaciji = `status = 'sent'` (plus accepted, rejected, delivered ako ih prikazuješ u „aktivnim”; u tvom slučaju „Aktivne” = samo sent).
- **Arhiva** = `status = 'arhivirano'`. Arhivirane su read-only (nema promene statusa / ponovnog slanja).

---

## 6. Automatska arhivacija i brisanje (retention)

**Funkcija:** `public.handle_order_retention()`

1. **Arhiviranje (30 dana)**  
   - Uslov: `status = 'sent'` i `created_at <= now() - interval '30 days'`.  
   - Akcija: `status = 'arhivirano'`, `archived_at = now()`.

2. **Brisanje (12 meseci)**  
   - Uslov: `expires_at <= now()`.  
   - Akcija: `DELETE FROM orders` (redovi sa isteklim `expires_at`).  
   - `order_items` se brišu automatski zbog **ON DELETE CASCADE**.

**Zakazano pokretanje (pg_cron):** svaki dan u 03:00 UTC:

```sql
SELECT cron.schedule(
  'daily_order_retention',
  '0 3 * * *',
  'SELECT public.handle_order_retention()'
);
```

- Korisnik ne bira period; sve je automatski.
- Jedna porudžbina = jedan prodavac; arhivacija ne menja poslovnu logiku.

---

## 7. Prikaz u aplikaciji (kupac i prodavac)

- **Aktivne porudžbine:** upit sa `status = 'sent'` (i eventualno ostali „aktivni” statusi, zavisi od UI).
- **Arhiva:** upit sa `status = 'arhivirano'`.
- Listanje: po `buyer_id` ili `seller_id`, sort po `created_at DESC`, sa paginacijom (npr. 20 po stranici).
- Napomena u sekciji Arhiva:  
  „Porudžbine starije od 30 dana automatski se premeštaju u arhivu. Porudžbine se brišu nakon 12 meseci.”

---

## 8. Indeksi (za 100k+ porudžbina)

- **Arhiviranje:** `(status, created_at)` WHERE `status = 'sent'`.
- **Brisanje:** `(expires_at)`.
- **Listanje po kupcu:** `(buyer_id, status, created_at DESC)`.
- **Listanje po prodavcu:** `(seller_id, status, created_at DESC)`.

---

## 9. Baza i operativno

### Praćenje cron-a (pg_cron)

Da vidiš da li se `daily_order_retention` zaista izvršava i da nema grešaka:

1. **Da li je job zakazan**  
   U SQL Editoru (Supabase):
   ```sql
   SELECT jobid, jobname, schedule, command
   FROM cron.job
   WHERE jobname = 'daily_order_retention';
   ```
   Ako vrati jedan red, job je zakazan.

2. **Istorija izvršavanja i greške**  
   Tabela `cron.job_run_details` (pg_cron) beleži svako pokretanje:
   ```sql
   SELECT jobid, runid, job_pid, status, return_message, start_time, end_time
   FROM cron.job_run_details
   WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'daily_order_retention')
   ORDER BY start_time DESC
   LIMIT 20;
   ```
   - `status = 'succeeded'` → OK.  
   - `status = 'failed'` → pogledaj `return_message` za grešku.  
   - `start_time` / `end_time` pokazuju kada se job zaista pokrenuo i trajao.

U **Supabase Dashboard** može postojati sekcija za Cron / Scheduled jobs (zavisi od verzije) gde se vidi istorija; ako je dostupna, koristi je uz gornje upite.

### Backup pre retention-a

Za **produkciju** pre nego što retention radi na punom opsegu (npr. hiljade porudžbina):

- **Dnevni backup** u istom (ili bliskom) terminu kao retention (npr. backup u 02:30, retention u 03:00), da uvek možeš da vratiš stanje ako nešto pođe po zlu.
- U **Supabase**: Dashboard → Project Settings → Database → Backup (point-in-time recovery ako je uključen, ili dnevni backup ako ga nudi plan).
- Pre **prvog** punog retention ciklusa: ručno napravi snapshot / backup (npr. pg_dump ili Supabase backup), pa tek onda ostavi da cron redovno radi.

### Checklist pre puštanja retention-a u produkciju

- [ ] **pg_cron** uključen (Dashboard → Database → Extensions).
- [ ] **handle_order_retention()** postoji i u bazi je `status = 'sent'` (ne `'poslato'`).
- [ ] **order_items** ima `ON DELETE CASCADE` na `order_id` (nema siročić-stavki).
- [ ] **expires_at** NOT NULL i DEFAULT postavljen na `orders`.
- [ ] **Indeksi** za retention i listanje primenjeni (arhiviranje, brisanje, buyer_id, seller_id).
- [ ] **Backup** podešen (dnevni ili PITR) i jedan ručni backup urađen pre prvog retention ciklusa.
- [ ] **Cron job** `daily_order_retention` zakazan (provera u `cron.job`).
- [ ] Jednom **ručno** pokrenut `SELECT public.handle_order_retention();` na test/kopiji baze i provereno da arhivira/briše kako treba.

---

## Kratak tok u jednom pasusu

Kupac bira proizvode kod prodavca → draft živi u **CartProvider** (po prodavcu) → na „Pregled” vidi „Tvoje odabrano”, može da menja količinu i briše stavke → „Pošalji porudžbinu” → u bazi se kreira **orders** (status `sent`, `expires_at` = now + 12 meseci) i **order_items**, draft se prazni → svakodnevno u 03:00 **handle_order_retention()** arhivira stare „sent” (30 dana) u `arhivirano` i briše redove sa `expires_at <= now()` (CASCADE briše i stavke). Aktivne/arhiva u aplikaciji filtriraju po `status = 'sent'` odnosno `'arhivirano'`.
