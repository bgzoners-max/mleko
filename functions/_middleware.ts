import { isBot } from "./api/_shared/preview-utils.js";
import { handleClassifiedPreview } from "./api/classified-preview.js";
import { handleProductPreview } from "./api/product-preview.js";

export const onRequest: PagesFunction = async (context) => {
  const { request, env } = context;
  const url = new URL(request.url);
  const pathname = url.pathname;
  const userAgent = request.headers.get("user-agent");

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

  // Za sve ostale zahteve (uključujući stvarne korisnike), nastavi ka statičkim fajlovima / Flutter SPA
  return context.next();
};
