import { buildHtml, isBot } from "./api/_shared/preview-utils.js";
import { handleClassifiedPreview } from "./api/classified-preview.js";
import { handleProductPreview } from "./api/product-preview.js";
import { handleSitemap } from "./api/sitemap.js";
import { resolveStaticPageSeo } from "./api/_shared/static-seo-pages.js";

export const onRequest: PagesFunction = async (context) => {
  const { request, env } = context;
  const url = new URL(request.url);
  const pathname = url.pathname;
  const userAgent = request.headers.get("user-agent");

  // 0. XML sitemap za sve posetioce (botove i ljude).
  //    Moramo je servirati iz middleware-a: `_redirects` 200-proxy ne može da
  //    pozove Pages funkciju, pa se zahtev za /sitemap.xml propada na SPA
  //    catch-all i Google dobija HTML umesto XML sitemape. Functions se
  //    izvršavaju pre `_redirects`-a i statičkih fajlova, pa je ovo pouzdano.
  if (pathname === "/sitemap.xml") {
    return handleSitemap(request, env);
  }

  // 0a. Cloudflare interni i email-protection linkovi: vratiti 410 Gone kako bi
  //     pretraživači (Google Search Console) odmah uklonili ove nepostojeće rute iz indeksa.
  if (pathname.startsWith("/cdn-cgi/")) {
    return new Response(null, {
      status: 410,
      statusText: "Gone",
      headers: {
        "cache-control": "public, max-age=86400",
      },
    });
  }

  // 1. Kratki linkovi: /ad/:id
  const adShortMatch = pathname.match(/^\/ad\/([^/]+)$/);
  if (adShortMatch) {
    const id = decodeURIComponent(adShortMatch[1]);
    const previewUrl = new URL(`/api/classified-preview?id=${encodeURIComponent(id)}`, url.origin);
    const subReq = new Request(previewUrl.toString(), request);
    return handleClassifiedPreview(subReq, env);
  }

  // 2. Kratki linkovi: /p/:id
  const prodShortMatch = pathname.match(/^\/p\/([^/]+)$/);
  if (prodShortMatch) {
    const id = decodeURIComponent(prodShortMatch[1]);
    const previewUrl = new URL(`/api/product-preview?id=${encodeURIComponent(id)}`, url.origin);
    const subReq = new Request(previewUrl.toString(), request);
    return handleProductPreview(subReq, env);
  }

  // 3. Bot detekcija za puni link oglasa: /classifieds/ad/:id
  const classifiedMatch = pathname.match(/^\/classifieds\/ad\/([^/]+)$/);
  if (classifiedMatch && isBot(userAgent)) {
    const id = decodeURIComponent(classifiedMatch[1]);
    const previewUrl = new URL(`/api/classified-preview?id=${encodeURIComponent(id)}`, url.origin);
    const subReq = new Request(previewUrl.toString(), request);
    return handleClassifiedPreview(subReq, env);
  }

  // 4. Bot detekcija za puni link proizvoda: /product/:id
  const productMatch = pathname.match(/^\/product\/([^/]+)$/);
  if (productMatch && isBot(userAgent)) {
    const id = decodeURIComponent(productMatch[1]);
    const previewUrl = new URL(`/api/product-preview?id=${encodeURIComponent(id)}`, url.origin);
    const subReq = new Request(previewUrl.toString(), request);
    return handleProductPreview(subReq, env);
  }

  // 5. Server-rendered SEO HTML za ključne javne rute (/classifieds, /categories
  //    + ?category= varijante, /search, /sellers-map, /about). Flutter SPA crta
  //    sadržaj na <canvas> i hardcoduje kanonski URL početne strane, pa botovi
  //    inače vide prazan duplikat homepage-a. Kanonski URL-ovi ovde su identični
  //    <loc> vrednostima iz sitemape. Obični korisnici i dalje dobijaju SPA.
  if (isBot(userAgent)) {
    const seoPayload = resolveStaticPageSeo(pathname, url.searchParams, url.origin);
    if (seoPayload) {
      return new Response(buildHtml(seoPayload), {
        status: 200,
        headers: {
          "content-type": "text/html; charset=utf-8",
          "cache-control":
            "public, max-age=0, s-maxage=3600, stale-while-revalidate=86400",
        },
      });
    }
  }

  // Za sve ostale zahteve (uključujući stvarne korisnike), nastavi ka statičkim fajlovima / Flutter SPA
  return context.next();
};
