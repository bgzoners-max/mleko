export const runtime = "edge";
export const config = { runtime: "edge" };

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

    // Za stvarne posetioce u browseru (ne botove) odmah vraćamo HTTP 302 na kanonski URL
    const userAgent = request.headers.get("user-agent");
    if (!isBot(userAgent)) {
      return new Response(null, {
        status: 302,
        headers: {
          Location: canonicalUrl,
          "Cache-Control": "public, max-age=0, s-maxage=60",
        },
      });
    }

    const fallbackImageUrl = `${publicBaseUrl}/icons/Icon-512.png`;

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
        },
      });
    }

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const { data, error } = await supabase
      .from("classified_ads")
      .select(
        "id, title, description, price, currency, price_type, city, condition, status, images, category_id, classified_categories:category_id(name)",
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
    const imageUrl = normalizeImageUrl(rawImageUrl ?? null, publicBaseUrl);

    const availability = (ad?.status === "sold" || ad?.status === "archived")
      ? "https://schema.org/OutOfStock"
      : "https://schema.org/InStock";

    const nextYear = new Date().getFullYear() + 1;
    const priceValidUntil = `${nextYear}-12-31`;

    const categoryName = (Array.isArray(ad?.classified_categories)
      ? ad?.classified_categories[0]?.name
      : ad?.classified_categories?.name) || undefined;

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
          itemCondition: ad.condition === "new"
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

    const html = buildHtml({
      title,
      description,
      previewUrl,
      canonicalUrl,
      imageUrl,
      jsonLd,
      ogType: "website",
      ogSiteName: "Domaći Market — Mali Oglasi",
      bodyHeading: title,
      redirectNote: "Preusmeravanje na oglas...",
      linkLabel: "kliknite ovde za pregled oglasa",
    });

    return new Response(html, {
      status: ad ? 200 : 404,
      headers: {
        "content-type": "text/html; charset=utf-8",
        "cache-control": ad
          ? "public, max-age=0, s-maxage=60, stale-while-revalidate=300"
          : "no-cache, no-store, must-revalidate",
      },
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
        ogType: "website",
        ogSiteName: "Domaći Market — Mali Oglasi",
        bodyHeading: FALLBACK_TITLE,
        redirectNote: "Preusmeravanje na oglas...",
        linkLabel: "kliknite ovde za pregled oglasa",
      }),
      {
        status: 200,
        headers: { "content-type": "text/html; charset=utf-8" },
      },
    );
  }
}
