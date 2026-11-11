import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import {
  normalizeBaseUrl,
  normalizeImageUrl,
  resolvePublicBaseUrl,
  type HtmlLinkItem,
  type HtmlPayload,
  type HtmlSection,
} from "./preview-utils.js";

const PATH_CLASSIFIEDS = "/classifieds";
const PATH_CATEGORIES = "/categories";

declare const process: any;

export type PublicSupabaseEnv = {
  SUPABASE_URL?: string;
  SUPABASE_ANON_KEY?: string;
};

type ClassifiedCategoryRow = {
  id: string;
  name: string;
  parent_id: string | null;
  sort_order?: number | null;
  is_obsolete?: boolean | null;
};

type ClassifiedAdSummaryRow = {
  id: string;
  title: string;
  price: number | null;
  currency: string | null;
  price_type: string | null;
  city: string | null;
  images: string[] | null;
};

type FoodCategoryRow = {
  id: string;
  name: string;
  slug: string | null;
  parent_id: string | null;
};

type ProductSummaryRow = {
  id: string;
  name: string;
  category: string | null;
  price_per_kg: number | null;
  location: string | null;
  image_urls: string[] | null;
  available_now?: boolean | null;
};

type SellerSummaryRow = {
  id: string;
  farm_name: string | null;
  display_name: string | null;
  city: string | null;
  location: string | null;
  profile_image_url: string | null;
  is_verified: boolean | null;
};

export function createAnonSupabaseClient(
  env?: PublicSupabaseEnv,
): SupabaseClient | null {
  const supabaseUrl =
    env?.SUPABASE_URL ||
    (typeof process !== "undefined"
      ? process.env?.SUPABASE_URL || process.env?.NEXT_PUBLIC_SUPABASE_URL
      : undefined);
  const supabaseAnonKey =
    env?.SUPABASE_ANON_KEY ||
    (typeof process !== "undefined"
      ? process.env?.SUPABASE_ANON_KEY ||
        process.env?.NEXT_PUBLIC_SUPABASE_ANON_KEY
      : undefined);

  if (!supabaseUrl || !supabaseAnonKey) {
    return null;
  }

  return createClient(supabaseUrl, supabaseAnonKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
}

function formatClassifiedPrice(
  price: number | null,
  currency: string | null,
  priceType: string | null,
): string {
  if (priceType === "free") return "Besplatno";
  if (priceType === "call") return "Cena na upit";
  const curr = currency || "RSD";
  const num = price != null ? Math.round(price).toLocaleString("sr-RS") : "0";
  return priceType === "negotiable" ? `${num} ${curr} (Dogovor)` : `${num} ${curr}`;
}

function collectDescendantIds(
  rootId: string,
  rows: ClassifiedCategoryRow[],
): string[] {
  const result = new Set<string>([rootId]);
  let changed = true;
  while (changed) {
    changed = false;
    for (const row of rows) {
      if (row.parent_id && result.has(row.parent_id) && !result.has(row.id)) {
        result.add(row.id);
        changed = true;
      }
    }
  }
  return Array.from(result);
}

function appendItemListJsonLd(
  payload: HtmlPayload,
  name: string,
  links: HtmlLinkItem[],
): Record<string, any> | Array<Record<string, any>> | undefined {
  if (links.length === 0) return payload.jsonLd;
  const itemList = {
    "@context": "https://schema.org",
    "@type": "ItemList",
    name,
    numberOfItems: links.length,
    itemListElement: links.map((item, idx) => ({
      "@type": "ListItem",
      position: idx + 1,
      name: item.label,
      url: item.href,
    })),
  };

  if (Array.isArray(payload.jsonLd)) {
    return [...payload.jsonLd, itemList];
  }
  return payload.jsonLd ? [payload.jsonLd, itemList] : itemList;
}

async function withTimeout<T>(
  promise: Promise<T>,
  ms: number,
  fallback: T,
): Promise<T> {
  let timer: ReturnType<typeof setTimeout> | undefined;
  try {
    return await Promise.race([
      promise,
      new Promise<T>((resolve) => {
        timer = setTimeout(() => resolve(fallback), ms);
      }),
    ]);
  } finally {
    if (timer) clearTimeout(timer);
  }
}

async function enrichClassifiedsPayload(
  supabase: SupabaseClient,
  baseUrl: string,
  categorySlug: string,
  payload: HtmlPayload,
): Promise<HtmlPayload> {
  const { data: catRowsRaw } = await supabase
    .from("classified_categories")
    .select("id, name, parent_id, sort_order, is_obsolete")
    .order("sort_order", { ascending: true });

  const activeCategories = ((catRowsRaw || []) as ClassifiedCategoryRow[]).filter(
    (c) => c.is_obsolete !== true,
  );

  let adsQuery = supabase
    .from("public_classified_ads")
    .select("id, title, price, currency, price_type, city, images")
    .eq("status", "active")
    .order("created_at", { ascending: false })
    .limit(12);

  let subcategoryNames: string[] = [];
  if (categorySlug) {
    const targetIds = collectDescendantIds(categorySlug, activeCategories);
    adsQuery = adsQuery.in("category_id", targetIds);
    subcategoryNames = activeCategories
      .filter((c) => c.parent_id === categorySlug)
      .map((c) => c.name);
  }

  const { data: adRowsRaw } = await adsQuery;
  const ads = (adRowsRaw || []) as ClassifiedAdSummaryRow[];

  const adLinks: HtmlLinkItem[] = ads.map((ad) => {
    const metaParts = [
      formatClassifiedPrice(ad.price, ad.currency, ad.price_type),
      ad.city?.trim() || null,
    ].filter(Boolean);
    return {
      label: ad.title,
      href: `${baseUrl}/classifieds/ad/${encodeURIComponent(ad.id)}`,
      meta: metaParts.join(" — "),
    };
  });

  const extraParagraphs = [...(payload.bodyParagraphs || [])];
  if (subcategoryNames.length > 0) {
    extraParagraphs.push(`Podkategorije: ${subcategoryNames.join(", ")}.`);
  }

  const dynamicSections: HtmlSection[] = [];
  if (adLinks.length > 0) {
    dynamicSections.push({
      heading: categorySlug
        ? `Aktuelni mali oglasi — ${payload.bodyHeading || categorySlug}`
        : "Najnoviji mali oglasi u Srbiji",
      links: adLinks,
    });
  } else if (categorySlug) {
    extraParagraphs.push(
      "Trenutno nema aktivnih oglasa u ovoj kategoriji. Budite prvi i postavite besplatan oglas bez provizije za manje od minut.",
    );
    const { data: fallbackAdsRaw } = await supabase
      .from("public_classified_ads")
      .select("id, title, price, currency, price_type, city, images")
      .eq("status", "active")
      .order("created_at", { ascending: false })
      .limit(6);

    const fallbackLinks: HtmlLinkItem[] = (
      (fallbackAdsRaw || []) as ClassifiedAdSummaryRow[]
    ).map((ad) => ({
      label: ad.title,
      href: `${baseUrl}/classifieds/ad/${encodeURIComponent(ad.id)}`,
      meta: [
        formatClassifiedPrice(ad.price, ad.currency, ad.price_type),
        ad.city?.trim() || null,
      ]
        .filter(Boolean)
        .join(" — "),
    }));

    if (fallbackLinks.length > 0) {
      dynamicSections.push({
        heading: "Ostali aktuelni mali oglasi na Domaćem Marketu",
        links: fallbackLinks,
      });
    }
  }

  const firstImage = ads.find(
    (ad) => Array.isArray(ad.images) && ad.images.length > 0,
  )?.images?.[0];

  return {
    ...payload,
    imageUrl: firstImage
      ? normalizeImageUrl(firstImage, baseUrl)
      : payload.imageUrl,
    bodyParagraphs: extraParagraphs,
    sections: [...dynamicSections, ...(payload.sections || [])],
    jsonLd: appendItemListJsonLd(
      payload,
      payload.bodyHeading || "Mali oglasi",
      adLinks,
    ),
  };
}

async function enrichProductsPayload(
  supabase: SupabaseClient,
  baseUrl: string,
  path: string,
  categorySlug: string,
  payload: HtmlPayload,
): Promise<HtmlPayload> {
  const { data: foodCatsRaw } = await supabase
    .from("categories")
    .select("id, name, slug, parent_id")
    .order("order", { ascending: true });

  const allCats = (foodCatsRaw || []) as FoodCategoryRow[];
  let childNames: string[] = [];
  let productsQuery = supabase
    .from("products")
    .select("id, name, category, price_per_kg, location, image_urls, available_now")
    .order("created_at", { ascending: false })
    .limit(12);

  if (path === PATH_CATEGORIES && categorySlug) {
    const parentCat =
      allCats.find((c) => c.slug === categorySlug && !c.parent_id) ||
      allCats.find((c) => c.slug === categorySlug);

    if (parentCat) {
      const children = allCats.filter((c) => c.parent_id === parentCat.id);
      childNames = children.map((c) => c.name);
      const filterNames = [parentCat.name, ...childNames];
      productsQuery = productsQuery.in("category", filterNames);
    }
  } else {
    productsQuery = productsQuery.eq("available_now", true);
  }

  const { data: productsRaw } = await productsQuery;
  const products = (productsRaw || []) as ProductSummaryRow[];

  const productLinks: HtmlLinkItem[] = products.map((p) => {
    const pricePart =
      p.price_per_kg != null
        ? `${Math.round(p.price_per_kg).toLocaleString("sr-RS")} RSD`
        : null;
    const meta = [pricePart, p.location?.trim() || null, p.category?.trim() || null]
      .filter(Boolean)
      .join(" — ");
    return {
      label: p.name,
      href: `${baseUrl}/product/${encodeURIComponent(p.id)}`,
      meta,
    };
  });

  const extraParagraphs = [...(payload.bodyParagraphs || [])];
  if (childNames.length > 0) {
    extraParagraphs.push(`Podkategorije: ${childNames.join(", ")}.`);
  }

  const dynamicSections: HtmlSection[] = [];
  if (productLinks.length > 0) {
    dynamicSections.push({
      heading:
        categorySlug && path === PATH_CATEGORIES
          ? `Ponuda domaćih proizvoda — ${payload.bodyHeading || categorySlug}`
          : "Sveži domaći proizvodi direktno sa gazdinstava",
      links: productLinks,
    });
  } else if (categorySlug && path === PATH_CATEGORIES) {
    extraParagraphs.push(
      "Trenutno nema aktivnih proizvoda u ovoj kategoriji. Pogledajte ostale kategorije domaće hrane ili se registrujte kao proizvođač.",
    );
  }

  const firstImage = products.find(
    (p) => Array.isArray(p.image_urls) && p.image_urls.length > 0,
  )?.image_urls?.[0];

  return {
    ...payload,
    imageUrl: firstImage
      ? normalizeImageUrl(firstImage, baseUrl)
      : payload.imageUrl,
    bodyParagraphs: extraParagraphs,
    sections: [...dynamicSections, ...(payload.sections || [])],
    jsonLd: appendItemListJsonLd(
      payload,
      payload.bodyHeading || "Domaći proizvodi",
      productLinks,
    ),
  };
}

async function enrichSellersMapPayload(
  supabase: SupabaseClient,
  baseUrl: string,
  payload: HtmlPayload,
): Promise<HtmlPayload> {
  const { data: sellersRaw } = await supabase
    .from("public_profiles")
    .select("id, farm_name, display_name, city, location, profile_image_url, is_verified")
    .eq("role", "seller")
    .order("created_at", { ascending: false })
    .limit(16);

  const sellers = (sellersRaw || []) as SellerSummaryRow[];
  const sellerLinks: HtmlLinkItem[] = sellers.map((s) => {
    const title = s.farm_name?.trim() || s.display_name?.trim() || "Domaće gazdinstvo";
    const place = s.city?.trim() || s.location?.trim() || "";
    return {
      label: title,
      href: `${baseUrl}/seller/${encodeURIComponent(s.id)}`,
      badge: s.is_verified ? "Provereno gazdinstvo" : undefined,
      meta: place || undefined,
    };
  });

  if (sellerLinks.length === 0) return payload;

  return {
    ...payload,
    sections: [
      {
        heading: "Registrovana seoska gazdinstva u Srbiji",
        links: sellerLinks,
      },
      ...(payload.sections || []),
    ],
    jsonLd: appendItemListJsonLd(
      payload,
      "Registrovana seoska gazdinstva",
      sellerLinks,
    ),
  };
}

export async function enrichDirectorySeoPayload(options: {
  pathname: string;
  searchParams: URLSearchParams;
  origin?: string;
  env?: PublicSupabaseEnv;
  basePayload: HtmlPayload;
}): Promise<HtmlPayload> {
  const { pathname, searchParams, origin, env, basePayload } = options;
  const normalizedPath = pathname === "/" ? "/" : pathname.replace(/\/+$/, "");

  // Ne obogaćuj stranice pretrage sa ?q= niti nepoznate parametre
  if (basePayload.robots?.startsWith("noindex")) {
    return basePayload;
  }

  const supabase = createAnonSupabaseClient(env);
  if (!supabase) {
    return basePayload;
  }

  const baseUrl = resolvePublicBaseUrl(
    origin ? normalizeBaseUrl(origin) : undefined,
  );
  const categorySlug = searchParams.get("category")?.trim() ?? "";

  try {
    if (normalizedPath === PATH_CLASSIFIEDS) {
      return await withTimeout(
        enrichClassifiedsPayload(supabase, baseUrl, categorySlug, basePayload),
        2500,
        basePayload,
      );
    }

    if (
      normalizedPath === PATH_CATEGORIES ||
      normalizedPath === "/search"
    ) {
      return await withTimeout(
        enrichProductsPayload(
          supabase,
          baseUrl,
          normalizedPath,
          categorySlug,
          basePayload,
        ),
        2500,
        basePayload,
      );
    }

    if (normalizedPath === "/sellers-map") {
      return await withTimeout(
        enrichSellersMapPayload(supabase, baseUrl, basePayload),
        2500,
        basePayload,
      );
    }
  } catch (err) {
    console.warn("[directory-ssr] enrichment fallback:", err);
  }

  return basePayload;
}
