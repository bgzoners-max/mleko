declare const process: { env?: Record<string, string | undefined> } | undefined;

export interface MediaBucketPutOptions {
  httpMetadata?: {
    contentType?: string;
    cacheControl?: string;
  };
}

export interface MediaBucket {
  put(
    key: string,
    value: ReadableStream<Uint8Array> | ArrayBuffer | ArrayBufferView | string | Blob | null,
    options?: MediaBucketPutOptions,
  ): Promise<unknown>;
  delete(keys: string | string[]): Promise<void>;
}

export interface UploadEnv {
  MEDIA_BUCKET?: MediaBucket;
  SUPABASE_URL?: string;
  SUPABASE_ANON_KEY?: string;
}

export interface UploadContext {
  request: Request;
  env: UploadEnv;
}

export interface UploadDependencies {
  fetchImpl?: typeof fetch;
}

interface VerifiedUser {
  id: string;
  is_anonymous?: boolean;
  app_metadata?: {
    provider?: string;
  };
}

export const MAX_UPLOAD_BYTES = 10 * 1024 * 1024; // 10 MB

const R2_PUBLIC_BASE_URL = 'https://pub-2969918b7c1b48209c4865c154b4e51d.r2.dev';

const ALLOWED_BUCKETS = new Set([
  'profiles',
  'product-images',
  'farm-gallery',
]);

const ALLOWED_MIME_TYPES = new Set([
  'image/jpeg',
  'image/png',
  'image/webp',
]);

const EXACT_ALLOWED_ORIGINS = new Set([
  'https://www.domacimarket.rs',
  'https://domacimarket.rs',
  'https://staging.domacimarket.rs',
  'https://domacimarket.pages.dev',
]);

const UUID_REGEX =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const SAFE_SEGMENT_REGEX = /^[A-Za-z0-9._-]+$/;
const SAFE_PROFILE_FILE_REGEX = /^[A-Za-z0-9_-]+\.(jpg|jpeg|png|webp)$/i;

export function isAllowedOrigin(origin: string): boolean {
  const clean = origin.trim().replace(/\/+$/, '');
  if (EXACT_ALLOWED_ORIGINS.has(clean)) {
    return true;
  }
  if (/^https:\/\/[a-z0-9-]+\.domacimarket\.pages\.dev$/i.test(clean)) {
    return true;
  }
  if (/^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/i.test(clean)) {
    return true;
  }
  return false;
}

function buildCorsHeaders(originHeader: string | null): {
  allowed: boolean;
  headers: Record<string, string>;
} {
  const baseHeaders: Record<string, string> = {
    Vary: 'Origin',
    'Access-Control-Allow-Methods': 'POST, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Requested-With',
    'Access-Control-Max-Age': '86400',
  };

  if (!originHeader || originHeader.trim().length === 0) {
    return { allowed: true, headers: baseHeaders };
  }

  const normalized = originHeader.trim().replace(/\/+$/, '');
  if (!isAllowedOrigin(normalized)) {
    return { allowed: false, headers: { Vary: 'Origin' } };
  }

  return {
    allowed: true,
    headers: {
      ...baseHeaders,
      'Access-Control-Allow-Origin': normalized,
    },
  };
}

function jsonResponse(
  data: unknown,
  status = 200,
  corsHeaders: Record<string, string> = {},
): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
}

function normalizeMimeType(rawHeader: string | null): string {
  if (!rawHeader) return '';
  return rawHeader.split(';')[0].trim().toLowerCase();
}

export function matchesAllowedImageMagicBytes(bytes: Uint8Array): boolean {
  if (bytes.length < 12) {
    // Minimalna provera za izuzetno male validne slike nije problem; odbaci sve < 4 bajta
    if (bytes.length < 4) return false;
  }
  // JPEG: FF D8 FF
  if (bytes.length >= 3 && bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff) {
    return true;
  }
  // PNG: 89 50 4E 47 0D 0A 1A 0A
  if (
    bytes.length >= 8 &&
    bytes[0] === 0x89 &&
    bytes[1] === 0x50 &&
    bytes[2] === 0x4e &&
    bytes[3] === 0x47 &&
    bytes[4] === 0x0d &&
    bytes[5] === 0x0a &&
    bytes[6] === 0x1a &&
    bytes[7] === 0x0a
  ) {
    return true;
  }
  // WebP: RIFF....WEBP
  if (
    bytes.length >= 12 &&
    bytes[0] === 0x52 &&
    bytes[1] === 0x49 &&
    bytes[2] === 0x46 &&
    bytes[3] === 0x46 &&
    bytes[8] === 0x57 &&
    bytes[9] === 0x45 &&
    bytes[10] === 0x42 &&
    bytes[11] === 0x50
  ) {
    return true;
  }
  return false;
}

export function validateAndSanitizeMediaPath(
  rawPath: string | null,
  userId: string,
): { ok: true; cleanPath: string } | { ok: false; status: number; error: string } {
  if (!rawPath || rawPath.trim().length === 0) {
    return { ok: false, status: 400, error: 'Parametar "path" je obavezan.' };
  }

  const trimmed = rawPath.trim();
  if (trimmed.includes('\\') || trimmed.includes('\0')) {
    return { ok: false, status: 400, error: 'Nevažeća putanja.' };
  }

  const withoutLeadingSlash = trimmed.replace(/^\/+/, '');
  if (!withoutLeadingSlash || withoutLeadingSlash.endsWith('/')) {
    return { ok: false, status: 400, error: 'Nevažeća putanja.' };
  }

  const segments = withoutLeadingSlash.split('/');
  for (const seg of segments) {
    if (
      !seg ||
      seg === '.' ||
      seg === '..' ||
      seg.startsWith('.') ||
      seg.includes('..') ||
      !SAFE_SEGMENT_REGEX.test(seg)
    ) {
      return { ok: false, status: 400, error: 'Nevažeća putanja.' };
    }
  }

  const bucket = segments[0];
  if (!ALLOWED_BUCKETS.has(bucket)) {
    return { ok: false, status: 400, error: 'Nedozvoljen storage bucket.' };
  }

  const normalizedUserId = userId.toLowerCase();

  if (bucket === 'profiles') {
    if (segments.length === 2) {
      const fileSegment = segments[1];
      if (!SAFE_PROFILE_FILE_REGEX.test(fileSegment)) {
        return { ok: false, status: 400, error: 'Nevažeći naziv profilne slike.' };
      }
      const ownerPrefix = `${normalizedUserId}.`;
      if (!fileSegment.toLowerCase().startsWith(ownerPrefix)) {
        return {
          ok: false,
          status: 403,
          error: 'Nemate dozvolu za izmenu tuđe profilne slike.',
        };
      }
      return { ok: true, cleanPath: segments.join('/') };
    }

    if (segments.length >= 3) {
      if (segments[1].toLowerCase() !== normalizedUserId) {
        return {
          ok: false,
          status: 403,
          error: 'Nemate dozvolu za pristup ovoj putanji.',
        };
      }
      return { ok: true, cleanPath: segments.join('/') };
    }

    return { ok: false, status: 400, error: 'Nevažeća putanja za profilnu sliku.' };
  }

  // product-images i farm-gallery zahtevaju format <bucket>/<userId>/<file...>
  if (segments.length < 3) {
    return { ok: false, status: 400, error: 'Putanja mora sadržati korisnički direktorijum i naziv fajla.' };
  }

  if (segments[1].toLowerCase() !== normalizedUserId) {
    return {
      ok: false,
      status: 403,
      error: 'Nemate dozvolu za upis ili brisanje tuđih fajlova.',
    };
  }

  return { ok: true, cleanPath: segments.join('/') };
}

function resolveSupabaseConfig(env: UploadEnv): {
  supabaseUrl?: string;
  supabaseAnonKey?: string;
} {
  const procEnv = typeof process !== 'undefined' ? process?.env : undefined;
  const supabaseUrl =
    env.SUPABASE_URL || procEnv?.SUPABASE_URL || procEnv?.NEXT_PUBLIC_SUPABASE_URL;
  const supabaseAnonKey =
    env.SUPABASE_ANON_KEY ||
    procEnv?.SUPABASE_ANON_KEY ||
    procEnv?.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  return { supabaseUrl, supabaseAnonKey };
}

async function authenticateRequest(
  request: Request,
  env: UploadEnv,
  fetchImpl: typeof fetch,
): Promise<
  | { ok: true; user: VerifiedUser }
  | { ok: false; status: number; error: string }
> {
  const authHeader = request.headers.get('Authorization');
  if (!authHeader || !/^Bearer\s+/i.test(authHeader)) {
    return {
      ok: false,
      status: 401,
      error: 'Nedostaje Authorization Bearer token.',
    };
  }

  const token = authHeader.replace(/^Bearer\s+/i, '').trim();
  if (!token) {
    return {
      ok: false,
      status: 401,
      error: 'Nevažeći Authorization Bearer token.',
    };
  }

  const { supabaseUrl, supabaseAnonKey } = resolveSupabaseConfig(env);
  if (!supabaseUrl || !supabaseAnonKey) {
    return {
      ok: false,
      status: 500,
      error: 'Supabase autentifikacija nije konfigurisana na serveru.',
    };
  }

  const baseUrl = supabaseUrl.replace(/\/+$/, '');
  const authRes = await fetchImpl(`${baseUrl}/auth/v1/user`, {
    method: 'GET',
    headers: {
      Authorization: `Bearer ${token}`,
      apikey: supabaseAnonKey,
    },
  });

  if (!authRes.ok) {
    return {
      ok: false,
      status: 401,
      error: 'Sesija je istekla ili token nije validan.',
    };
  }

  const user = (await authRes.json()) as VerifiedUser | null;
  if (!user || typeof user.id !== 'string' || !UUID_REGEX.test(user.id)) {
    return {
      ok: false,
      status: 401,
      error: 'Nevažeći korisnički identitet.',
    };
  }

  if (
    user.is_anonymous === true ||
    user.app_metadata?.provider === 'anonymous'
  ) {
    return {
      ok: false,
      status: 403,
      error: 'Gost nalozi nemaju dozvolu za otpremanje ili brisanje fajlova.',
    };
  }

  return { ok: true, user };
}

async function readBodyWithinLimit(
  body: ReadableStream<Uint8Array>,
  maxBytes: number,
): Promise<
  | { ok: true; bytes: Uint8Array }
  | { ok: false; status: number; error: string }
> {
  const reader = body.getReader();
  const chunks: Uint8Array[] = [];
  let totalBytes = 0;

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    if (!value || value.byteLength === 0) continue;

    totalBytes += value.byteLength;
    if (totalBytes > maxBytes) {
      try {
        await reader.cancel();
      } catch {
        // Ignoriši grešku pri prekidu strima
      }
      return {
        ok: false,
        status: 413,
        error: 'Fajl premašuje maksimalnu dozvoljenu veličinu (10 MB).',
      };
    }
    chunks.push(value);
  }

  if (totalBytes === 0) {
    return {
      ok: false,
      status: 400,
      error: 'Telo zahteva ne sme biti prazno.',
    };
  }

  const combined = new Uint8Array(totalBytes);
  let offset = 0;
  for (const chunk of chunks) {
    combined.set(chunk, offset);
    offset += chunk.byteLength;
  }

  return { ok: true, bytes: combined };
}

export async function handleUploadRequest(
  request: Request,
  env: UploadEnv,
  deps: UploadDependencies = {},
): Promise<Response> {
  const fetchImpl = deps.fetchImpl ?? fetch;
  const cors = buildCorsHeaders(request.headers.get('Origin'));

  if (!cors.allowed) {
    return jsonResponse(
      { error: 'Origin nije dozvoljen.' },
      403,
      cors.headers,
    );
  }

  if (request.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: cors.headers,
    });
  }

  if (request.method !== 'POST' && request.method !== 'DELETE') {
    return jsonResponse(
      { error: 'Metoda nije podržana.' },
      405,
      cors.headers,
    );
  }

  try {
    const authResult = await authenticateRequest(request, env, fetchImpl);
    if (!authResult.ok) {
      return jsonResponse(
        { error: authResult.error },
        authResult.status,
        cors.headers,
      );
    }

    const url = new URL(request.url);
    const pathCheck = validateAndSanitizeMediaPath(
      url.searchParams.get('path'),
      authResult.user.id,
    );
    if (!pathCheck.ok) {
      return jsonResponse(
        { error: pathCheck.error },
        pathCheck.status,
        cors.headers,
      );
    }

    if (!env.MEDIA_BUCKET) {
      return jsonResponse(
        {
          error:
            request.method === 'POST'
              ? 'R2 binding MEDIA_BUCKET nije konfigurisan na Cloudflare Pages.'
              : 'R2 binding MEDIA_BUCKET nije konfigurisan.',
        },
        500,
        cors.headers,
      );
    }

    const cleanPath = pathCheck.cleanPath;

    if (request.method === 'DELETE') {
      await env.MEDIA_BUCKET.delete(cleanPath);
      return jsonResponse(
        {
          success: true,
          deletedPath: cleanPath,
        },
        200,
        cors.headers,
      );
    }

    // POST validation: Content-Type, Content-Length, bounded body read, image magic bytes
    const contentType = normalizeMimeType(request.headers.get('Content-Type'));
    if (!ALLOWED_MIME_TYPES.has(contentType)) {
      return jsonResponse(
        {
          error:
            'Nedozvoljen tip fajla. Dozvoljene su samo JPEG, PNG i WebP slike.',
        },
        415,
        cors.headers,
      );
    }

    const contentLengthHeader = request.headers.get('Content-Length');
    if (contentLengthHeader !== null) {
      const parsedLength = Number(contentLengthHeader);
      if (!Number.isFinite(parsedLength) || parsedLength < 0) {
        return jsonResponse(
          { error: 'Nevažeća vrednost zaglavlja Content-Length.' },
          400,
          cors.headers,
        );
      }
      if (parsedLength > MAX_UPLOAD_BYTES) {
        return jsonResponse(
          { error: 'Fajl premašuje maksimalnu dozvoljenu veličinu (10 MB).' },
          413,
          cors.headers,
        );
      }
    }

    if (!request.body) {
      return jsonResponse(
        { error: 'Nedostaje telo zahteva (fajl).' },
        400,
        cors.headers,
      );
    }

    const bodyResult = await readBodyWithinLimit(request.body, MAX_UPLOAD_BYTES);
    if (!bodyResult.ok) {
      return jsonResponse(
        { error: bodyResult.error },
        bodyResult.status,
        cors.headers,
      );
    }

    if (!matchesAllowedImageMagicBytes(bodyResult.bytes)) {
      return jsonResponse(
        { error: 'Sadržaj fajla ne odgovara validnoj JPEG, PNG ili WebP slici.' },
        415,
        cors.headers,
      );
    }

    await env.MEDIA_BUCKET.put(cleanPath, bodyResult.bytes.buffer as ArrayBuffer, {
      httpMetadata: {
        contentType,
        cacheControl: 'public, max-age=31536000, immutable',
      },
    });

    const publicUrl = `${R2_PUBLIC_BASE_URL}/${cleanPath}`;

    return jsonResponse(
      {
        success: true,
        path: cleanPath,
        url: publicUrl,
      },
      200,
      cors.headers,
    );
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Nepoznata greška';
    console.error('Greška pri obradi zahteva za medije:', error);
    return jsonResponse(
      { error: 'Greška pri obradi fajla na serveru.', details: message },
      500,
      cors.headers,
    );
  }
}

export async function onRequestOptions(context: UploadContext): Promise<Response> {
  return handleUploadRequest(context.request, context.env);
}

export async function onRequestPost(context: UploadContext): Promise<Response> {
  return handleUploadRequest(context.request, context.env);
}

export async function onRequestDelete(context: UploadContext): Promise<Response> {
  return handleUploadRequest(context.request, context.env);
}
