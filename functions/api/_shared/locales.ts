// Centralna jezička i hreflang konfiguracija.
//
// Produkciona odluka: Domaći Market je isključivo na srpskom jeziku (`sr-RS`).
// `ENABLED_LOCALES` navodi jedinu aktivnu verziju sajta (`sr-RS`), a hreflang
// mapa emituje `sr-RS` + `x-default` (na istu URL adresu) — konzistentno sa
// SPA shell-om (`web/index.html`) i XML sitemapom.

export type LocaleConfig = {
  /** hreflang vrednost (ISO 639-1 jezik + ISO 3166-1 zemlja, npr. "sr-RS"). */
  hreflang: string;
  /** URL prefiks verzije ("" = osnovna verzija bez prefiksa). */
  urlPrefix: string;
  /** Open Graph `og:locale` vrednost (npr. "sr_RS"). */
  ogLocale: string;
};

/** Aktivna jezička konfiguracija sajta (isključivo srpski, `sr-RS`). */
export const LOCALE_PLAN: LocaleConfig[] = [
  { hreflang: "sr-RS", urlPrefix: "", ogLocale: "sr_RS" },
];

/**
 * Trenutno AKTIVNE verzije (`sr-RS`). Hreflang mapa emituje `sr-RS` + `x-default`
 * na istu kanonsku URL adresu — konzistentno sa SPA shell-om (`web/index.html`).
 */
export const ENABLED_LOCALES: LocaleConfig[] = LOCALE_PLAN;

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
