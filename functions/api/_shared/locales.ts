// Centralna i18n/hreflang konfiguracija — SEO na svetskom nivou (Faza 1).
//
// `LOCALE_PLAN` opisuje SVE jezičko-regionalne verzije sajta iz globalne SEO
// strategije (docs/SEO_GLOBALNI_PREDLOZI.md). `ENABLED_LOCALES` navodi SAMO
// verzije koje su trenutno dostupne (HTTP 200, indeksabilne, sa lokalizovanim
// sadržajem).
//
// PRAVILO: Google zahteva da svaki hreflang link bude reciprocan, kanonski i
// dostupan. Verziju dodajte u `ENABLED_LOCALES` TEK kada zaista postoji
// (npr. /en/ verzija sa engleskim prevodom) — u suprotnom će Google Search
// Console prijaviti hreflang greške ("no return tag" / 404).
//
// Ovaj modul nema spoljnih import-a da bi bio upotrebljiv i u Cloudflare
// Pages Functions (`functions/`) i u Vercel Edge funkcijama (`api/`) bez
// cirkularnih zavisnosti.

export type LocaleConfig = {
  /** hreflang vrednost (ISO 639-1 jezik + ISO 3166-1 zemlja, npr. "sr-RS"). */
  hreflang: string;
  /** URL prefiks verzije ("" = osnovna verzija bez prefiksa, npr. "en"). */
  urlPrefix: string;
  /** Open Graph `og:locale` vrednost (npr. "sr_RS"). */
  ogLocale: string;
};

/** Potpuni plan verzija po globalnoj SEO strategiji. */
export const LOCALE_PLAN: LocaleConfig[] = [
  { hreflang: "sr-RS", urlPrefix: "", ogLocale: "sr_RS" },
  { hreflang: "bs-BA", urlPrefix: "bh", ogLocale: "bs_BA" },
  { hreflang: "hr-HR", urlPrefix: "hr", ogLocale: "hr_HR" },
  { hreflang: "de-DE", urlPrefix: "de", ogLocale: "de_DE" },
  { hreflang: "en", urlPrefix: "en", ogLocale: "en_US" },
];

/**
 * Trenutno AKTIVNE verzije. Dok postoji samo srpska verzija sajta, hreflang
 * mapa emituje `sr-RS` + `x-default` (na istu URL adresu) — konzistentno sa
 * SPA shell-om (`web/index.html`). Dodavanje nove verzije = jedan red ovde.
 */
export const ENABLED_LOCALES: LocaleConfig[] = LOCALE_PLAN.filter(
  (locale) => locale.hreflang === "sr-RS",
);

/** hreflang vrednost koja se koristi za `x-default` fallback. */
export const X_DEFAULT_FALLBACK = "sr-RS";

function escapeHtmlAttr(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

export type HreflangEntry = {
  lang: string;
  href: string;
};

/**
 * Gradi listu hreflang parova (lang -> href) za zadati kanonski URL stranice.
 * `baseUrl` je autoritativni javni bazni URL (bez trailing slash), a
 * `canonicalUrl` apsolutni kanonski URL stranice (može da sadrzi `?query`).
 * Za nevalidan URL vraca praznu listu.
 */
export function resolveHreflangEntries(
  canonicalUrl: string,
  baseUrl: string,
): HreflangEntry[] {
  let pathname = "/";
  let search = "";
  try {
    const parsed = new URL(canonicalUrl);
    pathname = parsed.pathname;
    search = parsed.search;
  } catch {
    return [];
  }

  const cleanBase = baseUrl.replace(/\/+$/, "");
  // Početna stranica: pathname "/" -> "/" sufiks (konzistentno sa SPA shell-om
  // `web/index.html` i sitemap <loc> vrednošću `${baseUrl}/`).
  const path = pathname === "/" ? "/" : `${pathname}${search}`;

  const entries: HreflangEntry[] = ENABLED_LOCALES.map((locale) => ({
    lang: locale.hreflang,
    href: `${cleanBase}${locale.urlPrefix ? `/${locale.urlPrefix}` : ""}${path}`,
  }));

  const fallback =
    ENABLED_LOCALES.find((locale) => locale.hreflang === X_DEFAULT_FALLBACK) ??
    ENABLED_LOCALES[0];
  if (fallback) {
    entries.push({
      lang: "x-default",
      href: `${cleanBase}${fallback.urlPrefix ? `/${fallback.urlPrefix}` : ""}${path}`,
    });
  }

  return entries;
}

/** HTML `<link rel="alternate" hreflang=...>` tagovi za `<head>` bot-SSR stranica. */
export function buildHreflangLinks(canonicalUrl: string, baseUrl: string): string {
  return resolveHreflangEntries(canonicalUrl, baseUrl)
    .map(
      (entry) =>
        `  <link rel="alternate" hreflang="${entry.lang}" href="${escapeHtmlAttr(entry.href)}">`,
    )
    .join("\n");
}

/** `<xhtml:link>` tagovi za `<url>` element XML sitemape. */
export function buildHreflangXmlLinks(canonicalUrl: string, baseUrl: string): string {
  return resolveHreflangEntries(canonicalUrl, baseUrl)
    .map(
      (entry) =>
        `    <xhtml:link rel="alternate" hreflang="${entry.lang}" href="${escapeHtmlAttr(entry.href)}"/>`,
    )
    .join("\n");
}