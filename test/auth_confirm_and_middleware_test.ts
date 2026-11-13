import { assertEquals, assertStringIncludes } from "jsr:@std/assert";
import {
  buildAuthConfirmRedirectUrl,
  sanitizeNextPath,
} from "../functions/api/_shared/auth-confirm-utils.ts";
import {
  matchMiddlewarePreviewRoute,
  resolveApexCanonicalRedirectUrl,
  resolveLegacyRouteRedirect,
} from "../functions/api/_shared/preview-utils.ts";

const BASE = "https://www.domacimarket.rs";

Deno.test("sanitizeNextPath blokira open redirect i vraća bezbedan fallback", () => {
  assertEquals(sanitizeNextPath("//evil.com"), "/auth/confirmed");
  assertEquals(sanitizeNextPath("/\\evil.com"), "/auth/confirmed");
  assertEquals(sanitizeNextPath("https://evil.com/phish"), "/auth/confirmed");
  assertEquals(sanitizeNextPath("javascript:alert(1)"), "/auth/confirmed");
  assertEquals(sanitizeNextPath("/settings#evil"), "/auth/confirmed");
  assertEquals(sanitizeNextPath("settings"), "/settings");
  assertEquals(sanitizeNextPath("/settings"), "/settings");
  assertEquals(sanitizeNextPath(""), "/auth/confirmed");
});

Deno.test("buildAuthConfirmRedirectUrl ne proizvodi dupli '#' i pakuje tokene unutar fragmenta", () => {
  const redirect = buildAuthConfirmRedirectUrl(
    BASE,
    "/auth/confirmed",
    {
      access_token: "acc-123",
      refresh_token: "ref-456",
      expires_in: 3600,
    },
    "signup",
  );

  assertStringIncludes(redirect, `${BASE}/#/auth/confirmed?verified=1&`);
  assertStringIncludes(redirect, "access_token=acc-123");
  assertStringIncludes(redirect, "type=signup");
  const hashCount = (redirect.match(/#/g) ?? []).length;
  assertEquals(hashCount, 1);
  // Provera da su parametri u fragmentu, a ne pre '#' (bez curenja u Referer/server log).
  assertEquals(redirect.split("#")[0].includes("access_token"), false);
});

Deno.test("resolveApexCanonicalRedirectUrl ne preusmerava /.well-known/assetlinks.json", () => {
  const assetLinks = resolveApexCanonicalRedirectUrl(
    new URL("https://domacimarket.rs/.well-known/assetlinks.json"),
  );
  assertEquals(assetLinks, null);

  const regularApex = resolveApexCanonicalRedirectUrl(
    new URL("https://domacimarket.rs/support"),
  );
  assertEquals(regularApex, "https://www.domacimarket.rs/support");

  const shopApex = resolveApexCanonicalRedirectUrl(
    new URL("https://domacimarket.rs/shop/"),
  );
  assertEquals(shopApex, "https://www.domacimarket.rs/");

  const termsApex = resolveApexCanonicalRedirectUrl(
    new URL("https://domacimarket.rs/terms/"),
  );
  assertEquals(termsApex, "https://www.domacimarket.rs/uslovi-koriscenja");
});

Deno.test("resolveLegacyRouteRedirect preusmerava /shop i /terms na kanonske rute", () => {
  assertEquals(
    resolveLegacyRouteRedirect(new URL(`${BASE}/shop`)),
    `${BASE}/`,
  );
  assertEquals(
    resolveLegacyRouteRedirect(new URL(`${BASE}/terms`)),
    `${BASE}/uslovi-koriscenja`,
  );
  assertEquals(
    resolveLegacyRouteRedirect(new URL(`${BASE}/terms/`)),
    `${BASE}/uslovi-koriscenja`,
  );
  assertEquals(
    resolveLegacyRouteRedirect(new URL(`${BASE}/classifieds`)),
    null,
  );
});

Deno.test("matchMiddlewarePreviewRoute podržava opcioni trailing slash za kratke linkove i botove", () => {
  assertEquals(matchMiddlewarePreviewRoute("/ad/ogl-1/", false), {
    kind: "classified",
    id: "ogl-1",
  });
  assertEquals(matchMiddlewarePreviewRoute("/p/pro-2/", false), {
    kind: "product",
    id: "pro-2",
  });
  assertEquals(matchMiddlewarePreviewRoute("/product/pro-2/", true), {
    kind: "product",
    id: "pro-2",
  });
  assertEquals(matchMiddlewarePreviewRoute("/classifieds/ad/ogl-1/", true), {
    kind: "classified",
    id: "ogl-1",
  });
  assertEquals(matchMiddlewarePreviewRoute("/product/pro-2/", false), null);
});
