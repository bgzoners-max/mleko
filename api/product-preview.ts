import { createClient } from '@supabase/supabase-js';

type ProductRow = {
  id: string;
  name: string;
  description: string | null;
  location: string | null;
  price_per_kg: number | null;
  unit_type: string | null;
  image_urls: string[] | null;
};

type HtmlPayload = {
  title: string;
  description: string;
  previewUrl: string;
  canonicalUrl: string;
  imageUrl: string;
};

const FALLBACK_TITLE = 'Domaće, baš kako treba! | domaćimarket.rs';
const FALLBACK_DESCRIPTION =
  'Domaće, baš kako treba! Povežite se sa proverenim proizvođačima i otkrijte lokalnu ponudu na domaćimarket.rs.';

function normalizeBaseUrl(value: string): string {
  return value.trim().replace(/\/+$/, '');
}

function resolvePublicBaseUrl(origin: string): string {
  return normalizeBaseUrl(origin);
}

function escapeHtml(value: string): string {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

function normalizeImageUrl(
  imageUrl: string | null | undefined,
  origin: string,
): string {
  if (!imageUrl) return `${origin}/icons/Icon-512.png`;
  if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
    return imageUrl;
  }
  if (imageUrl.startsWith('/')) {
    return `${origin}${imageUrl}`;
  }
  return `${origin}/${imageUrl}`;
}

function formatPrice(
  pricePerKg: number | null,
  unitType: string | null,
): string | null {
  if (pricePerKg == null) return null;
  switch (unitType) {
    case 'L':
      return `${pricePerKg.toFixed(0)} RSD/L`;
    case 'kom':
      return `${pricePerKg.toFixed(0)} RSD/kom`;
    default:
      return `${pricePerKg.toFixed(0)} RSD/kg`;
  }
}

function buildDescription(product: ProductRow | null): string {
  if (product == null) return FALLBACK_DESCRIPTION;

  const location = product.location?.trim();
  const description = product.description?.trim();
  const parts = [
    formatPrice(product.price_per_kg, product.unit_type),
    location ? `Lokacija: ${location}` : null,
    description || 'Pogledajte detalje proizvoda i lokalnu ponudu na Domaćem marketu.',
  ].filter((part): part is string => Boolean(part));

  const text = parts.join('. ').replace(/\s+/g, ' ').trim();
  if (text.length <= 220) return text;
  return `${text.slice(0, 217).trimEnd()}...`;
}

function buildHtml({
  title,
  description,
  previewUrl,
  canonicalUrl,
  imageUrl,
}: HtmlPayload): string {
  const escapedTitle = escapeHtml(title);
  const escapedDescription = escapeHtml(description);
  const escapedPreviewUrl = escapeHtml(previewUrl);
  const escapedCanonicalUrl = escapeHtml(canonicalUrl);
  const escapedImageUrl = escapeHtml(imageUrl);
  const redirectTarget = canonicalUrl.replaceAll('"', '%22');

  return `<!DOCTYPE html>
<html lang="sr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${escapedTitle}</title>
  <meta name="description" content="${escapedDescription}">
  <meta name="robots" content="noindex,follow">
  <link rel="canonical" href="${escapedCanonicalUrl}">

  <meta property="og:type" content="product">
  <meta property="og:title" content="${escapedTitle}">
  <meta property="og:description" content="${escapedDescription}">
  <meta property="og:url" content="${escapedPreviewUrl}">
  <meta property="og:image" content="${escapedImageUrl}">
  <meta property="og:site_name" content="Domaći market">
  <meta property="og:locale" content="sr_RS">

  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="${escapedTitle}">
  <meta name="twitter:description" content="${escapedDescription}">
  <meta name="twitter:image" content="${escapedImageUrl}">

  <meta http-equiv="refresh" content="0;url=${escapedCanonicalUrl}">
  <script>
    window.location.replace("${redirectTarget}");
  </script>
</head>
<body>
  <p>Preusmeravanje na proizvod...</p>
</body>
</html>`;
}

export default {
  async fetch(request: Request): Promise<Response> {
    const requestUrl = new URL(request.url);
    const productId = requestUrl.searchParams.get('id')?.trim();
    const origin = normalizeBaseUrl(requestUrl.origin);
    const publicBaseUrl = resolvePublicBaseUrl(origin);

    if (!productId) {
      return new Response('Missing product id.', { status: 400 });
    }

    const encodedProductId = encodeURIComponent(productId);
    const canonicalUrl = `${publicBaseUrl}/product/${encodedProductId}`;
    const previewUrl = `${publicBaseUrl}/p/${encodedProductId}`;
    const fallbackImageUrl = `${origin}/icons/Icon-512.png`;

    const supabaseUrl = process.env.SUPABASE_URL;
    const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;

    if (!supabaseUrl || !supabaseAnonKey) {
      const html = buildHtml({
        title: FALLBACK_TITLE,
        description: FALLBACK_DESCRIPTION,
        previewUrl,
        canonicalUrl,
        imageUrl: fallbackImageUrl,
      });

      return new Response(html, {
        status: 200,
        headers: {
          'content-type': 'text/html; charset=utf-8',
          'cache-control': 'public, max-age=0, s-maxage=60, stale-while-revalidate=3600',
        },
      });
    }

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const { data, error } = await supabase
      .from('products')
      .select('id, name, description, location, price_per_kg, unit_type, image_urls')
      .eq('id', productId)
      .maybeSingle();

    const product = error ? null : (data as ProductRow | null);
    const title = product
      ? `${product.name} | Domaći market`
      : 'Proizvod nije pronađen | Domaći market';
    const description = buildDescription(product);
    const imageUrl = normalizeImageUrl(product?.image_urls?.[0], origin);
    const html = buildHtml({
      title,
      description,
      previewUrl,
      canonicalUrl,
      imageUrl,
    });

    return new Response(html, {
      status: product ? 200 : 404,
      headers: {
        'content-type': 'text/html; charset=utf-8',
        'cache-control': 'public, max-age=0, s-maxage=300, stale-while-revalidate=86400',
      },
    });
  },
};
