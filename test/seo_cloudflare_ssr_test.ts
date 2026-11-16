import { assert, assertEquals, assertStringIncludes } from "jsr:@std/assert";
import { buildHtml } from "../functions/api/_shared/preview-utils.ts";
import {
  buildNotFoundHtml,
  getClassifiedCategoryEntries,
  getFoodCategoryEntries,
  resolveStaticPageSeo,
} from "../functions/api/_shared/static-seo-pages.ts";
import { enrichDirectorySeoPayload } from "../functions/api/_shared/directory-ssr.ts";
import {
  buildPopulatedClassifiedCategoryEntries,
  buildPopulatedFoodCategoryEntries,
} from "../functions/api/sitemap.ts";

const ORIGIN = "https://www.domacimarket.rs";

Deno.test("resolveStaticPageSeo covers /support route", () => {
  const payload = resolveStaticPageSeo("/support", new URLSearchParams(), ORIGIN);
  assert(payload !== null);
  assertEquals(payload.canonicalUrl, `${ORIGIN}/support`);
  assertEquals(payload.robots, "index,follow,max-image-preview:large");
  assertStringIncludes(payload.title, "Podrška");
});

Deno.test("search query URLs (?q=) emit noindex,follow and omit redirect stub", () => {
  const classifiedQuery = resolveStaticPageSeo(
    "/classifieds",
    new URLSearchParams("q=traktor"),
    ORIGIN,
  );
  assert(classifiedQuery !== null);
  assertEquals(classifiedQuery.robots, "noindex,follow");
  assertEquals(classifiedQuery.canonicalUrl, `${ORIGIN}/classifieds`);

  const templateQuery = resolveStaticPageSeo(
    "/classifieds",
    new URLSearchParams("q={search_term_string}"),
    ORIGIN,
  );
  assert(templateQuery !== null);
  assertEquals(templateQuery.robots, "noindex,follow");

  const searchQuery = resolveStaticPageSeo(
    "/search",
    new URLSearchParams("q=med"),
    ORIGIN,
  );
  assert(searchQuery !== null);
  assertEquals(searchQuery.robots, "noindex,follow");
  assertEquals(searchQuery.canonicalUrl, `${ORIGIN}/search`);

  const searchCat = resolveStaticPageSeo(
    "/search",
    new URLSearchParams("category=Mleko"),
    ORIGIN,
  );
  assert(searchCat !== null);
  assertEquals(searchCat.robots, "noindex,follow");
});

Deno.test("category SSR builds canonical, breadcrumbs, sections, and no stub note", () => {
  const payload = resolveStaticPageSeo(
    "/classifieds",
    new URLSearchParams("category=deca_bebe"),
    ORIGIN,
  );
  assert(payload !== null);
  assertEquals(payload.canonicalUrl, `${ORIGIN}/classifieds?category=deca_bebe`);
  assertEquals(payload.robots, "index,follow,max-image-preview:large");
  assert(Array.isArray(payload.sections) && payload.sections.length > 0);
  assert(Array.isArray(payload.breadcrumbs) && payload.breadcrumbs.length === 3);

  const html = buildHtml(payload);
  assertStringIncludes(html, '<link rel="canonical" href="https://www.domacimarket.rs/classifieds?category=deca_bebe">');
  assertStringIncludes(html, 'hreflang="sr-RS"');
  assertStringIncludes(html, 'hreflang="x-default"');
  assert(!html.includes('hreflang="sr"'));
  assert(!html.includes("Učitavanje stranice..."));
  assertStringIncludes(html, "BreadcrumbList");
  assertStringIncludes(html, "CollectionPage");
});

Deno.test("unknown category param on /categories falls back to noindex,follow", () => {
  const payload = resolveStaticPageSeo(
    "/categories",
    new URLSearchParams("category=nepostojeca_kategorija"),
    ORIGIN,
  );
  assert(payload !== null);
  assertEquals(payload.robots, "noindex,follow");
  assertEquals(payload.canonicalUrl, `${ORIGIN}/categories`);
});

Deno.test("/categories/:slug resolves known food categories and noindexes unknown slugs", () => {
  const knownPayload = resolveStaticPageSeo(
    "/categories/mlecni-proizvodi",
    new URLSearchParams(),
    ORIGIN,
  );
  assert(knownPayload !== null);
  assertEquals(knownPayload.robots, "index,follow,max-image-preview:large");
  assertEquals(
    knownPayload.canonicalUrl,
    `${ORIGIN}/categories?category=mlecni-proizvodi`,
  );

  const unknownPayload = resolveStaticPageSeo(
    "/categories/nepoznat-slug-123",
    new URLSearchParams(),
    ORIGIN,
  );
  assert(unknownPayload !== null);
  assertEquals(unknownPayload.robots, "noindex,follow");
  assertEquals(unknownPayload.canonicalUrl, `${ORIGIN}/categories`);
});

Deno.test("buildNotFoundHtml sets noindex,nofollow and self url", () => {
  const html = buildNotFoundHtml("/nepostojeca-stranica", ORIGIN);
  assertStringIncludes(html, '<meta name="robots" content="noindex,nofollow">');
  assertStringIncludes(html, '<link rel="canonical" href="https://www.domacimarket.rs/nepostojeca-stranica">');
  assertStringIncludes(html, "Stranica nije pronađena (404)");
});

Deno.test("classified and food category catalogs contain expected entries", () => {
  assertEquals(getClassifiedCategoryEntries().length, 16);
  assertEquals(getFoodCategoryEntries().length, 14);
});

Deno.test("buildHtml escapes breadcrumbs, sections, navLinks, and renders JSON-LD array", () => {
  const html = buildHtml({
    title: "Test <naslov>",
    description: "Opis",
    previewUrl: `${ORIGIN}/classifieds`,
    canonicalUrl: `${ORIGIN}/classifieds`,
    imageUrl: `${ORIGIN}/icons/Icon-512.png`,
    navLinks: [{ label: "Početna <1>", href: `${ORIGIN}/` }],
    breadcrumbs: [{ label: "Kategorija & \"test\"" }],
    sections: [
      {
        heading: "Sekcija <script>",
        links: [
          {
            label: "Oglas & vise",
            href: `${ORIGIN}/classifieds/ad/123`,
            badge: "<NOVO>",
            meta: "1000 RSD",
          },
        ],
      },
    ],
    jsonLd: [
      { "@type": "BreadcrumbList", itemListElement: [] },
      { "@type": "CollectionPage", name: "</script><script>alert(1)</script>" },
    ],
    omitRedirectFallback: true,
  });

  assertStringIncludes(html, "&lt;naslov&gt;");
  assertStringIncludes(html, "Kategorija &amp; &quot;test&quot;");
  assertStringIncludes(html, "Sekcija &lt;script&gt;");
  assertStringIncludes(html, "&lt;NOVO&gt;");
  assert(!html.includes("</script><script>alert(1)"));
  assertStringIncludes(html, "\\u003c/script\\u003e");
  assert(!html.includes("Ako se ništa ne dešava"));
});

function makeMockDirectorySupabase(
  responses: Record<string, { data: unknown; error?: unknown }>,
) {
  const buildChain = (table: string) => {
    const chain: Record<string, unknown> = {
      select: () => chain,
      eq: () => chain,
      in: () => chain,
      order: () => chain,
      limit: () => chain,
      then: (
        onFulfilled: (value: { data: unknown; error?: unknown }) => unknown,
      ) =>
        Promise.resolve(
          responses[table] ?? { data: [], error: null },
        ).then(onFulfilled),
    };
    return chain;
  };
  return {
    from: (table: string) => buildChain(table),
  };
}

Deno.test("enrichDirectorySeoPayload emits noindex,follow for empty category pages and index,follow for populated ones", async () => {
  const emptyParams = new URLSearchParams("category=deca_bebe");
  const emptyBase = resolveStaticPageSeo("/classifieds", emptyParams, ORIGIN)!;
  const emptyResult = await enrichDirectorySeoPayload({
    pathname: "/classifieds",
    searchParams: emptyParams,
    origin: ORIGIN,
    basePayload: emptyBase,
    supabaseClient: makeMockDirectorySupabase({
      classified_categories: {
        data: [{ id: "deca_bebe", name: "Sve za decu i bebe", parent_id: null }],
        error: null,
      },
      public_classified_ads: { data: [], error: null },
    }) as any,
  });
  assertEquals(emptyResult.robots, "noindex,follow");

  const popParams = new URLSearchParams("category=poljoprivreda");
  const popBase = resolveStaticPageSeo("/classifieds", popParams, ORIGIN)!;
  const popResult = await enrichDirectorySeoPayload({
    pathname: "/classifieds",
    searchParams: popParams,
    origin: ORIGIN,
    basePayload: popBase,
    supabaseClient: makeMockDirectorySupabase({
      classified_categories: {
        data: [{ id: "poljoprivreda", name: "Poljoprivreda", parent_id: null }],
        error: null,
      },
      public_classified_ads: {
        data: [
          {
            id: "ad-1",
            title: "Traktor IMT 539",
            price: 4500,
            currency: "EUR",
            price_type: "fixed",
            city: "Šabac",
            images: null,
          },
        ],
        error: null,
      },
    }) as any,
  });
  assertEquals(popResult.robots, "index,follow,max-image-preview:large");

  // Transient DB error must NOT falsely emit noindex
  const errorResult = await enrichDirectorySeoPayload({
    pathname: "/classifieds",
    searchParams: emptyParams,
    origin: ORIGIN,
    basePayload: emptyBase,
    supabaseClient: makeMockDirectorySupabase({
      classified_categories: { data: [], error: null },
      public_classified_ads: { data: null, error: { message: "timeout" } },
    }) as any,
  });
  assertEquals(errorResult.robots, "index,follow,max-image-preview:large");
});

Deno.test("sitemap category helpers exclude empty categories and use real latest lastmod", () => {
  const classifiedEntries = buildPopulatedClassifiedCategoryEntries({
    baseUrl: ORIGIN,
    categories: [
      { id: "poljoprivreda", parent_id: null, is_obsolete: false },
      { id: "traktori", parent_id: "poljoprivreda", is_obsolete: false },
      { id: "deca_bebe", parent_id: null, is_obsolete: false },
    ],
    ads: [
      {
        id: "ad-1",
        category_id: "traktori",
        updated_at: "2026-11-12T10:00:00Z",
        created_at: "2026-11-10T10:00:00Z",
      },
    ],
  });
  assertEquals(classifiedEntries.length, 1);
  assertEquals(classifiedEntries[0].loc, `${ORIGIN}/classifieds?category=poljoprivreda`);
  assertEquals(classifiedEntries[0].lastmod, "2026-11-12");

  const foodEntries = buildPopulatedFoodCategoryEntries({
    baseUrl: ORIGIN,
    categories: [
      { id: "c1", name: "Mlečni proizvodi", slug: "mlecni-proizvodi", parent_id: null },
      { id: "c2", name: "Sirevi", slug: "sirevi", parent_id: "c1" },
      { id: "c3", name: "Meso", slug: "meso", parent_id: null },
    ],
    products: [
      {
        id: "p1",
        category: "Sirevi",
        created_at: "2026-11-09T08:30:00Z",
        available_now: true,
      },
    ],
  });
  assertEquals(foodEntries.length, 1);
  assertEquals(foodEntries[0].loc, `${ORIGIN}/categories?category=mlecni-proizvodi`);
  assertEquals(foodEntries[0].lastmod, "2026-11-09");
});
