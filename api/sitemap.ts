export const runtime = "edge";
export const config = { runtime: "edge" };

import { createClient } from "@supabase/supabase-js";
import { normalizeBaseUrl, resolvePublicBaseUrl } from "./_shared/preview-utils.js";

declare const process: any;

type SitemapEntry = {
  loc: string;
  lastmod?: string;
  changefreq?: "always" | "hourly" | "daily" | "weekly" | "monthly" | "yearly" | "never";
  priority?: string;
};

const CLASSIFIED_CATEGORIES = [
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

const FOOD_CATEGORIES = [
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

function buildXml(entries: SitemapEntry[]): string {
  const urlsXml = entries
    .map((e) => {
      const parts = [`    <loc>${e.loc}</loc>`];
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

export async function GET(request: Request): Promise<Response> {
  const requestUrl = new URL(request.url);
  const origin = normalizeBaseUrl(requestUrl.origin);
  const baseUrl = resolvePublicBaseUrl(origin);
  const today = formatDate();

  const staticEntries: SitemapEntry[] = [
    // Glavne rute
    { loc: `${baseUrl}/`, lastmod: today, changefreq: "daily", priority: "1.0" },
    { loc: `${baseUrl}/classifieds`, lastmod: today, changefreq: "daily", priority: "0.95" },
    { loc: `${baseUrl}/categories`, lastmod: today, changefreq: "daily", priority: "0.90" },
    { loc: `${baseUrl}/search`, lastmod: today, changefreq: "daily", priority: "0.80" },
    { loc: `${baseUrl}/sellers-map`, lastmod: today, changefreq: "weekly", priority: "0.80" },
    { loc: `${baseUrl}/about`, lastmod: today, changefreq: "monthly", priority: "0.60" },
    { loc: `${baseUrl}/uslovi-koriscenja`, lastmod: today, changefreq: "yearly", priority: "0.40" },
    { loc: `${baseUrl}/politika-privatnosti`, lastmod: today, changefreq: "yearly", priority: "0.40" },

    // Kategorije malih oglasa
    ...CLASSIFIED_CATEGORIES.map((cat): SitemapEntry => ({
      loc: `${baseUrl}/classifieds?category=${cat}`,
      lastmod: today,
      changefreq: "daily",
      priority: "0.85",
    })),

    // Kategorije domaće hrane
    ...FOOD_CATEGORIES.map((cat): SitemapEntry => ({
      loc: `${baseUrl}/categories?category=${cat}`,
      lastmod: today,
      changefreq: "daily",
      priority: "0.85",
    })),
  ];

  try {
    const supabaseUrl = typeof process !== "undefined"
      ? (process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL)
      : undefined;
    const supabaseAnonKey = typeof process !== "undefined"
      ? (process.env.SUPABASE_ANON_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY)
      : undefined;

    if (!supabaseUrl || !supabaseAnonKey) {
      // Bez Supabase kredencijala, vrati statički sitemap
      return new Response(buildXml(staticEntries), {
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

    // Paralelno dohvatanje aktivnih oglasa i proizvoda
    const [adsRes, productsRes] = await Promise.all([
      supabase
        .from("classified_ads")
        .select("id, updated_at, created_at")
        .eq("status", "active")
        .order("created_at", { ascending: false })
        .limit(3000),
      supabase
        .from("products")
        .select("id, updated_at, created_at")
        .eq("available_now", true)
        .order("created_at", { ascending: false })
        .limit(3000),
    ]);

    const dynamicEntries: SitemapEntry[] = [];

    if (adsRes.data && Array.isArray(adsRes.data)) {
      for (const ad of adsRes.data) {
        if (!ad.id) continue;
        const modDate = formatDate(ad.updated_at || ad.created_at);
        dynamicEntries.push({
          loc: `${baseUrl}/classifieds/ad/${encodeURIComponent(ad.id)}`,
          lastmod: modDate,
          changefreq: "weekly",
          priority: "0.80",
        });
      }
    }

    if (productsRes.data && Array.isArray(productsRes.data)) {
      for (const prod of productsRes.data) {
        if (!prod.id) continue;
        const modDate = formatDate(prod.updated_at || prod.created_at);
        dynamicEntries.push({
          loc: `${baseUrl}/product/${encodeURIComponent(prod.id)}`,
          lastmod: modDate,
          changefreq: "weekly",
          priority: "0.80",
        });
      }
    }

    const allEntries = [...staticEntries, ...dynamicEntries];
    const xml = buildXml(allEntries);

    return new Response(xml, {
      status: 200,
      headers: {
        "Content-Type": "application/xml; charset=utf-8",
        "Cache-Control": "public, max-age=3600, s-maxage=3600, stale-while-revalidate=86400",
      },
    });
  } catch (err) {
    console.error("Dynamic sitemap generation error:", err);
    // Siguran fallback: u slučaju bilo koje greške vrati statički sitemap
    return new Response(buildXml(staticEntries), {
      status: 200,
      headers: {
        "Content-Type": "application/xml; charset=utf-8",
        "Cache-Control": "public, max-age=300, s-maxage=300",
      },
    });
  }
}
