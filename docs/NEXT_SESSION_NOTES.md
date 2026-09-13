# Podsetnik za sledeću sesiju – Mleko Mali Oglasi (Classifieds)

> **Datum:** 11. septembar 2026.  
> **Status:** Stabilno, 195/195 testova prolazi (100%), `dart analyze` 0 grešaka/upozorenja, `scan_security_definer_migrations` čisto, CI coverage gate na 26.0% (trenutno 26.95%).

---

## 🎯 Pregled uspešno završenih faza

1. **Faza 1 – Hijerarhijsko pretraživanje i filtriranje automobila i brendova**
   - Dodate potkategorije (nemački, francuski, azijski, domaći brendovi), brend logo ikonice i dinamičko filtriranje.
2. **Faza 2 – Specifični atributi i filteri po kategorijama (Dynamic Attributes)**
   - Definisani atributi (godište, gorivo, kilometraža, kubikaža, menjač, snaga, stanje mehanizacije).
   - Filter bottom sheet i pametni `attribute_chips`.
3. **Faza 3 – Pretplata i obaveštenja o novim oglasima (Category Subscriptions)**
   - Tabela `classified_category_subscriptions`, praćenje po kategoriji ili reči pretrage, push notifikacije.
4. **Faza 4 – Isticanje oglasa i hitna prodaja (Featured & Urgent Ads)**
   - Zlatne i crvene značke, vizuelni prioritet u listi, `is_featured`, `is_urgent`, `featured_until`.
5. **Faza 5 – Prijavljivanje oglasa i bezbednost kupaca (Ad Reporting & Safety)**
   - Tabela `classified_ad_reports`, dijalog za prijavu sa 6 razloga, zaštita od dupliranja, kolona `reports_count`.
6. **Faza 6 – Statistika i analitika oglasa za prodavce (Seller Ad Analytics & Performance Dashboard)**
   - Praćenje pregleda 👁️, poziva 📞 i deljenja ↗️ (`increment_classified_ad_interaction`).
   - `SellerAnalyticsSummaryCard` na vrhu „Moji oglasi” sa KPI karticama i najuspešnijim oglasom.
   - Bedževi angažmana na svakoj pojedinačnoj kartici oglasa.
7. **Faza 7 – Admin panel za moderaciju prijavljenih oglasa (`ClassifiedsModerationScreen`)**
   - Migracija `20260911070000_classified_ad_moderation.sql`: RLS politike za admine na `classified_ad_reports` i sigurna RPC procedura `moderate_classified_ad` (`SECURITY DEFINER`, `public.is_admin()`).
   - Obogaćen `ClassifiedAdReportModel` i servis `ClassifiedReportsService`.
   - Ekran `ClassifiedsModerationScreen` sa KPI karticama, tabovima i akcijama moderatora.
8. **P2 – Testiranje i CI/CD (Coverage Gate & Test Pokrivenost)**
   - **CI Coverage Gate**: Napravljen `tool/check_coverage.dart` i dodat CI korak sa pragom `--min-coverage=26.0`.
   - **Price/Input Parsing**: Proširen `test/number_input_utils_test.dart` (pokriveni srpski i anglosaksonski separatori, razmaci, nevalidni unosi; rešen bug sa trojkama u `NumberInputUtils`).
   - **ChatService**: Dodat `test/chat_service_test.dart` koji pokriva uspešan upsert, PostgrestException fallback, pronalaženje razgovora i ažuriranje `order_id`.
   - **PushService**: Dodat `test/push_service_test.dart` (deterministički notification ID, dedup, rutiranje kanala, generacije i čišćenje starih tokena na istoj instalaciji).
   - **ClassifiedsProvider**: Dodat `test/classifieds_provider_test.dart` (stablo potkategorija, distrikti/gradovi, primenjivost stanja, dinamički atributi, race-safety sekvence i roll-up brojača).
   - **CartProvider**: Proširen `test/cart_provider_test.dart` za `_migrateLegacyData` (otkriven i rešen kritičan deadlock između `_load()` i `_save()` u `CartProvider`).
9. **P3 – UX i funkcionalnost**
   - **Stavka 11 (Guest korpa)**: `CartProvider.claimGuestCart(userId)` vezuje artikle iz gostujuće sesije za nalog i prikazuje informativni baner u korpi.
   - **Stavka 12 (`signInAsGuest()` failure)**: Uklonjen tihi fail na 8s timeout i mrežne greške u `login_screen.dart`; korisnik ostaje na ekranu uz SnackBar i retry dugme.
   - **Stavka 13 (Digits only unosi)**: `CategoryAttribute.isDecimal` ograničava unos na cele brojeve za vozila i mehanizaciju (`year`, `mileage`, `cubic_capacity`, `power_hp`, `operating_hours`), a dozvoljava decimalne brojeve isključivo za nekretnine i cene.
10. **P4 – Higijena repozitorijuma**
   - Premenjen `NEXT_SESSION_NOTES.md` u `docs/NEXT_SESSION_NOTES.md`.
   - Ažuriran `.gitignore` sa `.venv/`, `venv/` i `chromium/`.
   - Verifikovan status `supabase/seed.sql` (test nalozi samo za lokalni db reset) i ažurirana konsolidacija u `docs/MIGRATIONS_SOLO.md`.

---

## 🚀 Predlozi i teme za sledeću sesiju

### Glavni razvojni pravci (Sledeća faza):
1. **Faza 8 – Direktna ponuda cene / Cenkanje (Make an Offer)**
   - Dugme „Ponudi cenu” na detaljima oglasa.
   - Mogućnost da prodavac prihvati, odbije ili ponudi kontra-ponudu.
   - Povezivanje sa chatom za razmenu detalja.

### Sitna tehnička doterivanja zabeležena u backlogu:
- [x] **Cena unos**: `NumberInputUtils.parseDecimal` validacija hiljada i decimala, zaokruživanje na najviše 2 decimale.
- [x] **Web guest flow**: `signInAsGuest()` preskače ako već postoji `currentUser` (eliminisani suvišni logovi grešaka i nepotrebni mrežni pozivi).
- [x] **Unread count debounce**: zamenjen direktan `_loadUnreadCount()` sa `_scheduleLoadUnreadCount()` za auth event-e (sprečeni rafali identičnih SQL upita).

---

## 🛠️ Komande za brzu proveru na početku sesije

```bash
# 1. Provera statičke analize
dart analyze lib/ test/ tool/

# 2. Pokretanje svih testova (očekivano: 195 passing)
flutter test

# 3. Verifikacija pokrivenosti i prag u CI
dart run tool/check_coverage.dart --min-coverage=26.0

# 4. Verifikacija sigurnosti SQL migracija
dart run tool/scan_security_definer_migrations.dart
```
