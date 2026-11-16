import { createClient } from "@supabase/supabase-js";
import { normalizeBaseUrl, resolvePublicBaseUrl } from "./_shared/preview-utils.js";
import { buildHreflangXmlLinks } from "./_shared/locales.js";
import {
  collectDescendantIds,
  type ClassifiedCategoryRow,
  type FoodCategoryRow,
} from "./_shared/directory-ssr.js";

declare const process: any;

export type SitemapEntry = {
  loc: string;
  lastmod?: string;
  changefreq?: "always" | "hourly" | "daily" | "weekly" | "monthly" | "yearly" | "never";
  priority?: string;
};

type SitemapAdRow = {
  id: string;
  category_id?: string | null;
  updated_at?: string | null;
  created_at?: string | null;
};

type SitemapProductRow = {
  id: string;
  category?: string | null;
  created_at?: string | null;
  available_now?: boolean | null;
};

export const CLASSIFIED_CATEGORIES = [
  "poljoprivreda",
  "vozila",
  "masine_alati",
  "dom_basta",
  "telefoni",
  "tehnika",
  "nekretnine",
  "gradjevinarstvo",
  "odeca_obuca",
  "deca_bebe",
  "sport_hobi",
  "ljubimci",
  "usluge",
  "zdravlje_lepota",
  "knjige_edukacija",
  "umetnost_rukotvorine",
];

export const FOOD_CATEGORIES = [
  "mlecni-proizvodi",
  "meso",
  "voce-i-povrce",
  "med-i-pcelinji-proizvodi",
  "slana-zimnica",
  "slatka-zimnica-i-dzemovi",
  "jaja",
  "vina-i-domace-rakije",
  "sokovi-i-domaci-sirupi",
  "brasno-testenine-i-zitarice",
  "hladno-cedjena-ulja-i-sirceta",
  "cajevi-zacini-i-lekovito-bilje",
  "orasasti-plodovi-semenke-i-suvo-voce",
  "gljive-i-tartufi",
];

function formatDate(dateValue?: string | null): string {
  if (!dateValue) {
    return new Date().toISOString().split("T")[0];
  }
  try {
    const d = new Date(dateValue);
    if (isNaN(d.getTime())) {
      return new Date().toISOString().split("T")[0];
    }
    return d.toISOString().split("T")[0];
  } catch {
    return new Date().toISOString().split("T")[0];
  }
}

function maxIsoDate(dates: Array<string | null | undefined>): string | undefined {
  let latest: string | undefined;
  for (const raw of dates) {
    if (!raw) continue;
    const formatted = formatDate(raw);
    if (!latest || formatted > latest) {
      latest = formatted;
    }
  }
  return latest;
}

export function buildPopulatedClassifiedCategoryEntries(params: {
  baseUrl: string;
  slugs?: string[];
  categories: ClassifiedCategoryRow[];
  ads: SitemapAdRow[];
}): SitemapEntry[] {
  const {
    baseUrl,
    slugs = CLASSIFIED_CATEGORIES,
    categories,
    ads,
  } = params;
  const activeCategories = categories.filter((c) => c.is_obsolete !== true);
  const entries: SitemapEntry[] = [];

  for (const slug of slugs) {
    const descendants = new Set(collectDescendantIds(slug, activeCategories));
    const matchingAds = ads.filter(
      (ad) => ad.category_id != null && descendants.has(ad.category_id),
    );
    if (matchingAds.length === 0) continue;

    entries.push({
      loc: `${baseUrl}/classifieds?category=${slug}`,
      lastmod: maxIsoDate(
        matchingAds.map((ad) => ad.updated_at || ad.created_at),
      ),
      changefreq: "daily",
      priority: "0.85",
    });
  }

  return entries;
}

export function buildPopulatedFoodCategoryEntries(params: {
  baseUrl: string;
  slugs?: string[];
  categories: FoodCategoryRow[];
  products: SitemapProductRow[];
}): SitemapEntry[] {
  const {
    baseUrl,
    slugs = FOOD_CATEGORIES,
    categories,
    products,
  } = params;
  const entries: SitemapEntry[] = [];

  for (const slug of slugs) {
    const parentCat =
      categories.find((c) => c.slug === slug && !c.parent_id) ||
      categories.find((c) => c.slug === slug);
    if (!parentCat) continue;

    const childNames = categories
      .filter((c) => c.parent_id === parentCat.id)
      .map((c) => c.name);
    const targetNames = new Set([parentCat.name, ...childNames]);

    const matchingProducts = products.filter(
      (p) => p.category != null && targetNames.has(p.category),
    );
    if (matchingProducts.length === 0) continue;

    entries.push({
      loc: `${baseUrl}/categories?category=${slug}`,
      lastmod: maxIsoDate(matchingProducts.map((p) => p.created_at)),
      changefreq: "daily",
      priority: "0.85",
    });
  }

  return entries;
}

function buildCoreEntries(
  baseUrl: string,
  dates?: {
    home?: string;
    classifieds?: string;
    categories?: string;
    search?: string;
    sellersMap?: string;
  },
): SitemapEntry[] {
  return [
    { loc: `${baseUrl}/`, lastmod: dates?.home, changefreq: "daily", priority: "1.0" },
    { loc: `${baseUrl}/classifieds`, lastmod: dates?.classifieds, changefreq: "daily", priority: "0.95" },
    { loc: `${baseUrl}/categories`, lastmod: dates?.categories, changefreq: "daily", priority: "0.90" },
    { loc: `${baseUrl}/search`, lastmod: dates?.search, changefreq: "daily", priority: "0.80" },
    { loc: `${baseUrl}/sellers-map`, lastmod: dates?.sellersMap, changefreq: "weekly", priority: "0.80" },
    { loc: `${baseUrl}/vodic-za-proizvodjace`, changefreq: "monthly", priority: "0.70" },
    { loc: `${baseUrl}/about`, changefreq: "monthly", priority: "0.60" },
    { loc: `${baseUrl}/support`, changefreq: "monthly", priority: "0.50" },
    { loc: `${baseUrl}/uslovi-koriscenja`, changefreq: "yearly", priority: "0.40" },
    { loc: `${baseUrl}/politika-privatnosti`, changefreq: "yearly", priority: "0.40" },
  ];
}

function buildAllCategoryFallbackEntries(baseUrl: string, today: string): SitemapEntry[] {
  return [
    ...CLASSIFIED_CATEGORIES.map((cat): SitemapEntry => ({
      loc: `${baseUrl}/classifieds?category=${cat}`,
      lastmod: today,
      changefreq: "daily",
      priority: "0.85",
    })),
    ...FOOD_CATEGORIES.map((cat): SitemapEntry => ({
      loc: `${baseUrl}/categories?category=${cat}`,
      lastmod: today,
      changefreq: "daily",
      priority: "0.85",
    })),
  ];
}

function buildXml(entries: SitemapEntry[], baseUrl: string): string {
  const urlsXml = entries
    .map((e) => {
      const parts = [`    <loc>${e.loc}</loc>`];
      const hreflangXml = buildHreflangXmlLinks(e.loc, baseUrl);
      if (hreflangXml) parts.push(hreflangXml);
      if (e.lastmod) parts.push(`    <lastmod>${e.lastmod}</lastmod>`);
      if (e.changefreq) parts.push(`    <changefreq>${e.changefreq}</changefreq>`);
      if (e.priority) parts.push(`    <priority>${e.priority}</priority>`);
      return `  <url>\n${parts.join("\n")}\n  </url>`;
    })
    .join("\n");

  return `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
        xmlns:xhtml="http://www.w3.org/1999/xhtml">
${urlsXml}
</urlset>`;
}

export async function handleSitemap(request: Request, env?: any): Promise<Response> {
  const requestUrl = new URL(request.url);
  const origin = normalizeBaseUrl(requestUrl.origin);
  const baseUrl = resolvePublicBaseUrl(origin);
  const today = formatDate();

  const fallbackEntries: SitemapEntry[] = [
    ...buildCoreEntries(baseUrl, {
      home: today,
      classifieds: today,
      categories: today,
      search: today,
      sellersMap: today,
    }),
    ...buildAllCategoryFallbackEntries(baseUrl, today),
  ];

  try {
    const supabaseUrl =
      env?.SUPABASE_URL ||
      (typeof process !== "undefined"
        ? process.env?.SUPABASE_URL || process.env?.NEXT_PUBLIC_SUPABASE_URL
        : undefined);
    const supabaseAnonKey =
      env?.SUPABASE_ANON_KEY ||
      (typeof process !== "undefined"
        ? process.env?.SUPABASE_ANON_KEY || process.env?.NEXT_PUBLIC_SUPABASE_ANON_KEY
        : undefined);

    if (!supabaseUrl || !supabaseAnonKey) {
      return new Response(buildXml(fallbackEntries, baseUrl), {
        status: 200,
        headers: {
          "Content-Type": "application/xml; charset=utf-8",
          "Cache-Control": "public, max-age=3600, s-maxage=3600, stale-while-revalidate=86400",
        },
      });
    }

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const [adsRes, productsRes, sellersRes, classifiedCatsRes, foodCatsRes] =
      await Promise.all([
        supabase
          .from("classified_ads")
          .select("id, category_id, updated_at, created_at")
          .eq("status", "active")
          .order("created_at", { ascending: false })
          .limit(3000),
        supabase
          .from("products")
          .select("id, category, created_at, available_now")
          .order("created_at", { ascending: false })
          .limit(3000),
        supabase
          .from("public_profiles")
          .select("id, created_at")
          .eq("role", "seller")
          .order("created_at", { ascending: false })
          .limit(1000),
        supabase
          .from("classified_categories")
          .select("id, parent_id, is_obsolete"),
        supabase
          .from("categories")
          .select("id, name, slug, parent_id"),
      ]);

    if (adsRes.error) {
      console.error("Sitemap ads query error:", adsRes.error);
    }
    if (productsRes.error) {
      console.error("Sitemap products query error:", productsRes.error);
    }
    if (sellersRes.error) {
      console.error("Sitemap sellers query error:", sellersRes.error);
    }
    if (classifiedCatsRes.error) {
      console.error("Sitemap classified categories query error:", classifiedCatsRes.error);
    }
    if (foodCatsRes.error) {
      console.error("Sitemap food categories query error:", foodCatsRes.error);
    }

    const ads = ((adsRes.data ?? []) as SitemapAdRow[]);
    const products = ((productsRes.data ?? []) as SitemapProductRow[]);
    const sellers = ((sellersRes.data ?? []) as Array<{ id: string; created_at?: string | null }>);
    const classifiedCats = ((classifiedCatsRes.data ?? []) as ClassifiedCategoryRow[]);
    const foodCats = ((foodCatsRes.data ?? []) as FoodCategoryRow[]);

    const latestAdDate = maxIsoDate(ads.map((a) => a.updated_at || a.created_at));
    const latestProductDate = maxIsoDate(products.map((p) => p.created_at));
    const latestSellerDate = maxIsoDate(sellers.map((s) => s.created_at));
    const latestHomeDate = maxIsoDate([
      latestAdDate,
      latestProductDate,
      latestSellerDate,
    ]);

    const coreEntries = buildCoreEntries(baseUrl, {
      home: latestHomeDate || today,
      classifieds: latestAdDate,
      categories: latestProductDate,
      search: latestProductDate,
      sellersMap: latestSellerDate,
    });

    const classifiedCategoryEntries =
      !adsRes.error && !classifiedCatsRes.error
        ? buildPopulatedClassifiedCategoryEntries({
            baseUrl,
            categories: classifiedCats,
            ads,
          })
        : CLASSIFIED_CATEGORIES.map((cat): SitemapEntry => ({
            loc: `${baseUrl}/classifieds?category=${cat}`,
            lastmod: today,
            changefreq: "daily",
            priority: "0.85",
          }));

    const foodCategoryEntries =
      !productsRes.error && !foodCatsRes.error
        ? buildPopulatedFoodCategoryEntries({
            baseUrl,
            categories: foodCats,
            products,
          })
        : FOOD_CATEGORIES.map((cat): SitemapEntry => ({
            loc: `${baseUrl}/categories?category=${cat}`,
            lastmod: today,
            changefreq: "daily",
            priority: "0.85",
          }));

    const dynamicEntries: SitemapEntry[] = [];

    for (const ad of ads) {
      if (!ad.id) continue;
      dynamicEntries.push({
        loc: `${baseUrl}/classifieds/ad/${encodeURIComponent(ad.id)}`,
        lastmod: formatDate(ad.updated_at || ad.created_at),
        changefreq: "weekly",
        priority: "0.80",
      });
    }

    for (const prod of products) {
      if (!prod.id || !prod.available_now) continue;
      dynamicEntries.push({
        loc: `${baseUrl}/product/${encodeURIComponent(prod.id)}`,
        lastmod: formatDate(prod.created_at),
        changefreq: "weekly",
        priority: "0.80",
      });
    }

    for (const seller of sellers) {
      if (!seller.id) continue;
      dynamicEntries.push({
        loc: `${baseUrl}/seller/${encodeURIComponent(seller.id)}`,
        lastmod: formatDate(seller.created_at),
        changefreq: "weekly",
        priority: "0.75",
      });
    }

    const allEntries = [
      ...coreEntries,
      ...classifiedCategoryEntries,
      ...foodCategoryEntries,
      ...dynamicEntries,
    ];
    const xml = buildXml(allEntries, baseUrl);

    return new Response(xml, {
      status: 200,
      headers: {
        "Content-Type": "application/xml; charset=utf-8",
        "Cache-Control": "public, max-age=3600, s-maxage=3600, stale-while-revalidate=86400",
      },
    });
  } catch (err) {
    console.error("Dynamic sitemap generation error:", err);
    return new Response(buildXml(fallbackEntries, baseUrl), {
      status: 200,
      headers: {
        "Content-Type": "application/xml; charset=utf-8",
        "Cache-Control": "public, max-age=300, s-maxage=300",
      },
    });
  }
}

export async function onRequestGet(context: {
  request: Request;
  env?: any;
}): Promise<Response> {
  return handleSitemap(context.request, context.env);
}

export async function GET(request: Request): Promise<Response> {
  return handleSitemap(request);
}
