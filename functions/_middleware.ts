import {
  buildHtml,
  isBot,
  matchMiddlewarePreviewRoute,
  resolveApexCanonicalRedirectUrl,
  resolveLegacyRouteRedirect,
} from "./api/_shared/preview-utils.js";
import { handleClassifiedPreview } from "./api/classified-preview.js";
import { handleProductPreview } from "./api/product-preview.js";
import { handleSitemap } from "./api/sitemap.js";
import {
  buildNotFoundHtml,
  resolveStaticPageSeo,
} from "./api/_shared/static-seo-pages.js";
import { enrichDirectorySeoPayload } from "./api/_shared/directory-ssr.js";
import { onRequestGet as onSellerPreviewRequest } from "./api/seller-preview.js";

export const onRequest: PagesFunction = async (context) => {
  const { request, env } = context;
  const url = new URL(request.url);
  const pathname = url.pathname;
  const userAgent = request.headers.get("user-agent");

  // 0. Apex na WWW 301 Permanent Redirect (Google SEO Canonical Rule, uz izuzetak
  //    za /.well-known/assetlinks.json kako bi Android autoVerify radio na oba hosta).
  const apexRedirectTarget = resolveApexCanonicalRedirectUrl(url);
  if (apexRedirectTarget) {
    return Response.redirect(apexRedirectTarget, 301);
  }

  // 0a. Zastarele / alternativne rute (/shop, /terms) -> 301 ka kanonskim rutama
  const legacyRedirectTarget = resolveLegacyRouteRedirect(url);
  if (legacyRedirectTarget) {
    return Response.redirect(legacyRedirectTarget, 301);
  }

  // 0b. XML sitemap za sve posetioce (botove i ljude).
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

  // 1-4. Kratki linkovi (/ad/:id, /p/:id) i bot preview za /classifieds/ad/:id, /product/:id
  const previewMatch = matchMiddlewarePreviewRoute(pathname, isBot(userAgent));
  if (previewMatch) {
    const endpoint =
      previewMatch.kind === "classified"
        ? "/api/classified-preview"
        : "/api/product-preview";
    const previewUrl = new URL(
      `${endpoint}?id=${encodeURIComponent(previewMatch.id)}`,
      url.origin,
    );
    const subReq = new Request(previewUrl.toString(), request);
    return previewMatch.kind === "classified"
      ? handleClassifiedPreview(subReq, env)
      : handleProductPreview(subReq, env);
  }

  // 5. Server-rendered SEO HTML za ključne javne rute (/classifieds, /categories
  //    + ?category= varijante, /search, /sellers-map, /about). Flutter SPA crta
  //    sadržaj na <canvas> i hardcoduje kanonski URL početne strane, pa botovi
  //    inače vide prazan duplikat homepage-a. Kanonski URL-ovi ovde su identični
  //    <loc> vrednostima iz sitemape. Obični korisnici i dalje dobijaju SPA.
  const sellerMatch = pathname.match(/^\/seller\/([^/]+)\/?$/);
  if (sellerMatch) {
    return onSellerPreviewRequest({
      ...context,
      env: (context.env ?? {}) as Record<string, string | undefined>,
      params: { ...context.params, id: sellerMatch[1] },
    });
  }

  if (isBot(userAgent)) {
    const seoPayload = resolveStaticPageSeo(pathname, url.searchParams, url.origin);
    if (seoPayload) {
      const enrichedPayload = await enrichDirectorySeoPayload({
        pathname,
        searchParams: url.searchParams,
        origin: url.origin,
        env: context.env as any,
        basePayload: seoPayload,
      });
      const headers: Record<string, string> = {
        "content-type": "text/html; charset=utf-8",
        "cache-control":
          "public, max-age=0, s-maxage=3600, stale-while-revalidate=86400",
      };
      if (enrichedPayload.robots?.startsWith("noindex")) {
        headers["x-robots-tag"] = enrichedPayload.robots;
      }
      return new Response(buildHtml(enrichedPayload), {
        status: 200,
        headers,
      });
    }

    const normalizedBotPath =
      pathname === "/" ? "/" : pathname.replace(/\/+$/, "");
    const hasFileExtension = /\.[a-zA-Z0-9]{1,8}$/.test(normalizedBotPath);
    const isAssetOrSystemPath =
      normalizedBotPath.startsWith("/assets/") ||
      normalizedBotPath.startsWith("/icons/") ||
      normalizedBotPath.startsWith("/.well-known/") ||
      normalizedBotPath.startsWith("/api/");

    const isKnownStaticOrHtmlRoute =
      normalizedBotPath === "/" ||
      normalizedBotPath === "/uslovi-koriscenja" ||
      normalizedBotPath === "/politika-privatnosti" ||
      normalizedBotPath === "/terms";

    const isPrivateOrDynamicSpaRoute =
      normalizedBotPath === "/login" ||
      normalizedBotPath === "/register" ||
      normalizedBotPath === "/splash" ||
      normalizedBotPath === "/onboarding" ||
      normalizedBotPath === "/verify-email" ||
      normalizedBotPath.startsWith("/auth/") ||
      normalizedBotPath === "/cart" ||
      normalizedBotPath === "/favorites" ||
      normalizedBotPath === "/favorite-sellers" ||
      normalizedBotPath === "/notifications" ||
      normalizedBotPath === "/settings" ||
      normalizedBotPath.startsWith("/profile") ||
      normalizedBotPath === "/orders" ||
      normalizedBotPath === "/conversations" ||
      normalizedBotPath.startsWith("/chat/") ||
      normalizedBotPath.startsWith("/checkout") ||
      normalizedBotPath === "/add-product" ||
      normalizedBotPath.startsWith("/product/edit/") ||
      normalizedBotPath === "/becoming-seller" ||
      normalizedBotPath === "/seller-dashboard" ||
      normalizedBotPath === "/seller-settings" ||
      normalizedBotPath === "/map-picker" ||
      normalizedBotPath === "/classifieds/new" ||
      normalizedBotPath.startsWith("/classifieds/edit/") ||
      normalizedBotPath === "/classifieds/my" ||
      normalizedBotPath === "/classifieds/saved-searches" ||
      normalizedBotPath.startsWith("/admin/") ||
      normalizedBotPath.startsWith("/support/ticket/") ||
      normalizedBotPath.startsWith("/buyer/") ||
      normalizedBotPath.startsWith("/seller/") ||
      normalizedBotPath.startsWith("/categories/");

    if (isPrivateOrDynamicSpaRoute) {
      const noindexUrl = `${url.origin}${normalizedBotPath}`;
      return new Response(
        buildHtml({
          title: "Domaći Market",
          description: "Pristup stranici na platformi Domaći Market.",
          previewUrl: noindexUrl,
          canonicalUrl: noindexUrl,
          imageUrl: `${url.origin}/icons/Icon-512.png`,
          robots: "noindex,nofollow",
          ogType: "website",
          omitRedirectFallback: true,
        }),
        {
          status: 200,
          headers: {
            "content-type": "text/html; charset=utf-8",
            "x-robots-tag": "noindex, nofollow",
            "cache-control": "no-store",
          },
        },
      );
    }

    if (!hasFileExtension && !isAssetOrSystemPath && !isKnownStaticOrHtmlRoute) {
      return new Response(buildNotFoundHtml(pathname, url.origin), {
        status: 404,
        headers: {
          "content-type": "text/html; charset=utf-8",
          "x-robots-tag": "noindex, nofollow",
          "cache-control": "public, max-age=0, s-maxage=300",
        },
      });
    }
  }

  // Za sve ostale zahteve (uključujući stvarne korisnike), nastavi ka statičkim fajlovima / Flutter SPA
  return context.next();
};
