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

type ProductRow = {
  id: string;
  name: string;
  description: string | null;
  location: string | null;
  price_per_kg: number | null;
  unit_type: string | null;
  image_urls: string[] | null;
  available_now: boolean | null;
};

const FALLBACK_TITLE = "Domaće, baš kako treba! | domaćimarket.rs";
const FALLBACK_DESCRIPTION =
  "Domaće, baš kako treba! Povežite se sa proverenim proizvođačima i otkrijte lokalnu ponudu na domaćimarket.rs.";

function formatPrice(
  pricePerKg: number | null,
  unitType: string | null,
): string | null {
  if (pricePerKg == null) return null;
  const rounded = Math.round(pricePerKg);
  switch (unitType) {
    case "L":
      return `${rounded} RSD/L`;
    case "kom":
      return `${rounded} RSD/kom`;
    case "kg":
      return `${rounded} RSD/kg`;
    default:
      return `${rounded} RSD`;
  }
}

function buildDescription(product: ProductRow | null): string {
  if (product == null) return FALLBACK_DESCRIPTION;

  const location = product.location?.trim() || "";
  const description = product.description?.trim() || "";
  const priceInfo = formatPrice(product.price_per_kg, product.unit_type);

  const parts = [
    priceInfo,
    location ? `Lokacija: ${location}` : null,
    description.length > 10
      ? description
      : "Pogledajte detalje proizvoda i lokalnu ponudu na Domaćem marketu.",
  ].filter((part): part is string => Boolean(part));

  const text = parts.join(". ").replace(/\s+/g, " ").trim();
  if (text.length <= 220) return text;
  return `${text.slice(0, 217).trimEnd()}...`;
}

export async function GET(request: Request): Promise<Response> {
  try {
    const requestUrl = new URL(request.url);
    const productId = requestUrl.searchParams.get("id")?.trim();
    const origin = normalizeBaseUrl(requestUrl.origin);
    const publicBaseUrl = resolvePublicBaseUrl(origin);

    if (!productId) {
      return new Response("Missing product id.", { status: 400 });
    }

    const encodedProductId = encodeURIComponent(productId);
    const canonicalUrl = `${publicBaseUrl}/product/${encodedProductId}`;
    const previewUrl = `${publicBaseUrl}/p/${encodedProductId}`;

    // Za stvarne korisnike u browseru odmah vraćamo HTTP 302 na kanonski URL
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
        ogType: "product",
        redirectNote: "Preusmeravanje na proizvod...",
        linkLabel: "klikni ovde",
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
      .from("products")
      .select(
        "id, name, description, location, price_per_kg, unit_type, image_urls, available_now",
      )
      .eq("id", productId)
      .maybeSingle();

    const product = error ? null : (data as ProductRow | null);
    const title = product
      ? `${product.name} | Domaći market`
      : "Proizvod nije pronađen | Domaći market";
    const description = buildDescription(product);

    const rawImageUrl = product?.image_urls?.find((url) =>
      url && url.trim().length > 0
    );
    const imageUrl = normalizeImageUrl(rawImageUrl ?? null, publicBaseUrl);

    const availability = product?.available_now === false
      ? "https://schema.org/OutOfStock"
      : "https://schema.org/InStock";

    const jsonLd = product
      ? {
        "@context": "https://schema.org",
        "@type": "Product",
        name: product.name,
        description: product.description || description,
        image: product.image_urls && product.image_urls.length > 0
          ? product.image_urls
          : [imageUrl],
        offers: {
          "@type": "Offer",
          priceCurrency: "RSD",
          price: product.price_per_kg != null ? product.price_per_kg : 0,
          availability,
          url: canonicalUrl,
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
      ogType: "product",
      redirectNote: "Preusmeravanje na proizvod...",
      linkLabel: "klikni ovde",
    });

    return new Response(html, {
      status: product ? 200 : 404,
      headers: {
        "content-type": "text/html; charset=utf-8",
        "cache-control": product
          ? "public, max-age=0, s-maxage=60, stale-while-revalidate=300"
          : "no-cache, no-store, must-revalidate",
      },
    });
  } catch (err) {
    console.error("Edge Function Error:", err);
    const fallbackBaseUrl = resolvePublicBaseUrl();
    return new Response(
      buildHtml({
        title: FALLBACK_TITLE,
        description: FALLBACK_DESCRIPTION,
        previewUrl: request.url,
        canonicalUrl: request.url,
        imageUrl: `${fallbackBaseUrl}/icons/Icon-512.png`,
        ogType: "product",
        redirectNote: "Preusmeravanje na proizvod...",
        linkLabel: "klikni ovde",
      }),
      {
        status: 200,
        headers: { "content-type": "text/html; charset=utf-8" },
      },
    );
  }
}
