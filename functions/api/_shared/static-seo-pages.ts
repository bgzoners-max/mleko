// Server-rendered SEO payloads for key public SPA routes.
//
// Flutter Web paints content on <canvas>, so crawlers cannot extract any text
// from the SPA shell (`index.html`). The shell also hardcodes the homepage
// canonical for EVERY route, which tells Google that /classifieds, /categories,
// /search etc. are duplicates of the homepage (GSC: "Duplicate without
// user-selected canonical"). The Pages middleware serves HTML built from
// these payloads to verified bot user-agents instead — with a unique
// title/description/canonical per route and per category.
//
// IMPORTANT: canonical URLs here must stay identical to the `loc` values
// emitted by `api/sitemap.ts` (including `?category=` variants).

import {
  normalizeBaseUrl,
  resolvePublicBaseUrl,
  type HtmlPayload,
} from "./preview-utils.js";

type RouteSeo = {
  title: string;
  description: string;
  heading: string;
  paragraphs: string[];
};

type CategorySeo = {
  name: string;
  description: string;
  body: string;
};

const SITE_NAME = "Domaći Market";
const BASE_URL_PATH_CLASSIFIEDS = "/classifieds";
const BASE_URL_PATH_CATEGORIES = "/categories";

const BASE_ROUTES: Record<string, RouteSeo> = {
  "/classifieds": {
    title: `Besplatni Mali Oglasi u Srbiji | ${SITE_NAME}`,
    description:
      "Besplatni mali oglasi u Srbiji bez provizije: traktori, automobili, poljoprivredne mašine, alati, nekretnine, stoka, tehnika i oprema. Postavite oglas potpuno besplatno.",
    heading: "Besplatni Mali Oglasi u Srbiji — 0 dinara provizije",
    paragraphs: [
      "Postavite oglas potpuno besplatno, bez skrivenih troškova i bez limita. Vraćanje oglasa na vrh pretrage (obnavljanje) košta tačno 0 dinara kad god poželite.",
      "Istražite kategorije malih oglasa: poljoprivreda i mehanizacija, vozila i auto-moto, mašine i alati, dom i bašta, mobilni telefoni, računari i elektronika, nekretnine, građevinarstvo, odeća i obuća, sve za decu i bebe, sport i hobi, kućni ljubimci, usluge, zdravlje i lepota, knjige i umetnost i rukotvorine.",
    ],
  },
  "/categories": {
    title: `Pijaca domaće hrane | ${SITE_NAME}`,
    description:
      "Kupujte domaće proizvode direktno sa seoskih gazdinstava širom Srbije: sir, kajmak, mleko, meso, med, zimnica, jaja, brašno, rakije i vino — bez posrednika i marži.",
    heading: "Pijaca domaće hrane — direktno sa seoskih gazdinstava",
    paragraphs: [
      "Kupujte autentične proizvode direktno od vrednih domaćina bez posrednika i trgovačkih marži: mlečni proizvodi, meso i delikatesi, med, voće i povrće, slana i slatka zimnica, brašno i testenine, domaća jaja, vina i domaće rakije.",
      "Ponudu možete pretražiti po kategorijama, gradovima i opštinama širom Srbije, a porudžbine se šalju direktno gazdinstvu koje proizvode priprema po vašem zahtevu.",
    ],
  },
  "/search": {
    title: `Pretraga domaće hrane | ${SITE_NAME}`,
    description:
      "Pretražite ponudu domaće hrane širom Srbije po kategorijama, gradovima i opštinama — direktno od proverenih seoskih gazdinstava, bez posrednika.",
    heading: "Pretraga domaće hrane",
    paragraphs: [
      "Pretražite sve domaće proizvode na pijaci Domaćeg Marketa: filtrirajte po kategoriji, gradu i opštini, uporedite cene i pošaljite upit direktno gazdinstvu.",
      "Proizvodi se naručuju direktno od seoskih gazdinstava koja hranu pripremaju po zahtevu — sveže, sezonski i bez posrednika.",
    ],
  },
  "/sellers-map": {
    title: `Mapa seoskih gazdinstava | ${SITE_NAME}`,
    description:
      "Pogledajte na karti gde se nalaze proverena seoska gazdinstva u Srbiji i pronađite domaće proizvode u svom kraju — mleko, sir, meso, med i zimnicu.",
    heading: "Mapa seoskih gazdinstava",
    paragraphs: [
      "Pronađite seoska gazdinstva u svom kraju na interaktivnoj karti Srbije i kupujte domaće proizvode direktno od proizvođača.",
      "Svako gazdinstvo na mapi je registrovano sa verifikovanom lokacijom i kontakt podacima, a ponuda se stalno ažurira.",
    ],
  },
  "/about": {
    title: `O Domaćem Marketu | ${SITE_NAME}`,
    description:
      "Domaći Market povezuje lokalne poljoprivredne proizvođače i seoska gazdinstva sa kupcima širom Srbije — pijaca domaće hrane i besplatni mali oglasi bez provizije.",
    heading: "O Domaćem Marketu",
    paragraphs: [
      "Domaći Market je platforma koja objedinjuje dve celine: direktnu pijacu domaće hrane sa seoskih poljoprivrednih gazdinstava i 100% besplatne male oglase za kupovinu i prodaju mehanizacije, vozila, alata, tehnike i nekretnina — bez posrednika i bez provizije.",
      "Misija platforme je da vrati poverenje između domaćina i kupaca: svako gazdinstvo se registruje sa verifikovanom lokacijom i kontakt telefonom.",
    ],
  },
  "/vodic-za-proizvodjace": {
    title: `Kako postaviti domaće proizvode na Pijacu — Vodič za proizvođače | ${SITE_NAME}`,
    description:
      "Korak po korak vodič za gazdinstva i proizvođače domaće hrane: besplatna registracija, otvaranje prodavničkog profila na Pijaci, dodavanje proizvoda i primanje porudžbina — bez provizije. Saznajte i razliku između Pijace i Malih oglasa.",
    heading:
      "Vodič za proizvođače — kako postaviti domaće proizvode na domacimarket.rs",
    paragraphs: [
      "Domaći Market ima dva dela: Pijacu domaće hrane, gde poljoprivredna gazdinstva otvaraju svoju online tezgu i primaju porudžbine, i 100% besplatne Male oglase, namenjene mehanizaciji, vozilima, alatima, nekretninama i svemu što nije hrana. Domaća hrana — sir, kajmak, mleko, meso, med, zimnica, jaja, rakije — izlaže se isključivo na Pijaci.",
      "Postavljanje proizvoda je jednostavno i besplatno: registrujte nalog, otvorite prodavnički profil („Postani prodavac“), dodajte proizvode sa fotografijama, cenom i mernom jedinicom, a kupci vas pronalaze kroz kategorije, pretragu i mapu gazdinstava i šalju porudžbine direktno vama. Platforma ne naplaćuje proviziju niti učestvuje u naplati.",
    ],
  },
};
// Classified ad categories (slugs must match CLASSIFIED_CATEGORIES in api/sitemap.ts).
const CLASSIFIED_CATEGORY_SEO: Record<string, CategorySeo> = {
  poljoprivreda: {
    name: "Poljoprivreda i mehanizacija",
    description:
      "Oglasi traktora (IMT, IMR, Belarus, Zetor, Ursus, John Deere), kombajna, priključnih mašina, plugova, sejalica, sadnica, stočne hrane i poljoprivredne opreme — besplatno.",
    body: "Traktori (IMT, IMR, Belarus, Zetor, Ursus, John Deere), kombajni, priključne mašine, plugovi, sejalice, drljače, tanjirače, sadnice voća, semena, stočna hrana, bale sena, silaža i poljoprivredna oprema.",
  },
  vozila: {
    name: "Vozila i auto-moto",
    description:
      "Polovni i novi automobili, auto delovi, gume, felne, motocikli, skuteri, teretna vozila, kombiji, traktorske i auto prikolice — oglasi bez provizije.",
    body: "Polovni i novi automobili (Volkswagen, Audi, BMW, Mercedes-Benz, Opel, Fiat, Peugeot, Renault), auto delovi, gume, felne, motocikli, skuteri, teretna vozila, kombi, traktorske i auto prikolice.",
  },
  masine_alati: {
    name: "Mašine, alati i zanatstvo",
    description:
      "Električni i akumulatorski alati, aparati za varenje, kompresori, agregati za struju, radionički stolovi i bravarski i stolarski alati — besplatni oglasi.",
    body: "Električni i akumulatorski alati (bušilice, brusilice, motorne testere Stihl i Husqvarna), aparati za varenje, kompresori, agregati za struju, radionički stolovi, bravarski i stolarski alati.",
  },
  dom_basta: {
    name: "Dom, nameštaj i bašta",
    description:
      "Bela tehnika (frižideri, šporeti, veš mašine), nameštaj, peći na drva i pelet, kotlovi za grejanje, kosilice, motokultivatori, trimeri i baštenski alati.",
    body: "Bela tehnika (frižideri, šporeti, veš mašine, zamrzivači), nameštaj za kuću i dvorište, peći na drva i pelet, kotlovi za grejanje, kosilice, motokultivatori, trimeri i baštenski alati.",
  },
  telefoni: {
    name: "Mobilni telefoni i oprema",
    description:
      "Pametni telefoni (Apple iPhone, Samsung Galaxy, Xiaomi, Honor, Motorola), tableti, brzi punjači, maske, zaštitna stakla i dodatna mobilna oprema.",
    body: "Pametni telefoni (Apple iPhone, Samsung Galaxy, Xiaomi, Honor, Motorola), tableti, brzi punjači, maske, zaštitna stakla i dodatna mobilna oprema.",
  },
  tehnika: {
    name: "Računari i elektronika",
    description:
      "Laptopovi, desktop konfiguracije, monitori, televizori (Smart TV), audio sistemi, pojačala, zvučnici, sigurnosne kamere i elektronske komponente.",
    body: "Laptopovi, desktop konfiguracije, monitori, televizori (Smart TV), audio sistemi, pojačala, zvučnici, sigurnosne kamere i elektronske komponente.",
  },
  nekretnine: {
    name: "Nekretnine",
    description:
      "Seoska gazdinstva, imanja, obradiva zemlja, njive, voćnjaci, placevi, seoske kuće, vikendice, kuće i stanovi za prodaju i izdavanje širom Srbije.",
    body: "Seoska gazdinstva, imanja, obradiva zemlja, njive, voćnjaci, placevi, seoske kuće, vikendice, kuće i stanovi za prodaju i izdavanje širom Srbije.",
  },
  gradjevinarstvo: {
    name: "Građevinarstvo i materijali",
    description:
      "Građevinski materijal, armatura, blokovi, crep, drvena građa, daske, skele, izolacija, stiropor i PVC i aluminijumska stolarija.",
    body: "Građevinski materijal, armatura, blokovi, crep, drvena građa, daske, skele, izolacija, stiropor, PVC i aluminijumska stolarija.",
  },
  odeca_obuca: {
    name: "Odeća, obuća i aksesoari",
    description:
      "Radna odela, uniforme, zimske jakne, kaputi, svečana odeća, narodna nošnja, garderoba, obuća, čizme, patike, torbe i novčanici.",
    body: "Radna odela, uniforme, zimske jakne, kaputi, svečana odeća, narodna nošnja, muška, ženska i dečija garderoba, obuća, čizme, patike, torbe i novčanici.",
  },
  deca_bebe: {
    name: "Sve za decu i bebe",
    description:
      "Dečija kolica i nosiljke, auto-sedišta, kreveci, kolevke, hranilice, igračke (LEGO, autići, lutke), edukativne i Montesori igračke.",
    body: "Dečija kolica i nosiljke, auto-sedišta za decu i busteri, kreveci, kolevke, komode za presvlačenje, hranilice, igračke (LEGO, autići, lutke), edukativne i Montesori igračke, hodalice (dubak), ogradice i bebi alarmi.",
  },
  sport_hobi: {
    name: "Sport, lov, ribolov i hobi",
    description:
      "Pribor za ribolov i lov, skijanje, bicikli, fitnes sprave, kamp oprema, roleri, trotineti, borilačka oprema i muzički instrumenti.",
    body: "Pribor za ribolov (štapovi, mašinice, varalice), oprema za lov, skijanje i zimski sportovi, bicikli (MTB, drumski, gradski), fitnes sprave, kamp oprema, vodeni sportovi (SUP daske), roleri, trotineti, borilačka oprema i muzički instrumenti.",
  },
  ljubimci: {
    name: "Kućni ljubimci",
    description:
      "Psi, štenci, mačke, mačići, ptice, papagaji, kanarinci, ribice i hrana i oprema za kućne ljubimce.",
    body: "Psi, štenci, mačke, mačići, ptice, papagaji, kanarinci, ribice i hrana i oprema za kućne ljubimce.",
  },
  usluge: {
    name: "Usluge i poslovi",
    description:
      "Poljoprivredne usluge (oranje, tanjiranje, setva, baliranje, žetva kombajnom), prevoz robe, selidbe, građevinski i zanatski radovi, IT usluge i knjigovodstvo.",
    body: "Poljoprivredne usluge (oranje, tanjiranje, setva, baliranje, žetva kombajnom), prevoz robe i selidbe, građevinski i zanatski radovi, IT usluge, knjigovodstvo, profesionalna ugostiteljska i trgovačka oprema.",
  },
  zdravlje_lepota: {
    name: "Zdravlje i lepota",
    description:
      "Originalni parfemi i toaletne vode, prirodna kozmetika, čajevi i biljni preparati, eterična ulja, aparati za kosu i medicinski aparati.",
    body: "Originalni muški i ženski parfemi i toaletne vode, prirodna kozmetika, čajevi i biljni preparati, eterična ulja, aparati za kosu (fenovi, prese, trimeri, brijači), fitnes suplementi i medicinski aparati (merači pritiska, inhalatori).",
  },
  knjige_edukacija: {
    name: "Knjige i edukacija",
    description:
      "Udžbenici za osnovnu i srednju školu, fakultetska literatura i skripte, stručne knjige, beletristika, romani, dečije knjige i stripovi.",
    body: "Udžbenici za osnovnu i srednju školu, fakultetska literatura i skripte, stručne knjige (medicina, pravo, ekonomija), beletristika, romani, dečije knjige i stripovi.",
  },
  umetnost_rukotvorine: {
    name: "Umetnost i rukotvorine",
    description:
      "Umetničke slike, skulpture, ručno rađeni nakit, keramika, grnčarija, pleteni i heklani proizvodi, tradicionalni vez i antikviteti.",
    body: "Umetničke slike, skulpture, ručno rađeni nakit, keramika, grnčarija, pleteni i heklani proizvodi, tradicionalni vez, drvorezi, unikatne sveće i antikviteti.",
  },
};


// Food market categories (slugs must match FOOD_CATEGORIES in api/sitemap.ts).
const FOOD_CATEGORY_SEO: Record<string, CategorySeo> = {
  "mlecni-proizvodi": {
    name: "Mlečni proizvodi",
    description:
      "Domaći kravlji, kozji i ovčiji sir, sjenički sir, zlatiborski kajmak, sveže mleko, jogurt, surutka i domaći kefir direktno sa gazdinstava.",
    body: "Punomasni kravlji, kozji i ovčiji sir, sjenički sir, zlatiborski kajmak, sveže mleko, jogurt, surutka i domaći kefir — direktno sa seoskih gazdinstava širom Srbije.",
  },
  meso: {
    name: "Meso, riba i delikatesi",
    description:
      "Domaća pršuta, pečenica, slanina, kobasice, kulen, čvarci, jagnjetina, teletina i sveža i dimljena rečna riba sa gazdinstava.",
    body: "Domaća pršuta, pečenica, slanina, kobasice, kulen, čvarci, jagnjetina, teletina, sveža rečna riba (pastrmka, šaran) i dimljena riba.",
  },
  "voce-i-povrce": {
    name: "Voće i povrće",
    description:
      "Sezonsko domaće voće i povrće: paradajz, paprika, krompir, jabuke, šljive, maline, kupine, borovnice i sveže začinsko bilje.",
    body: "Domaći paradajz, paprika, krompir, jabuke, šljive, maline, kupine, borovnice i sveže začinsko bilje — ubrano po sezoni, direktno sa njiva i bašta.",
  },
  "med-i-pcelinji-proizvodi": {
    name: "Med i pčelinji proizvodi",
    description:
      "Bagremov, livadski, lipov i šumski med, propolis kapi, polen, matični mleč i medovača sa domaćih pčelinjaka. Med se prodaje na kilogram.",
    body: "Prirodni domaći med — bagremov, livadski, lipov i šumski, propolis kapi, polen, matični mleč i medovača sa proverenih pčelinjaka.",
  },
  "slana-zimnica": {
    name: "Slana zimnica i namazi",
    description:
      "Domaći ajvar (blagi i ljuti), pinđur, lovačka salata, turšija i kiseli kupus iz seoskih kuhinja — u teglama od 200 ml do 1 L.",
    body: "Domaći ajvar (blagi i cepkani ljuti), pinđur, lovačka salata, turšija i kiseli kupus — pripremljeni po tradicionalnim receptima iz seoskih kuhinja.",
  },
  "slatka-zimnica-i-dzemovi": {
    name: "Slatka zimnica i džemovi",
    description:
      "Tradicionalni džemovi (šljiva, kajsija, malina), slatko od šumskih jagoda i smokava, domaći sokovi, sirupi i sitni kolači (vanilice).",
    body: "Tradicionalni džemovi (šljiva, kajsija, malina), slatko od šumskih jagoda i smokava, domaći sokovi, sirupi i tradicionalni sitni kolači (vanilice).",
  },

  jaja: {
    name: "Domaća jaja",
    description:
      "Sveža konzumna jaja iz slobodnog uzgoja, prepeličja i domaća seoska jaja — naručena direktno od gazdinstva.",
    body: "Sveža konzumna jaja iz slobodnog uzgoja, prepeličja i domaća seoska jaja — iz slobodnog uzgoja, bez baterijskog držanja.",
  },
  "vina-i-domace-rakije": {
    name: "Vina i domaće rakije",
    description:
      "Domaća šljivovica, dunjevača, viljamovka, kajsijevača i zanatska vina iz srpskih vinograda — direktno od proizvođača.",
    body: "Domaća šljivovica, dunjevača, viljamovka, kajsijevača i zanatska vina iz srpskih vinograda — flaširana na gazdinstvu.",
  },
  "sokovi-i-domaci-sirupi": {
    name: "Sokovi i domaći sirupi",
    description:
      "Prirodno ceđeni domaći sokovi i sirupi — od šipka, drenjine, maline, koprive i drugog seoskog voća, bez veštačkih dodataka.",
    body: "Prirodno ceđeni domaći sokovi i sirupi od šipka, drenjine, maline, koprive i drugog seoskog voća — bez veštačkih boja i dodataka, u flašama od 0,5 L do 2 L.",
  },
  "brasno-testenine-i-zitarice": {
    name: "Brašno, testenine i žitarice",
    description:
      "Vodeničarsko kukuruzno i pšenično brašno, domaće kore za pitu i gibanicu, rezanci za supu i domaće testenine.",
    body: "Domaće kore za pitu i gibanicu, domaći rezanci za supu, testenine i vodeničarsko kukuruzno i pšenično brašno — mleveno na tradicionalan način.",
  },
  "hladno-cedjena-ulja-i-sirceta": {
    name: "Hladno ceđena ulja i sirća",
    description:
      "Bundevino, suncokretovo i maslinovo ulje hladnog ceđenja i prirodna domaća sirća — nerafinisana, sa sačuvanim ukusima.",
    body: "Hladno ceđena bundevino, suncokretovo i maslinovo ulje i prirodna domaća sirća — nerafinisana, bez toplotne obrade.",
  },
  "cajevi-zacini-i-lekovito-bilje": {
    name: "Čajevi, začini i lekovito bilje",
    description:
      "Planinski čajevi, domaći začini, lekovito bilje i mešavine sa srpskih planina — brani i sušeno na tradicionalan način.",
    body: "Planinski čajevi, domaći začini, lekovito bilje i mešavine sa srpskih planina — ručno brano i prirodno sušeno.",
  },
  "orasasti-plodovi-semenke-i-suvo-voce": {
    name: "Orašasti plodovi, semenke i suvo voće",
    description:
      "Domaći orasi, lešnici, bademi, semenke i prirodno sušeno voće — sa seoskih imanja i voćnjaka.",
    body: "Domaći orasi, lešnici, bademi, semenke i prirodno sušeno voće — iz seoskih voćnjaka i imanja, sušeno na prirodan način.",
  },
  "gljive-i-tartufi": {
    name: "Gljive i tartufi",
    description:
      "Šumske gljive, sušene pečurke i domaći tartufi sa proverenih sakupljača — sveže u sezoni ili sušeno cele godine.",
    body: "Šumske gljive, sušene pečurke i domaći tartufi — sakupljani na proverenim lokacijama, sveži u sezoni ili prirodno sušeni.",
  },
};

const CLASSIFIED_CATEGORY_CTA =
  "Oglasi u ovoj kategoriji su 100% besplatni — postavljanje i obnavljanje oglasa bez provizije.";
const FOOD_CATEGORY_CTA =
  "Proizvode naručujete direktno sa gazdinstva — porudžbina je upit, a gazdinstvo potvrđuje količinu, termin i isporuku.";

function normalizePathname(pathname: string): string {
  if (pathname.length > 1 && pathname.endsWith("/")) {
    return pathname.slice(0, -1);
  }
  return pathname;
}

/**
 * Resolves a server-rendered SEO payload for a public SPA route (or returns
 * `null` for routes the middleware should not handle). Category variants
 * (`/classifieds?category=slug`, `/categories?category=slug`) get a unique
 * title/description/canonical that matches the sitemap `loc` exactly.
 */
export function resolveStaticPageSeo(
  pathname: string,
  searchParams: URLSearchParams,
  origin?: string,
): HtmlPayload | null {
  const path = normalizePathname(pathname);
  const baseUrl = resolvePublicBaseUrl(
    origin ? normalizeBaseUrl(origin) : undefined,
  );

  let route = BASE_ROUTES[path];
  let canonicalUrl = `${baseUrl}${path === "/" ? "" : path}`;

  const categorySlug = searchParams.get("category")?.trim() ?? "";

  if (
    route &&
    categorySlug &&
    (path === BASE_URL_PATH_CLASSIFIEDS || path === BASE_URL_PATH_CATEGORIES)
  ) {
    const categorySeo =
      path === BASE_URL_PATH_CLASSIFIEDS
        ? CLASSIFIED_CATEGORY_SEO[categorySlug]
        : FOOD_CATEGORY_SEO[categorySlug];

    if (categorySeo) {
      const suffix =
        path === BASE_URL_PATH_CLASSIFIEDS ? " — Mali Oglasi" : "";
      route = {
        title: `${categorySeo.name}${suffix} | ${SITE_NAME}`,
        description: categorySeo.description,
        heading: categorySeo.name,
        paragraphs: [
          categorySeo.body,
          path === BASE_URL_PATH_CLASSIFIEDS
            ? CLASSIFIED_CATEGORY_CTA
            : FOOD_CATEGORY_CTA,
        ],
      };
      canonicalUrl = `${baseUrl}${path}?category=${encodeURIComponent(categorySlug)}`;
    }
  }

  if (!route) {
    return null;
  }

  return {
    title: route.title,
    description: route.description,
    previewUrl: canonicalUrl,
    canonicalUrl,
    imageUrl: `${baseUrl}/icons/Icon-512.png`,
    ogType: "website",
    ogSiteName: SITE_NAME,
    bodyHeading: route.heading,
    bodyParagraphs: route.paragraphs,
    redirectNote: "Učitavanje stranice...",
    linkLabel: "otvorite stranicu u aplikaciji",
  };
}

