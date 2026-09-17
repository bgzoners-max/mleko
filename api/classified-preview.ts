export const runtime = "edge";

import { createClient } from "@supabase/supabase-js";

declare const process: any;

type ClassifiedRow = {
  id: string;
  title: string;
  description: string | null;
  price: number | null;
  currency: string | null;
  price_type: string | null;
  city: string | null;
  condition: string | null;
  images: string[] | null;
  category_id: string | null;
  classified_categories?: { name: string } | { name: string }[] | null;
};

type HtmlPayload = {
  title: string;
  description: string;
  previewUrl: string;
  canonicalUrl: string;
  imageUrl: string;
  jsonLd?: Record<string, any>;
};

const FALLBACK_TITLE = "Mali Oglasi | Besplatno oglašavanje | Domaći Market";
const FALLBACK_DESCRIPTION =
  "Besplatni mali oglasi u Srbiji. Kupujte i oglasite bez provizije na Domaćem Marketu: traktore, automobile, stoku, poljoprivredne mašine, alate, tehniku i nekretnine.";

function normalizeBaseUrl(value: string): string {
  return value.trim().replace(/\/+$/, "");
}

function resolvePublicBaseUrl(origin: string): string {
  return normalizeBaseUrl(origin);
}

function escapeHtml(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function normalizeImageUrl(
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

function formatPrice(
  price: number | null,
  currency: string | null,
  priceType: string | null,
): string {
  if (priceType === "free") return "Besplatno";
  if (priceType === "call") return "Cena na upit";

  const curr = currency || "RSD";
  const num = price != null ? Math.round(price).toLocaleString("sr-RS") : "0";

  if (priceType === "negotiable") {
    return `${num} ${curr} (Dogovor)`;
  }
  return `${num} ${curr}`;
}

function buildDescription(ad: ClassifiedRow | null): string {
  if (ad == null) return FALLBACK_DESCRIPTION;

  const city = ad.city?.trim() || "";
  const priceInfo = formatPrice(ad.price, ad.currency, ad.price_type);
  const rawDesc = ad.description?.trim() || "";
  let categoryName = "";
  if (ad.classified_categories) {
    if (Array.isArray(ad.classified_categories)) {
      categoryName = ad.classified_categories[0]?.name?.trim() || "";
    } else {
      categoryName = ad.classified_categories.name?.trim() || "";
    }
  }

  const parts = [
    priceInfo,
    city ? `Lokacija: ${city}` : null,
    categoryName ? `Kategorija: ${categoryName}` : null,
    rawDesc.length > 5
      ? rawDesc
      : "Pogledajte detalje malog oglasa na platformi Domaći Market bez posrednika i provizije.",
  ].filter((part): part is string => Boolean(part));

  const text = parts.join(". ").replace(/\s+/g, " ").trim();
  if (text.length <= 220) return text;
  return `${text.slice(0, 217).trimEnd()}...`;
}

function buildHtml({
  title,
  description,
  previewUrl,
  canonicalUrl,
  imageUrl,
  jsonLd,
}: HtmlPayload): string {
  const escapedTitle = escapeHtml(title);
  const escapedDescription = escapeHtml(description);
  const escapedPreviewUrl = escapeHtml(previewUrl);
  const escapedCanonicalUrl = escapeHtml(canonicalUrl);
  const escapedImageUrl = escapeHtml(imageUrl);
  const redirectTarget = canonicalUrl.replaceAll('"', "%22");

  const safeJson = jsonLd
    ? JSON.stringify(jsonLd)
        .replace(/</g, "\\u003c")
        .replace(/>/g, "\\u003e")
        .replace(/&/g, "\\u0026")
    : "";

  const jsonLdScript = safeJson
    ? `<script type="application/ld+json">${safeJson}</script>`
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

  <!-- Open Graph -->
  <meta property="og:type" content="product">
  <meta property="og:title" content="${escapedTitle}">
  <meta property="og:description" content="${escapedDescription}">
  <meta property="og:url" content="${escapedPreviewUrl}">
  <meta property="og:image" content="${escapedImageUrl}">
  <meta property="og:site_name" content="Domaći Market — Mali Oglasi">
  <meta property="og:locale" content="sr_RS">

  <!-- Twitter Card -->
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
    <h2>${escapedTitle}</h2>
    <p>${escapedDescription}</p>
    <p>Preusmeravanje na oglas...</p>
    <p style="font-size: 0.9em; color: #666;">Ako se ništa ne dešava,
      <a href="${escapedCanonicalUrl}" style="color: #1B5E20; font-weight: bold;">kliknite ovde za pregled oglasa</a>.</p>
  </div>
</body>
</html>`;
}

export async function GET(request: Request): Promise<Response> {
  try {
    const requestUrl = new URL(request.url);
    const adId = requestUrl.searchParams.get("id")?.trim();
    const origin = normalizeBaseUrl(requestUrl.origin);
    const publicBaseUrl = resolvePublicBaseUrl(origin);

    if (!adId) {
      return new Response("Missing classified ad id.", { status: 400 });
    }

    const encodedAdId = encodeURIComponent(adId);
    const canonicalUrl = `${publicBaseUrl}/classifieds/ad/${encodedAdId}`;
    const previewUrl = `${publicBaseUrl}/ad/${encodedAdId}`;
    const fallbackImageUrl = `${origin}/icons/Icon-512.png`;

    const supabaseUrl = typeof process !== "undefined"
      ? process.env.SUPABASE_URL
      : undefined;
    const supabaseAnonKey = typeof process !== "undefined"
      ? process.env.SUPABASE_ANON_KEY
      : undefined;

    if (!supabaseUrl || !supabaseAnonKey) {
      const html = buildHtml({
        title: FALLBACK_TITLE,
        description: FALLBACK_DESCRIPTION,
        previewUrl,
        canonicalUrl,
        imageUrl: fallbackImageUrl,
      });

      return new Response(html, {
        status: 200,
        headers: {
          "content-type": "text/html; charset=utf-8",
          "cache-control":
            "public, max-age=0, s-maxage=60, stale-while-revalidate=3600",
        },
      });
    }

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const { data, error } = await supabase
      .from("classified_ads")
      .select(
        "id, title, description, price, currency, price_type, city, condition, images, category_id, classified_categories:category_id(name)",
      )
      .eq("id", adId)
      .maybeSingle();

    const ad = error ? null : (data as unknown as ClassifiedRow | null);
    const priceFormatted = ad
      ? formatPrice(ad.price, ad.currency, ad.price_type)
      : "";

    const title = ad
      ? `${ad.title} | ${priceFormatted} | Mali Oglasi Domaći Market`
      : "Oglas nije pronađen | Domaći Market";
    const description = buildDescription(ad);

    const rawImageUrl = ad?.images?.find((url) => url && url.trim().length > 0);
    const imageUrl = normalizeImageUrl(rawImageUrl ?? null, origin);

    const jsonLd = ad
      ? {
        "@context": "https://schema.org",
        "@type": "Product",
        name: ad.title,
        description: ad.description || description,
        image: ad.images && ad.images.length > 0 ? ad.images : [imageUrl],
        category: (Array.isArray(ad.classified_categories) ? ad.classified_categories[0]?.name : ad.classified_categories?.name) || undefined,
        offers: {
          "@type": "Offer",
          priceCurrency: ad.currency || "RSD",
          price: ad.price != null ? ad.price : 0,
          availability: "https://schema.org/InStock",
          url: canonicalUrl,
          itemCondition: ad.condition === "new"
            ? "https://schema.org/NewCondition"
            : "https://schema.org/UsedCondition",
        },
      }
      : undefined;

    const html = buildHtml({
      title,
      description,
      previewUrl,
      canonicalUrl,
      imageUrl,
      jsonLd,
    });

    return new Response(html, {
      status: ad ? 200 : 404,
      headers: {
        "content-type": "text/html; charset=utf-8",
        "cache-control":
          "public, max-age=0, s-maxage=300, stale-while-revalidate=86400",
      },
    });
  } catch (err) {
    console.error("Classified Preview Edge Function Error:", err);
    return new Response(
      buildHtml({
        title: FALLBACK_TITLE,
        description: FALLBACK_DESCRIPTION,
        previewUrl: request.url,
        canonicalUrl: request.url,
        imageUrl: `${new URL(request.url).origin}/icons/Icon-512.png`,
      }),
      {
        status: 200,
        headers: { "content-type": "text/html; charset=utf-8" },
      },
    );
  }
}
