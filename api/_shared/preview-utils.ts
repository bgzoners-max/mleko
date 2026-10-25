// Shared SEO/HTML helpers for the Vercel preview Edge functions.
// Both `product-preview` and `classified-preview` use these utilities.

import { buildHreflangLinks } from "./locales.js";

declare const process: any;

export type HtmlPayload = {
  title: string;
  description: string;
  previewUrl: string;
  canonicalUrl: string;
  imageUrl: string;
  jsonLd?: Record<string, any>;
  /** Open Graph `og:type` value (defaults to 'product', use 'website' for classifieds). */
  ogType?: "product" | "website" | string;
  /** Open Graph `og:site_name` value. */
  ogSiteName?: string;
  /** Optional heading rendered above the redirect note (classified uses this). */
  bodyHeading?: string;
  /** Short sentence shown before the fallback link. */
  redirectNote?: string;
  /** Visible text of the fallback link. */
  linkLabel?: string;
};

export function normalizeBaseUrl(value: string): string {
  return value.trim().replace(/\/+$/, "");
}

const DEFAULT_CANONICAL_ORIGIN = "https://www.domacimarket.rs";

const WHITELISTED_ORIGINS = new Set([
  "https://www.domacimarket.rs",
  "https://staging.domacimarket.rs",
]);

/**
 * Određuje autoritativni javni bazni URL.
 *
 * 1. Ako je definisan `SHARE_BASE_URL` ili `STAGING_BASE_URL` u environment-u, uvek koristi njega.
 * 2. Ako je request origin na listi dozvoljenih (whitelisted) ili localhost za razvoj, koristi ga.
 * 3. Za sve ostale hostove (*.vercel.app preview deployment-i, nepoznati hostovi), vraća
 *    kanonski produkcijski domen kako bi se izbegao duplicate content i cache poisoning.
 */
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

/**
 * Proverava da li je User-Agent web scraper / socijalni bot ili crawler.
 */
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
  jsonLd,
  ogType = "product",
  ogSiteName = "Domaći Market",
  bodyHeading,
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

  const jsonLdScript = jsonLd
    ? `<script type="application/ld+json">${sanitizeJsonLd(jsonLd)}</script>`
    : "";

  return `<!DOCTYPE html>
<html lang="sr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${escapedTitle}</title>
  <meta name="description" content="${escapedDescription}">
  <meta name="robots" content="index,follow,max-image-preview:large">
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
  <div style="font-family: sans-serif; text-align: center; margin-top: 50px;">
    ${escapedBodyHeading ? `<h2>${escapedBodyHeading}</h2>` : ""}
    ${escapedBodyHeading ? `<p>${escapedDescription}</p>` : ""}
    <p>${escapedRedirectNote}</p>
    <p style="font-size: 0.9em; color: #666;">Ako se ništa ne dešava,
      <a href="${escapedCanonicalUrl}" style="color: #1B5E20; font-weight: bold;">${escapedLinkLabel}</a>.</p>
  </div>
</body>
</html>`;
}
