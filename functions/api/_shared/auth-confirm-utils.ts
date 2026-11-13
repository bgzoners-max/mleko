// Pure helpers za /api/auth-confirm preusmeravanje (deljeno sa Deno testovima).

export function sanitizeNextPath(
  rawNext: string | null | undefined,
  fallback = "/auth/confirmed",
): string {
  const trimmed = (rawNext ?? "").trim();
  if (!trimmed) return fallback;
  // Odbaci eksplicitne URL sheme (https:, javascript:, data:) pre dodavanja '/'
  if (/^[a-zA-Z][a-zA-Z0-9+.-]*:/.test(trimmed)) {
    return fallback;
  }
  const candidate = trimmed.startsWith("/") ? trimmed : `/${trimmed}`;
  if (
    candidate.startsWith("//") ||
    candidate.startsWith("/\\") ||
    candidate.includes("\\") ||
    candidate.includes("#") ||
    /[\u0000-\u001F\u007F]/.test(candidate)
  ) {
    return fallback;
  }
  return candidate;
}

export function buildAuthConfirmRedirectUrl(
  publicBaseUrl: string,
  next: string | null | undefined,
  session:
    | {
        access_token: string;
        refresh_token: string;
        expires_in: number;
      }
    | null
    | undefined,
  type: string,
): string {
  const cleanNext = sanitizeNextPath(next);
  if (!session) {
    return `${publicBaseUrl}/#${cleanNext}`;
  }
  const params = new URLSearchParams({
    access_token: session.access_token,
    refresh_token: session.refresh_token,
    expires_in: String(session.expires_in),
    token_type: "bearer",
    type,
  });
  // Jedan '#' za GoRouter hash strategiju + '?verified=1&...' kako bi gotrue
  // getSessionFromUrl uredno parsirao tokene u fragmentu bez slanja serveru.
  const sep = cleanNext.includes("?") ? "&" : "?verified=1&";
  return `${publicBaseUrl}/#${cleanNext}${sep}${params.toString()}`;
}

