// Shared SEO/HTML helpers for the Vercel preview Edge functions.
// Both `product-preview` and `classified-preview` used to duplicate these
// ~120 lines; keeping them here so escaping/CSP/OG changes happen once.

export type HtmlPayload = {
  title: string;
  description: string;
  previewUrl: string;
  canonicalUrl: string;
  imageUrl: string;
  jsonLd?: Record<string, any>;
  /** Open Graph `og:site_name` value. */
  ogSiteName?: string;
  /** Optional heading rendered above the redirect note (classified uses this). */
  bodyHeading?: string;
  /** Short sentence shown before the fallback link. */
  redirectNote: string;
  /** Visible text of the fallback link. */
  linkLabel: string;
};

export function normalizeBaseUrl(value: string): string {
  return value.trim().replace(/\/+$/, "");
}

export function resolvePublicBaseUrl(origin: string): string {
  return normalizeBaseUrl(origin);
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
  origin: string,
): string {
  const fallback = `${origin}/icons/Icon-512.png`;
  if (!imageUrl || typeof imageUrl !== "string") return fallback;

  if (imageUrl.startsWith("http://") || imageUrl.startsWith("https://")) {
    return imageUrl;
  }

  const cleanOrigin = origin.replace(/\/+$/, "");
  if (imageUrl.startsWith("/")) {
    return `${cleanOrigin}${imageUrl}`;
  }
  return `${cleanOrigin}/${imageUrl}`;
}

function sanitizeJsonLd(jsonLd: Record<string, any>): string {
  return JSON.stringify(jsonLd)
    .replace(/</g, "\\u003c")
    .replace(/>/g, "\\u003e")
    .replace(/&/g, "\\u0026");
}

export function buildHtml({
  title,
  description,
  previewUrl,
  canonicalUrl,
  imageUrl,
  jsonLd,
  ogSiteName = "Domaći Market",
  bodyHeading,
  redirectNote,
  linkLabel,
}: HtmlPayload): string {
  const escapedTitle = escapeHtml(title);
  const escapedDescription = escapeHtml(description);
  const escapedPreviewUrl = escapeHtml(previewUrl);
  const escapedCanonicalUrl = escapeHtml(canonicalUrl);
  const escapedImageUrl = escapeHtml(imageUrl);
  const escapedOgSiteName = escapeHtml(ogSiteName);
  const escapedRedirectNote = escapeHtml(redirectNote);
  const escapedLinkLabel = escapeHtml(linkLabel);
  const escapedBodyHeading = bodyHeading ? escapeHtml(bodyHeading) : "";
  const redirectTarget = canonicalUrl.replaceAll('"', "%22");

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

  <meta property="og:type" content="product">
  <meta property="og:title" content="${escapedTitle}">
  <meta property="og:description" content="${escapedDescription}">
  <meta property="og:url" content="${escapedPreviewUrl}">
  <meta property="og:image" content="${escapedImageUrl}">
  <meta property="og:site_name" content="${escapedOgSiteName}">
  <meta property="og:locale" content="sr_RS">

  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="${escapedTitle}">
  <meta name="twitter:description" content="${escapedDescription}">
  <meta name="twitter:image" content="${escapedImageUrl}">

  ${jsonLdScript}

  <meta http-equiv="refresh" content="0;url=${escapedCanonicalUrl}">
  <script>
    window.location.replace("${redirectTarget}");
  </script>
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
