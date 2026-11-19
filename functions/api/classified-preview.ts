import { createClient } from "@supabase/supabase-js";
import {
  buildHtml,
  isBot,
  normalizeBaseUrl,
  normalizeImageUrl,
  resolvePublicBaseUrl,
} from "./_shared/preview-utils.js";

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
  status: string | null;
  images: string[] | null;
  category_id: string | null;
  classified_categories?: { name: string } | { name: string }[] | null;
};

const FALLBACK_TITLE = "Mali Oglasi | Besplatno oglašavanje | Domaći Market";
const FALLBACK_DESCRIPTION =
  "Besplatni mali oglasi u Srbiji. Kupujte i oglasite bez provizije na Domaćem Marketu: traktore, automobile, stoku, poljoprivredne mašine, alate, tehniku i nekretnine.";

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

function extractCategoryName(
  ad: ClassifiedRow | null | undefined,
): string | undefined {
  if (!ad?.classified_categories) return undefined;
  const raw = Array.isArray(ad.classified_categories)
    ? ad.classified_categories[0]?.name
    : ad.classified_categories.name;
  const trimmed = raw?.trim();
  return trimmed ? trimmed : undefined;
}

function buildDescription(ad: ClassifiedRow | null): string {
  if (ad == null) return FALLBACK_DESCRIPTION;

  const city = ad.city?.trim() || "";
  const priceInfo = formatPrice(ad.price, ad.currency, ad.price_type);
  const rawDesc = ad.description?.trim() || "";
  const categoryName = extractCategoryName(ad);

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

export async function handleClassifiedPreview(
  request: Request,
  env?: any,
): Promise<Response> {
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
    const previewUrl = canonicalUrl;

    const userAgent = request.headers.get("user-agent");
    if (!isBot(userAgent)) {
      const redirectTarget = new URL(canonicalUrl);
      for (const [k, v] of requestUrl.searchParams.entries()) {
        if (k !== "id" && k !== "v") {
          redirectTarget.searchParams.set(k, v);
        }
      }
      return new Response(null, {
        status: 302,
        headers: {
          Location: redirectTarget.toString(),
          "Cache-Control": "public, max-age=0, s-maxage=60",
          Vary: "User-Agent",
        },
      });
    }

    const fallbackImageUrl = `${publicBaseUrl}/icons/Icon-512.png`;

    const supabaseUrl =
      env?.SUPABASE_URL ||
      (typeof process !== "undefined" ? process.env?.SUPABASE_URL : undefined);
    const supabaseAnonKey =
      env?.SUPABASE_ANON_KEY ||
      (typeof process !== "undefined"
        ? process.env?.SUPABASE_ANON_KEY
        : undefined);

    if (!supabaseUrl || !supabaseAnonKey) {
      const html = buildHtml({
        title: FALLBACK_TITLE,
        description: FALLBACK_DESCRIPTION,
        previewUrl,
        canonicalUrl,
        imageUrl: fallbackImageUrl,
        ogType: "website",
        ogSiteName: "Domaći Market — Mali Oglasi",
        bodyHeading: FALLBACK_TITLE,
        redirectNote: "Preusmeravanje na oglas...",
        linkLabel: "kliknite ovde za pregled oglasa",
      });

      return new Response(html, {
        status: 200,
        headers: {
          "content-type": "text/html; charset=utf-8",
          "cache-control":
            "public, max-age=0, s-maxage=60, stale-while-revalidate=3600",
          vary: "User-Agent",
        },
      });
    }

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const { data, error } = await supabase
      .from("public_classified_ads")
      .select(
        "id, title, description, price, currency, price_type, city, condition, status, images, category_id, classified_categories:category_id(name)",
      )
      .eq("id", adId)
      .maybeSingle();

    const rawAd = error ? null : (data as unknown as ClassifiedRow | null);
    const ad =
      rawAd && (!rawAd.status || rawAd.status === "active" || rawAd.status === "sold")
        ? rawAd
        : null;
    const priceFormatted = ad
      ? formatPrice(ad.price, ad.currency, ad.price_type)
      : "";

    const title = ad
      ? `${ad.title} | ${priceFormatted} | Mali Oglasi Domaći Market`
      : "Oglas nije pronađen | Domaći Market";
    const description = buildDescription(ad);

    const rawImageUrl = ad?.images?.find(
      (url) => url && url.trim().length > 0,
    );
    const imageUrl = normalizeImageUrl(rawImageUrl ?? null, publicBaseUrl);

    const availability =
      ad?.status === "sold" || ad?.status === "archived"
        ? "https://schema.org/OutOfStock"
        : "https://schema.org/InStock";

    const nextYear = new Date().getFullYear() + 1;
    const priceValidUntil = `${nextYear}-12-31`;

    const categoryName = extractCategoryName(ad);

    const jsonLd = ad
      ? {
          "@context": "https://schema.org",
          "@type": "Product",
          name: ad.title,
          description: ad.description || description,
          sku: ad.id,
          productID: ad.id,
          image: ad.images && ad.images.length > 0 ? ad.images : [imageUrl],
          brand: {
            "@type": "Brand",
            name: "Domaći Market",
          },
          category: categoryName,
          offers: {
            "@type": "Offer",
            priceCurrency: ad.currency || "RSD",
            price: ad.price != null ? ad.price : 0,
            availability,
            itemCondition:
              ad.condition === "new"
                ? "https://schema.org/NewCondition"
                : "https://schema.org/UsedCondition",
            priceValidUntil,
            url: canonicalUrl,
            seller: {
              "@type": "Person",
              name: ad.city ? `Oglašivač (${ad.city})` : "Domaći Market oglašivač",
            },
          },
        }
      : undefined;

    const bodyParagraphs: string[] = [];
    if (ad) {
      const infoParts = [
        priceFormatted,
        ad.city ? `Lokacija: ${ad.city}` : "",
        categoryName ? `Kategorija: ${categoryName}` : "",
        ad.condition ? `Stanje: ${ad.condition}` : "",
      ]
        .filter(Boolean)
        .join(" • ");
      if (infoParts) bodyParagraphs.push(infoParts);

      if (ad.description && ad.description.trim().length > 0) {
        bodyParagraphs.push(ad.description.trim());
      }
      bodyParagraphs.push(
        "Domaći Market — besplatni mali oglasi u Srbiji bez provizije.",
      );
    } else {
      bodyParagraphs.push(description);
    }

    const html = buildHtml({
      title,
      description,
      previewUrl,
      canonicalUrl,
      imageUrl,
      robots: ad ? "index,follow,max-image-preview:large" : "noindex,nofollow",
      jsonLd,
      ogType: "website",
      ogSiteName: "Domaći Market — Mali Oglasi",
      bodyHeading: ad ? ad.title : "Oglas nije pronađen",
      bodyParagraphs,
      redirectNote: "Preusmeravanje na oglas...",
      linkLabel: "kliknite ovde za pregled oglasa",
    });

    const responseHeaders: Record<string, string> = {
      "content-type": "text/html; charset=utf-8",
      "cache-control": ad
        ? "public, max-age=0, s-maxage=60, stale-while-revalidate=300"
        : "no-cache, no-store, must-revalidate",
      vary: "User-Agent",
    };
    if (!ad) {
      responseHeaders["x-robots-tag"] = "noindex, nofollow";
    }

    return new Response(html, {
      status: ad ? 200 : 404,
      headers: responseHeaders,
    });
  } catch (err) {
    console.error("Classified Preview Edge Function Error:", err);
    const fallbackBaseUrl = resolvePublicBaseUrl();
    return new Response(
      buildHtml({
        title: FALLBACK_TITLE,
        description: FALLBACK_DESCRIPTION,
        previewUrl: request.url,
        canonicalUrl: request.url,
        imageUrl: `${fallbackBaseUrl}/icons/Icon-512.png`,
        robots: "noindex,nofollow",
        ogType: "website",
        ogSiteName: "Domaći Market — Mali Oglasi",
        bodyHeading: FALLBACK_TITLE,
        redirectNote: "Preusmeravanje na oglas...",
        linkLabel: "kliknite ovde za pregled oglasa",
      }),
      {
        status: 503,
        headers: {
          "content-type": "text/html; charset=utf-8",
          "cache-control": "no-store, max-age=0",
          "x-robots-tag": "noindex, nofollow",
        },
      },
    );
  }
}

export const onRequestGet: PagesFunction = async (context) => {
  return handleClassifiedPreview(context.request, context.env);
};

export async function GET(request: Request): Promise<Response> {
  return handleClassifiedPreview(request);
}
