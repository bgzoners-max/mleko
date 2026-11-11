import {
  buildHtml,
  isBot,
  normalizeBaseUrl,
  normalizeImageUrl,
  resolvePublicBaseUrl,
  type HtmlLinkItem,
  type HtmlSection,
} from "./_shared/preview-utils.js";
import {
  createAnonSupabaseClient,
  type PublicSupabaseEnv,
} from "./_shared/directory-ssr.js";
import { buildNotFoundHtml } from "./_shared/static-seo-pages.js";

type SellerProfileRow = {
  id: string;
  display_name: string | null;
  farm_name: string | null;
  city: string | null;
  location: string | null;
  profile_image_url: string | null;
  seller_story: string | null;
  is_verified: boolean | null;
  role: string | null;
  seller_tags: string[] | null;
};

type SellerProductRow = {
  id: string;
  name: string;
  price_per_kg: number | null;
  image_urls: string[] | null;
  available_now: boolean | null;
};

type SellerAdRow = {
  id: string;
  title: string;
  price: number | null;
  currency: string | null;
  price_type: string | null;
  city: string | null;
};

function sanitizeSellerId(rawId: unknown): string {
  if (!rawId) return "";
  try {
    return decodeURIComponent(String(rawId)).trim();
  } catch {
    return String(rawId).trim();
  }
}

function buildSellerDescription(
  seller: SellerProfileRow,
  name: string,
  productCount: number,
  adCount: number,
): string {
  const place = seller.city?.trim() || seller.location?.trim() || "";
  const story = seller.seller_story?.trim() || "";
  const tags = Array.isArray(seller.seller_tags)
    ? seller.seller_tags.filter(Boolean).slice(0, 4)
    : [];

  const parts = [
    place ? `${name} (${place})` : name,
    seller.is_verified ? "Provereno poljoprivredno gazdinstvo na Domaćem Marketu" : "Domaći proizvođač na Domaćem Marketu",
    productCount > 0 ? `${productCount} proizvoda u ponudi` : null,
    adCount > 0 ? `${adCount} aktivnih malih oglasa` : null,
    tags.length > 0 ? `Specijalnost: ${tags.join(", ")}` : null,
    story.length > 10 ? story : null,
  ].filter((part): part is string => Boolean(part));

  const combined = parts.join(". ").replace(/\s+/g, " ").trim();
  return combined.length <= 220
    ? combined
    : `${combined.slice(0, 217).trimEnd()}...`;
}

export const onRequestGet: PagesFunction<PublicSupabaseEnv> = async (context) => {
  const { request, env, params } = context;
  const userAgent = request.headers.get("user-agent") || "";
  const url = new URL(request.url);
  const baseUrl = resolvePublicBaseUrl(normalizeBaseUrl(url.origin));

  if (!isBot(userAgent)) {
    return context.next();
  }

  const rawId =
    (typeof params?.id === "string" ? params.id : undefined) ||
    url.searchParams.get("id");
  const sellerId = sanitizeSellerId(rawId);

  if (!sellerId) {
    return new Response(buildNotFoundHtml(url.pathname, url.origin), {
      status: 404,
      headers: {
        "content-type": "text/html; charset=utf-8",
        "x-robots-tag": "noindex, nofollow",
      },
    });
  }

  const supabase = createAnonSupabaseClient(env);
  if (!supabase) {
    return context.next();
  }

  const { data: sellerData } = await supabase
    .from("public_profiles")
    .select(
      "id, display_name, farm_name, city, location, profile_image_url, seller_story, is_verified, role, seller_tags",
    )
    .eq("id", sellerId)
    .maybeSingle();

  const seller = sellerData as SellerProfileRow | null;
  if (!seller || seller.role !== "seller") {
    return new Response(buildNotFoundHtml(url.pathname, url.origin), {
      status: 404,
      headers: {
        "content-type": "text/html; charset=utf-8",
        "x-robots-tag": "noindex, nofollow",
      },
    });
  }

  const [productsRes, adsRes] = await Promise.all([
    supabase
      .from("products")
      .select("id, name, price_per_kg, image_urls, available_now")
      .eq("seller_id", seller.id)
      .order("created_at", { ascending: false })
      .limit(12),
    supabase
      .from("public_classified_ads")
      .select("id, title, price, currency, price_type, city")
      .eq("user_id", seller.id)
      .eq("status", "active")
      .order("created_at", { ascending: false })
      .limit(12),
  ]);

  const products = (productsRes.data || []) as SellerProductRow[];
  const ads = (adsRes.data || []) as SellerAdRow[];

  const sellerName =
    seller.farm_name?.trim() || seller.display_name?.trim() || "Domaće Gazdinstvo";
  const city = seller.city?.trim() || seller.location?.trim() || "";
  const canonicalUrl = `${baseUrl}/seller/${encodeURIComponent(seller.id)}`;
  const fallbackProductImg = products.find(
    (p) => Array.isArray(p.image_urls) && p.image_urls.length > 0,
  )?.image_urls?.[0];
  const imageUrl = normalizeImageUrl(
    seller.profile_image_url || fallbackProductImg,
    baseUrl,
  );

  const description = buildSellerDescription(
    seller,
    sellerName,
    products.length,
    ads.length,
  );

  const productLinks: HtmlLinkItem[] = products.map((p) => ({
    label: p.name,
    href: `${baseUrl}/product/${encodeURIComponent(p.id)}`,
    badge: p.available_now ? "Dostupno" : undefined,
    meta:
      p.price_per_kg != null
        ? `${Math.round(p.price_per_kg).toLocaleString("sr-RS")} RSD/kg`
        : undefined,
  }));

  const adLinks: HtmlLinkItem[] = ads.map((ad) => ({
    label: ad.title,
    href: `${baseUrl}/classifieds/ad/${encodeURIComponent(ad.id)}`,
    meta: ad.city?.trim() || undefined,
  }));

  const sections: HtmlSection[] = [];
  if (productLinks.length > 0) {
    sections.push({
      heading: `Domaći proizvodi gazdinstva ${sellerName}`,
      links: productLinks,
    });
  }
  if (adLinks.length > 0) {
    sections.push({
      heading: `Mali oglasi korisnika ${sellerName}`,
      links: adLinks,
    });
  }
  sections.push({
    heading: "Povezane stranice",
    links: [
      { label: "Sva gazdinstva na mapi", href: `${baseUrl}/sellers-map` },
      { label: "Pijaca domaće hrane", href: `${baseUrl}/categories` },
      { label: "Besplatni mali oglasi", href: `${baseUrl}/classifieds` },
    ],
  });

  const bodyParagraphs: string[] = [];
  if (city) {
    bodyParagraphs.push(`Lokacija gazdinstva: ${city}, Srbija.`);
  }
  if (seller.seller_story?.trim()) {
    bodyParagraphs.push(seller.seller_story.trim());
  } else {
    bodyParagraphs.push(description);
  }
  if (Array.isArray(seller.seller_tags) && seller.seller_tags.length > 0) {
    bodyParagraphs.push(`Kategorije i specijalnosti: ${seller.seller_tags.join(", ")}.`);
  }

  const profileJsonLd = {
    "@context": "https://schema.org",
    "@type": "ProfilePage",
    mainEntity: {
      "@type": "LocalBusiness",
      name: sellerName,
      url: canonicalUrl,
      image: imageUrl,
      description,
      ...(city
        ? {
            address: {
              "@type": "PostalAddress",
              addressLocality: city,
              addressCountry: "RS",
            },
          }
        : {}),
    },
  };

  const breadcrumbJsonLd = {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    itemListElement: [
      { "@type": "ListItem", position: 1, name: "Početna", item: `${baseUrl}/` },
      {
        "@type": "ListItem",
        position: 2,
        name: "Mapa gazdinstava",
        item: `${baseUrl}/sellers-map`,
      },
      { "@type": "ListItem", position: 3, name: sellerName, item: canonicalUrl },
    ],
  };

  const html = buildHtml({
    title: `${sellerName}${city ? ` (${city})` : ""} — Domaći Proizvođač | Domaći Market`,
    description,
    previewUrl: canonicalUrl,
    canonicalUrl,
    imageUrl,
    robots: "index,follow,max-image-preview:large",
    jsonLd: [profileJsonLd, breadcrumbJsonLd],
    ogType: "website",
    ogSiteName: "Domaći Market",
    bodyHeading: sellerName,
    bodyParagraphs,
    breadcrumbs: [
      { label: "Početna", href: `${baseUrl}/` },
      { label: "Mapa gazdinstava", href: `${baseUrl}/sellers-map` },
      { label: sellerName },
    ],
    navLinks: [
      { label: "Početna", href: `${baseUrl}/` },
      { label: "Pijaca hrane", href: `${baseUrl}/categories` },
      { label: "Mali oglasi", href: `${baseUrl}/classifieds` },
      { label: "Mapa gazdinstava", href: `${baseUrl}/sellers-map` },
    ],
    primaryCta: {
      label: "Pogledaj ceo profil proizvođača",
      href: canonicalUrl,
    },
    sections,
    omitRedirectFallback: true,
  });

  return new Response(html, {
    status: 200,
    headers: {
      "content-type": "text/html; charset=utf-8",
      "cache-control":
        "public, max-age=0, s-maxage=3600, stale-while-revalidate=86400",
    },
  });
};

