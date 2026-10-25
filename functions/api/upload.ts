interface Env {
  MEDIA_BUCKET: R2Bucket;
  SUPABASE_URL?: string;
  SUPABASE_ANON_KEY?: string;
}

const R2_PUBLIC_BASE_URL = 'https://pub-2969918b7c1b48209c4865c154b4e51d.r2.dev';

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Requested-With',
  'Access-Control-Max-Age': '86400',
};

function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...CORS_HEADERS,
      'Content-Type': 'application/json',
    },
  });
}

export const onRequestOptions: PagesFunction<Env> = async () => {
  return new Response(null, {
    status: 204,
    headers: CORS_HEADERS,
  });
};

export const onRequestPost: PagesFunction<Env> = async (context) => {
  const { request, env } = context;

  try {
    const url = new URL(request.url);
    const path = url.searchParams.get('path');

    if (!path || path.trim().length === 0) {
      return jsonResponse({ error: 'Parametar "path" je obavezan.' }, 400);
    }

    // Zaštita od path traversal napada
    const cleanPath = path.trim().replace(/^\/+/, '').replace(/\.\.\//g, '');
    if (!cleanPath) {
      return jsonResponse({ error: 'Nevažeća putanja.' }, 400);
    }

    if (!env.MEDIA_BUCKET) {
      return jsonResponse(
        { error: 'R2 binding MEDIA_BUCKET nije konfigurisan na Cloudflare Pages.' },
        500
      );
    }

    const contentType =
      request.headers.get('Content-Type') || 'application/octet-stream';

    if (!request.body) {
      return jsonResponse({ error: 'Nedostaje telo zahteva (fajl).' }, 400);
    }

    // Direktan striming iz request body-ja u Cloudflare R2
    await env.MEDIA_BUCKET.put(cleanPath, request.body, {
      httpMetadata: {
        contentType,
        cacheControl: 'public, max-age=31536000, immutable',
      },
    });

    const publicUrl = `${R2_PUBLIC_BASE_URL}/${cleanPath}`;

    return jsonResponse({
      success: true,
      path: cleanPath,
      url: publicUrl,
    });
  } catch (error: any) {
    console.error('Greška pri uploadu na R2:', error);
    return jsonResponse(
      { error: 'Greška pri čuvanju fajla na R2.', details: error?.message },
      500
    );
  }
};

export const onRequestDelete: PagesFunction<Env> = async (context) => {
  const { request, env } = context;

  try {
    const url = new URL(request.url);
    const path = url.searchParams.get('path');

    if (!path || path.trim().length === 0) {
      return jsonResponse({ error: 'Parametar "path" je obavezan.' }, 400);
    }

    const cleanPath = path.trim().replace(/^\/+/, '').replace(/\.\.\//g, '');

    if (!env.MEDIA_BUCKET) {
      return jsonResponse(
        { error: 'R2 binding MEDIA_BUCKET nije konfigurisan.' },
        500
      );
    }

    await env.MEDIA_BUCKET.delete(cleanPath);

    return jsonResponse({
      success: true,
      deletedPath: cleanPath,
    });
  } catch (error: any) {
    console.error('Greška pri brisanju sa R2:', error);
    return jsonResponse(
      { error: 'Greška pri brisanju fajla.', details: error?.message },
      500
    );
  }
};
