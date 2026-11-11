import { assert, assertEquals, assertStringIncludes } from "jsr:@std/assert";
import { buildHtml } from "../functions/api/_shared/preview-utils.ts";
import {
  buildNotFoundHtml,
  getClassifiedCategoryEntries,
  getFoodCategoryEntries,
  resolveStaticPageSeo,
} from "../functions/api/_shared/static-seo-pages.ts";

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
