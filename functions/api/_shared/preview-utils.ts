// Shared SEO/HTML helpers for Cloudflare Pages Functions & Edge previews.
// Both `product-preview` and `classified-preview` use these utilities.

import { buildHreflangLinks } from "./locales.js";

declare const process: any;

export type HtmlLinkItem = {
  label: string;
  href: string;
  meta?: string;
  badge?: string;
};

export type HtmlBreadcrumbItem = {
  label: string;
  href?: string;
};

export type HtmlSection = {
  heading: string;
  description?: string;
  links: HtmlLinkItem[];
};

export type HtmlPayload = {
  title: string;
  description: string;
  previewUrl: string;
  canonicalUrl: string;
  imageUrl: string;
  robots?: string;
  jsonLd?: Record<string, any> | Array<Record<string, any>>;
  ogType?: "product" | "website" | string;
  ogSiteName?: string;
  bodyHeading?: string;
  bodyParagraphs?: string[];
  breadcrumbs?: HtmlBreadcrumbItem[];
  sections?: HtmlSection[];
  navLinks?: HtmlLinkItem[];
  primaryCta?: HtmlLinkItem;
  omitRedirectFallback?: boolean;
  redirectNote?: string;
  linkLabel?: string;
};

export function normalizeBaseUrl(value: string): string {
  return value.trim().replace(/\/+$/, "");
}

const DEFAULT_CANONICAL_ORIGIN = "https://www.domacimarket.rs";

const WHITELISTED_ORIGINS = new Set([
  "https://www.domacimarket.rs",
  "https://staging.domacimarket.rs",
  "https://domacimarket.pages.dev",
]);

export function resolvePublicBaseUrl(origin?: string): string {
  const envUrl = typeof process !== "undefined"
    ? (process.env.SHARE_BASE_URL || process.env.STAGING_BASE_URL)
    : undefined;

  if (envUrl && typeof envUrl === "string" && envUrl.trim().length > 0) {
    return normalizeBaseUrl(envUrl.trim());
  }

  if (origin) {
    const cleanOrigin = normalizeBaseUrl(origin);
    if (/^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(cleanOrigin)) {
      return cleanOrigin;
    }
    if (WHITELISTED_ORIGINS.has(cleanOrigin)) {
      return cleanOrigin;
    }
  }

  return DEFAULT_CANONICAL_ORIGIN;
}

const BOT_USER_AGENTS = [
  "googlebot",
  "google-inspectiontool",
  "bingbot",
  "yandexbot",
  "duckduckbot",
  "baiduspider",
  "facebookexternalhit",
  "facebot",
  "meta-externalagent",
  "twitterbot",
  "rogerbot",
  "linkedinbot",
  "embedly",
  "quora link preview",
  "showyoubot",
  "outbrain",
  "pinterest",
  "slackbot",
  "vkshare",
  "w3c_validator",
  "whatsapp",
  "viber",
  "telegrambot",
  "discordbot",
  "applebot",
  "skypeuripreview",
  "petalbot",
  "bytespider",
  "threads",
];

export function isBot(userAgent: string | null | undefined): boolean {
  if (!userAgent) return false;
  const lower = userAgent.toLowerCase();
  return BOT_USER_AGENTS.some((bot) => lower.includes(bot));
}

export function escapeHtml(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

export function normalizeImageUrl(
  imageUrl: string | null | undefined,
  baseUrl: string,
): string {
  const fallback = `${baseUrl}/icons/Icon-512.png`;
  if (!imageUrl || typeof imageUrl !== "string") return fallback;

  if (imageUrl.startsWith("http://") || imageUrl.startsWith("https://")) {
    return imageUrl;
  }

  const cleanBase = baseUrl.replace(/\/+$/, "");
  if (imageUrl.startsWith("/")) {
    return `${cleanBase}${imageUrl}`;
  }
  return `${cleanBase}/${imageUrl}`;
}

function sanitizeJsonLd(jsonLd: Record<string, any>): string {
  return JSON.stringify(jsonLd)
    .replace(/</g, "\\u003c")
    .replace(/>/g, "\\u003e")
    .replace(/&/g, "\\u0026");
}

/**
 * Gradi `<link rel="alternate" hreflang=...>` tagove iz kanonskog URL-a
 * stranice (vidi `./locales.ts` — SEO na svetskom nivou, Faza 1).
 * Vraća prazan string ako nema aktivnih verzija ili URL nije validan.
 */
function deriveHreflangLinks(canonicalUrl: string): string {
  try {
    const { origin } = new URL(canonicalUrl);
    return buildHreflangLinks(canonicalUrl, resolvePublicBaseUrl(origin));
  } catch {
    return "";
  }
}

export function buildHtml({
  title,
  description,
  previewUrl,
  canonicalUrl,
  imageUrl,
  robots = "index,follow,max-image-preview:large",
  jsonLd,
  ogType = "product",
  ogSiteName = "Domaći Market",
  bodyHeading,
  bodyParagraphs,
  breadcrumbs,
  sections,
  navLinks,
  primaryCta,
  omitRedirectFallback = false,
  redirectNote = "Preusmeravanje...",
  linkLabel = "klikni ovde",
}: HtmlPayload): string {
  const escapedTitle = escapeHtml(title);
  const escapedDescription = escapeHtml(description);
  const escapedPreviewUrl = escapeHtml(previewUrl);
  const escapedCanonicalUrl = escapeHtml(canonicalUrl);
  const escapedImageUrl = escapeHtml(imageUrl);
  const escapedOgType = escapeHtml(ogType);
  const escapedOgSiteName = escapeHtml(ogSiteName);
  const escapedRedirectNote = escapeHtml(redirectNote);
  const escapedLinkLabel = escapeHtml(linkLabel);
  const escapedBodyHeading = bodyHeading ? escapeHtml(bodyHeading) : "";

  const hreflangLinks = deriveHreflangLinks(canonicalUrl);

  const jsonLdScript = Array.isArray(jsonLd)
    ? jsonLd
        .map((item) => `<script type="application/ld+json">${sanitizeJsonLd(item)}</script>`)
        .join("\n  ")
    : jsonLd
      ? `<script type="application/ld+json">${sanitizeJsonLd(jsonLd)}</script>`
      : "";

  const bodyParagraphsHtml =
    Array.isArray(bodyParagraphs) && bodyParagraphs.length > 0
      ? bodyParagraphs
          .map((paragraph) => `<p>${escapeHtml(paragraph)}</p>`)
          .join("\n    ")
      : "";

  const navHtml =
    Array.isArray(navLinks) && navLinks.length > 0
      ? `<header style="border-bottom: 1px solid #e2e8f0; padding-bottom: 12px; margin-bottom: 20px;">
      <nav aria-label="Glavna navigacija" style="display: flex; flex-wrap: wrap; gap: 14px;">
        ${navLinks
          .map(
            (link) =>
              `<a href="${escapeHtml(link.href)}" style="color: #1B5E20; font-weight: 600; text-decoration: none;">${escapeHtml(link.label)}</a>`,
          )
          .join("\n        ")}
      </nav>
    </header>`
      : "";

  const breadcrumbsHtml =
    Array.isArray(breadcrumbs) && breadcrumbs.length > 0
      ? `<nav aria-label="Putanja" style="font-size: 0.9em; color: #565959; margin-bottom: 12px;">
      ${breadcrumbs
        .map((item) =>
          item.href
            ? `<a href="${escapeHtml(item.href)}" style="color: #1B5E20; text-decoration: none;">${escapeHtml(item.label)}</a>`
            : `<span>${escapeHtml(item.label)}</span>`,
        )
        .join(" &rsaquo; ")}
    </nav>`
      : "";

  const sectionsHtml =
    Array.isArray(sections) && sections.length > 0
      ? sections
          .filter((sec) => sec.links.length > 0 || sec.description)
          .map((sec) => {
            const descHtml = sec.description
              ? `<p style="color: #4a5568; margin: 6px 0 12px;">${escapeHtml(sec.description)}</p>`
              : "";
            const itemsHtml =
              sec.links.length > 0
                ? `<ul style="list-style: none; padding: 0; margin: 0; display: grid; gap: 8px;">
        ${sec.links
          .map((link) => {
            const metaHtml = link.meta
              ? ` <span style="color: #565959; font-size: 0.92em;">&mdash; ${escapeHtml(link.meta)}</span>`
              : "";
            const badgeHtml = link.badge
              ? ` <span style="display: inline-block; padding: 2px 6px; font-size: 0.8em; background: #edf7ed; color: #1B5E20; border-radius: 4px;">${escapeHtml(link.badge)}</span>`
              : "";
            return `<li><a href="${escapeHtml(link.href)}" style="color: #1B5E20; font-weight: 600;">${escapeHtml(link.label)}</a>${badgeHtml}${metaHtml}</li>`;
          })
          .join("\n        ")}
      </ul>`
                : "";
            return `<section style="margin-top: 24px;">
      <h2 style="font-size: 1.2em; color: #0f1111; margin: 0 0 8px;">${escapeHtml(sec.heading)}</h2>
      ${descHtml}${itemsHtml}
    </section>`;
          })
          .join("\n    ")
      : "";

  const ctaHtml = primaryCta
    ? `<p style="margin: 18px 0;"><a href="${escapeHtml(primaryCta.href)}" style="display: inline-block; background: #1B5E20; color: #ffffff; padding: 10px 18px; border-radius: 8px; text-decoration: none; font-weight: 600;">${escapeHtml(primaryCta.label)}</a></p>`
    : "";

  const fallbackHtml = omitRedirectFallback
    ? ""
    : `<p>${escapedRedirectNote}</p>
    <p style="font-size: 0.9em; color: #666;">Ako se ništa ne dešava,
      <a href="${escapedCanonicalUrl}" style="color: #1B5E20; font-weight: bold;">${escapedLinkLabel}</a>.</p>`;

  const hasRichLayout =
    Boolean(navHtml) || Boolean(breadcrumbsHtml) || Boolean(sectionsHtml) || omitRedirectFallback;

  const bodyInnerHtml = hasRichLayout
    ? `<main style="max-width: 960px; margin: 0 auto; padding: 24px 16px; font-family: system-ui, -apple-system, sans-serif; color: #0f1111; line-height: 1.6;">
    ${navHtml}
    ${breadcrumbsHtml}
    ${escapedBodyHeading ? `<h1 style="font-size: 1.7em; margin: 8px 0 12px;">${escapedBodyHeading}</h1>` : ""}
    ${bodyParagraphsHtml ? `${bodyParagraphsHtml}\n    ` : (escapedDescription ? `<p>${escapedDescription}</p>\n    ` : "")}
    ${ctaHtml}
    ${sectionsHtml}
    ${fallbackHtml}
  </main>`
    : `<div style="font-family: sans-serif; text-align: center; margin-top: 50px;">
    ${escapedBodyHeading ? `<h1>${escapedBodyHeading}</h1>` : ""}
    ${bodyParagraphsHtml ? `${bodyParagraphsHtml}\n    ` : (escapedDescription ? `<p>${escapedDescription}</p>\n    ` : "")}
    ${fallbackHtml}
  </div>`;

  return `<!DOCTYPE html>
<html lang="sr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${escapedTitle}</title>
  <meta name="description" content="${escapedDescription}">
  <meta name="robots" content="${escapeHtml(robots)}">
  <link rel="canonical" href="${escapedCanonicalUrl}">

  ${hreflangLinks}

  <meta property="og:type" content="${escapedOgType}">
  <meta property="og:title" content="${escapedTitle}">
  <meta property="og:description" content="${escapedDescription}">
  <meta property="og:url" content="${escapedPreviewUrl}">
  <meta property="og:image" content="${escapedImageUrl}">
  <meta property="og:image:secure_url" content="${escapedImageUrl}">
  <meta property="og:image:alt" content="${escapedTitle}">
  <meta property="og:site_name" content="${escapedOgSiteName}">
  <meta property="og:locale" content="sr_RS">

  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="${escapedTitle}">
  <meta name="twitter:description" content="${escapedDescription}">
  <meta name="twitter:image" content="${escapedImageUrl}">
  <meta name="twitter:image:alt" content="${escapedTitle}">

  ${jsonLdScript}
</head>
  <body>
  ${bodyInnerHtml}
</body>
</html>`;
}

/**
 * Odlučuje da li apex `domacimarket.rs` zahtev treba preusmeriti 301 na `www.domacimarket.rs`.
 * Izuzetak: `/.well-known/assetlinks.json` mora vratiti direktan HTTP 200 na oba hosta
 * (Android App Links autoVerify odbija 3xx preusmerenja).
 */
export function resolveApexCanonicalRedirectUrl(requestUrl: URL): string | null {
  if (
    requestUrl.hostname !== "domacimarket.rs" ||
    requestUrl.pathname === "/.well-known/assetlinks.json"
  ) {
    return null;
  }
  const target = new URL(requestUrl.toString());
  target.hostname = "www.domacimarket.rs";
  if (target.pathname === "/shop" || target.pathname === "/shop/") {
    target.pathname = "/";
  } else if (target.pathname === "/terms" || target.pathname === "/terms/") {
    target.pathname = "/uslovi-koriscenja";
  }
  return target.toString();
}

/**
 * 301 preusmerenja zastarelih ili alternativnih putanja ka kanonskim rutama.
 */
export function resolveLegacyRouteRedirect(requestUrl: URL): string | null {
  if (requestUrl.pathname === "/shop" || requestUrl.pathname === "/shop/") {
    return new URL("/", requestUrl.origin).toString();
  }
  if (requestUrl.pathname === "/terms" || requestUrl.pathname === "/terms/") {
    return new URL("/uslovi-koriscenja", requestUrl.origin).toString();
  }
  return null;
}

export type MiddlewarePreviewMatch =
  | { kind: "classified" | "product"; id: string };

/**
 * Mapira kratke linkove i bot zahteve na odgovarajući preview endpoint,
 * uz podršku za opcioni trailing slash (`/.../`).
 */
export function matchMiddlewarePreviewRoute(
  pathname: string,
  botRequest: boolean,
): MiddlewarePreviewMatch | null {
  const adShortMatch = pathname.match(/^\/ad\/([^/]+)\/?$/);
  if (adShortMatch) {
    return { kind: "classified", id: decodeURIComponent(adShortMatch[1]) };
  }

  const prodShortMatch = pathname.match(/^\/p\/([^/]+)\/?$/);
  if (prodShortMatch) {
    return { kind: "product", id: decodeURIComponent(prodShortMatch[1]) };
  }

  if (botRequest) {
    const classifiedMatch = pathname.match(/^\/classifieds\/ad\/([^/]+)\/?$/);
    if (classifiedMatch) {
      return { kind: "classified", id: decodeURIComponent(classifiedMatch[1]) };
    }

    const productMatch = pathname.match(/^\/product\/([^/]+)\/?$/);
    if (productMatch) {
      return { kind: "product", id: decodeURIComponent(productMatch[1]) };
    }
  }

  return null;
}
