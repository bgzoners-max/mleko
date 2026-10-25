# 🌍 SEO Optimizacija na Svetskom Nivou — Predlozi i Strategija

**Projekat:** Domaći Market (domacimarket.rs)  
**Uloga:** Inženjer SEO optimizacije  
**Trenutno:** Srbija (.rs, srpski) → **Cilj:** globalna/međunarodna prisustvenost  
**Osnova:** Odlična (sitemap, robots.txt, canonical, hreflang samo početna, OpenGraph, Schema.org, bot SSR), ali ograničena na jedno tržište i jezik.

---

## 1. Analiza trenutnog stanja

| Oblast | Stanje | Procena |
|--------|--------|---------|
| Domen | domacimarket.rs (ccTLD Srbija) | Dobro lokalno, ograničava globalno |
| Jezik | Samo srpski | Mora se proširiti |
| hreflang | sr, sr-RS, x-default (samo /) | Delimično; treba na sve stranice |
| Sitemap | Dinamički, 42 URL-a | OK, dodati međunarodne verzije |
| Robots.txt | Konfigurovano, Sitemap naveden | OK |
| Kanonski linkovi | Unikatni po ruti/proizvodu | OK |
| OpenGraph | og:title, desc, image, url | OK |
| Schema.org | Org, WebSite, Breadcrumb, ItemList, FAQ, Product | Odlična baza |
| Bot SSR | Googlebot, Viber, WhatsApp, FB | OK |
| Hosting | Cloudflare Pages (globalna CDN) | Odlično |

**Glavni prepreke za svetski nivou:** jedan jezik/domena, nema geo-targetinga, nema lokalizovanih cena/valuta/isporuka, nema hreflang mape za sve stranice.

---

## 2. Cilj

Vidljivost i organski promet sa više međunarodnih tržišta (početno: BiH, Hrvatska, Crna Gora, Slovenija, Austrija, Nemačka, Švicarska, a kasnije EU i svet), sa lokalizovanim verzijama koje Google razume kao povezane entitete.

---

## 3. Arhitektura domena i URL-ova

**Preporučena Opcija A (poddirektorijumi):** konsoliduje autoritet jedne domene i je lako za održavanje na Cloudflare Pages.

```
https://domacimarket.rs/          -> x-default / globalna (srpski)
https://domacimarket.rs/sr/       -> srpski / Srbija
https://domacimarket.rs/bh/       -> bosanski / BiH
https://domacimarket.rs/hr/       -> hrvatski / Hrvatska
https://domacimarket.rs/de/       -> nemački / D-A-CH
https://domacimarket.rs/en/       -> engleski / svetski fallback
```

Alternative (slabije za početak): subdomene (sr.domacimarket.rs) ili zasebne ccTLD (domacimarket.ba, .hr, .de).

---

## 4. Hreflang strategija (kritično)

Svaka stranica treba `hreflang` za sebe i sve druge verzije, uključujući `x-default`. Pravila:
- ISO 639-1 jezik + ISO 3166-1 zemlja (npr. `sr-RS`, `de-DE`, `en-GB`).
- **Reciprocni linkovi:** ako A linkuje na B, B mora linkovati nazad na A.
- Svi hreflang URL-ovi moraju biti kanonski, dostupni (200 OK) i ne blokovani `robots.txt`.
- Dodati `<xhtml:link rel="alternate" hreflang="..." href="..."/>` u XML sitemap.

**Primer (srpska kategorija):**
```html
<link rel="canonical" href="https://domacimarket.rs/sr/klasici-cvarci/">
<link rel="alternate" hreflang="sr-RS" href="https://domacimarket.rs/sr/klasici-cvarci/">
<link rel="alternate" hreflang="bs-BA" href="https://domacimarket.rs/bh/cvarci/">
<link rel="alternate" hreflang="hr-HR" href="https://domacimarket.rs/hr/slanina/">
<link rel="alternate" hreflang="de-DE" href="https://domacimarket.rs/de/speck/">
<link rel="alternate" hreflang="en" href="https://domacimarket.rs/en/cured-meat/">
<link rel="alternate" hreflang="x-default" href="https://domacimarket.rs/en/cured-meat/">
```

## 5. Tehnička SEO (svetski standard)

- **Sitemap:** generisati za sve verzije, sa `lastmod`, prioritetima i hreflang linkovima; slati u GSC.
- **Robots.txt:** `Allow: /`, `Disallow` za /admin/, /auth/, /cart/, /checkout/, /api/, /cdn-cgi/; navesti sve `Sitemap:`.
- **Kanonski linkovi:** svaka lokalizovana verzija ima **svoj self-canonical**, ne pokazuje na domaću verziju. Parametre (`?category=`) konsolidovati kanonskim linkom.
- **Core Web Vitals:** LCP < 2,5 s, INP < 200 ms, CLS < 0,1. Cloudflare CDN, WebP/AVIF slike, lazy loading, lokalni fontovi sa `font-display: swap`. Testirati iz više svetskih lokacija (PageSpeed Insights, WebPageTest).
- **Mobilno:** mobile-first, responzivan dizajn, bez blokirajućih intersticija.

## 6. Strukturirani podaci (Schema.org JSON-LD)

Deklarisati za sve verzije: `Organization`, `WebSite`, `BreadcrumbList`, `ItemList`/`CollectionPage`, `Product`/`Offer`, `FAQPage`, `LocalBusiness`.
- **Važno:** `priceCurrency` po zemlji (RSD, EUR, BAM, HRK, CHF...) i cena u lokalnoj valuti, inače nema rich snippeta izvan Srbije.
- Lokalizovati `name`, `description`, breadcrumb-ove i FAQ pitanja po jeziku.

## 7. Sadržaj i ključne reči po tržištima

Raditi zaseban ključni-rečnik po zemlji i lokalizovati sadržaj (ne samo automatski prevod):

| Tržište | Teme | Primer ključnih reči |
|---------|------|----------------------|
| Srbija (sr) | Domaća hrana, mali oglasi | domaći proizvodi, mali oglasi srbija, seoska hrana |
| BiH (bs) | Domaća hrana, oglasi | domaći proizvodi bosna, mali oglasi bih |
| Hrvatska (hr) | Domaći proizvodi, oglasi | domaći proizvodi hrvatska, besplatni oglasi |
| Nemačka (de) | Bio/regionalna hrana | regionale produkte, kostenlose kleinanzeigen |
| Austrija (de-AT) | | regionalprodukte, kostenlose kleinanzeigen |
| Švicarska (de-CH/fr) | | produits régionaux, annonces gratuites |
| Svetski (en) | Balkan food, homemade | balkan food, homemade products, free classifieds |

Dodati jezički preklopnik (language switcher) i internu linkovanost između verzija. Blog članke lokalizovati sa regionalnim primerima.

## 8. Lokalni SEO i geo-targeting

- Verifikovati verzije u **Google Search Console**; za poddirektorijume postaviti geo-targeting po zemlji (npr. `/de/` → Nemačka).
- **Google Business Profile** za fizičke lokacije (Beč, Berlin, Zagreb, Sarajevo...).
- NAP konzistentnost (ime, adresa, telefon) u lokalnim direktorijumima.
- Lokalni backlinks: regionalni poljoprivredni portali, blogovi, komore preduzetništva.

## 9. Link building (svetsko)

Backlinks iz ciljnih zemalja imaju veći uticaj za rangiranje u tom tržištu. Direktori oglasa, PR o ekološkoj hrani, guest posting na sajtovima o zdravkoj hrani i putovanjima po Balkanu, socijalne mreže (Facebook, Instagram, Viber, WhatsApp već OpenGraph-integrisani).

## 10. Analitika i KPI-vi

**Alati:** GSC po zemlji, GA4, Ahrefs/Semrush, Screaming Frog (hreflang/canonical audit).

| KPI | Cilj (6–12 meseci) |
|-----|--------------------|
| Organski promet izvan Srbije | +300 % |
| Indeksirane stranice po jeziku | 100% lokalizovanih ruta |
| Top-10 rangiranje ključnih reči po zemlji | 5+ po tržištu |
| CTR iz pretrage (globalno) | > 3 % |
| Core Web Vitals (mobilno) | "Good" svuda |
| Hreflang greške u GSC | 0 |

## 11. Implementacioni plan (roadmap)

| Faza | Vreme | Akcije |
|------|-------|--------|
| 1. Tehnička osnova | 1–2 ned. | Hreflang na sve stranice, prošireni sitemap, GSC geo-targeting |
| 2. Prvi poddirektorijumi | 3–4 ned. | `/sr/`, `/bh/`, `/hr/`, `/en/`; lokalizovani title/meta/schema |
| 3. Proizvodi i cene | 1–2 meseca | Lokalizovani proizvodi, valute, `priceCurrency` |
| 4. D-A-CH i svet | 2–3 meseca | `/de/`, `/de-at/`, `/de-ch/`, `/fr-ch/`, prevod bloga/FAQ |
| 5. Link building i PR | Ongoing | Backlinks iz ciljnih zemlja, GBP, lokalni direktorijumi |
| 6. Optimizacija | Ongoing | A/B testovi title/meta, praćenje KPI, novi jezici |

## 12. Primer koda (Cloudflare Functions / TypeScript)

```ts
const LOCALES = ['sr-RS','bs-BA','hr-HR','de-DE','de-AT','de-CH','fr-CH','en'] as const;
const BASE = 'https://domacimarket.rs';
export function hreflangLinks(path: string): string {
  return LOCALES.map(loc => {
    const prefix = loc === 'sr-RS' ? 'sr' : loc.split('-')[0].toLowerCase();
    return `<link rel="alternate" hreflang="${loc}" href="${BASE}/${prefix}${path}">`;
  }).join('\n') +
  `<link rel="alternate" hreflang="x-default" href="${BASE}/en${path}">`;
}
```

## 13. Zaključak

Tehnička osnova Domaćeg Marka je izuzetno dobra za Srbiju. Za **SEO na svetskom nivou** ključni su: međunarodna URL struktura, pun hreflang map, lokalizovan sadržaj (ne samo prevod), Schema.org sa lokalnim valutama, geo-targeting u GSC i lokalni backlinks. Ovim koracima sajt može competitive rangirati u regionu i svetu za termine oko domaćih proizvoda i besplatnih malih oglasa.

**Autor:** Inženjer SEO optimizacije · **Datum:** 25.10.2026 · **Putanja:** `c:\dev\mleko\docs\SEO_GLOBALNI_PREDLOZI.md`