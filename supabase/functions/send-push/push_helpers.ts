// ─── Čisti helperi za send-push Edge funkciju ───────────────────────────────
// Izdvojeno iz index.ts radi unit-testiranja (deno test) bez pokretanja
// servera i bez pristupa environmentu. Sve funkcije ovde su determinističke
// i nemaju spoljne zavisnosti.

/** Podržani nivoi logovanja (redosled raste po ozbiljnosti). */
export const LOG_LEVELS = ["debug", "info", "warn", "error"] as const
export type LogLevel = (typeof LOG_LEVELS)[number]

/**
 * Normalizuje sirovu vrednost env promenljive `LOG_LEVEL` u validan nivo.
 * Podrazumevano "info"; neprepoznate vrednosti se sigurno spuštaju na "info".
 */
export function resolveLogLevel(
  raw: string | undefined | null,
): LogLevel {
  const normalized = (raw ?? "info").trim().toLowerCase()
  return (LOG_LEVELS as readonly string[]).includes(normalized)
    ? (normalized as LogLevel)
    : "info"
}

/**
 * Da li je poruka nivoa [level] vidljiva kada je trenutni prag [current].
 * Npr. uz prag "warn" se vide samo "warn" i "error".
 */
export function isLogLevelEnabled(
  level: LogLevel,
  current: LogLevel,
): boolean {
  return LOG_LEVELS.indexOf(level) >= LOG_LEVELS.indexOf(current)
}

/**
 * Skraćen, ne-reverzibilan prikaz identifikatora za logove (bez curenja punog
 * UUID). Ne koristi se za poređenje — samo za human-readable dijagnostiku.
 */
export function shortId(id: string | undefined | null): string {
  if (!id) return "(nepoznato)"
  return `${id.slice(0, 8)}…`
}

/**
 * Skraćuje sadržaj poruke radi logovanja (ne menja stvarni payload).
 * PII (sadržaj poruka) se ne loguje u celosti u produkciji.
 */
export function redactText(
  text: string | undefined | null,
  maxLen = 30,
): string {
  if (!text) return ""
  const trimmed = (text || "").trim()
  return trimmed.length <= maxLen ? trimmed : `${trimmed.slice(0, maxLen)}…`
}

/**
 * Priprema body tekst za lockscreen notifikaciju: normalizuje razmake i
 * seče na najviše [maxLen] karaktera — po mogućstvu na granici reči,
 * ali nikada ne ostavlja "patuljastu" prvu reč (granica je ~24 karaktera).
 */
export function getLockscreenBody(input: string, maxLen = 88): string {
  const trimmed = (input || "").replace(/\s+/g, " ").trim()
  if (trimmed.length <= maxLen) return trimmed
  const cut = trimmed.slice(0, maxLen)
  const lastSpace = cut.lastIndexOf(" ")
  const safe = lastSpace > 24 ? cut.slice(0, lastSpace) : cut
  return safe.trimEnd() + "..."
}

/**
 * Gradi CORS zaglavlja za send-push Edge funkciju.
 * Za nedozvoljene ili prazne Origin vrednosti ne emituje Access-Control-Allow-Origin
 * umesto fallback-a na prvi dozvoljeni domen.
 */
export function buildCorsHeaders(
  origin: string | null | undefined,
  allowedOrigins: readonly string[],
): Record<string, string> {
  const trimmedOrigin = (origin ?? "").trim()
  const headers: Record<string, string> = {
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Vary": "Origin",
  }
  if (trimmedOrigin && allowedOrigins.includes(trimmedOrigin)) {
    headers["Access-Control-Allow-Origin"] = trimmedOrigin
  }
  return headers
}

/**
 * Odlučuje da li FCM greška znači da je sam push token trajno nevažeći.
 * Za HTTP 400 (`INVALID_ARGUMENT`) briše token isključivo ako poruka eksplicitno
 * ukazuje na problem sa registration token-om — payload greške ne smeju da obrišu
 * važeće korisničke tokene.
 */
export function shouldDeletePushToken(status: number, errorBody: string): boolean {
  if (status === 404) return true
  let parsed: {
    error?: {
      status?: unknown
      message?: unknown
      details?: Array<{ errorCode?: unknown }>
    }
  } | null = null
  try {
    parsed = JSON.parse(errorBody)
  } catch {
    return false
  }
  const errorStatus = parsed?.error?.status
  const errorCode = parsed?.error?.details?.[0]?.errorCode
  const errorMessage = typeof parsed?.error?.message === "string"
    ? parsed.error.message.toLowerCase()
    : ""

  if (errorStatus === "NOT_FOUND" || errorCode === "UNREGISTERED") {
    return true
  }
  if (errorCode === "INVALID_ARGUMENT" || status === 400) {
    return errorMessage.includes("registration token")
  }
  return false
}

export type AuthEvaluationResult =
  | { ok: true; isSystemOrAdmin: boolean; callerUid: string | null }
  | { ok: false; status: number; error: string; logMessage: string }

/**
 * Izvlači Bearer token iz Authorization zaglavlja (case-insensitive).
 */
export function extractBearerToken(
  authHeader: string | null | undefined,
): string | null {
  if (!authHeader) return null
  if (!authHeader.toLowerCase().startsWith("bearer ")) return null
  const token = authHeader.slice(7).trim()
  return token.length > 0 ? token : null
}

/**
 * Evaluira dekodirane JWT claim-ove i određuje autorizaciju za slanje push-a.
 * Dozvoljava `service_role`, administratore i `authenticated` korisnike sa validnim `sub`.
 */
export function evaluateJwtClaims(
  payload: Record<string, unknown>,
): AuthEvaluationResult {
  const role = payload.role
  if (role === "service_role") {
    return { ok: true, isSystemOrAdmin: true, callerUid: null }
  }
  if (role === "authenticated") {
    const callerUid = typeof payload.sub === "string" && payload.sub.length > 0
      ? payload.sub
      : null
    const appMeta =
      typeof payload.app_metadata === "object" && payload.app_metadata !== null
        ? (payload.app_metadata as Record<string, unknown>)
        : null
    const isAdmin = payload.is_admin === true || appMeta?.is_admin === true
    if (isAdmin) {
      return { ok: true, isSystemOrAdmin: true, callerUid }
    }
    if (callerUid) {
      return { ok: true, isSystemOrAdmin: false, callerUid }
    }
    return {
      ok: false,
      status: 401,
      error: "Unauthorized: invalid user claim",
      logMessage: "FCM: Odbijen zahtev - authenticated JWT bez validnog sub claim-a",
    }
  }
  return {
    ok: false,
    status: 403,
    error: "Forbidden: insufficient permissions",
    logMessage:
      `FCM: Neovlašćen pristup sa role '${String(role)}' umesto 'service_role' ili 'authenticated'`,
  }
}

/**
 * Verifikuje dolazni Authorization header protiv service_role ključa ili JWT potpisa.
 */
export async function authorizePushRequest(params: {
  authHeader: string | null | undefined
  expectedServiceKey?: string | null
  jwtSecret?: string | null
  verifyJwt: (token: string, secret: string) => Promise<Record<string, unknown>>
}): Promise<AuthEvaluationResult> {
  const token = extractBearerToken(params.authHeader)
  if (!token) {
    return {
      ok: false,
      status: 401,
      error: "Missing or invalid authorization header",
      logMessage: "FCM: Odbijen zahtev - nedostaje Authorization header",
    }
  }

  if (params.expectedServiceKey && token === params.expectedServiceKey) {
    return { ok: true, isSystemOrAdmin: true, callerUid: null }
  }

  if (!params.jwtSecret) {
    return {
      ok: false,
      status: 401,
      error: "Unauthorized: Signature verification required",
      logMessage:
        "FCM: Odbijen zahtev - token se ne poklapa sa service_role_key a SUPABASE_JWT_SECRET nije konfigurisan.",
    }
  }

  try {
    const payload = await params.verifyJwt(token, params.jwtSecret)
    return evaluateJwtClaims(payload)
  } catch (verifyErr) {
    return {
      ok: false,
      status: 401,
      error: "Invalid authorization token signature",
      logMessage: `FCM: Odbijen zahtev - nevalidan JWT potpis: ${String(verifyErr)}`,
    }
  }
}

export function personalizeNotificationTitle(
  rawTitle: unknown,
  type: string,
): string {
  const titleStr = typeof rawTitle === "string" ? rawTitle : ""
  if (!titleStr || titleStr === "Obaveštenje" || titleStr === "Notification") {
    if (type === "new_order") return "Nova porudžbina 🛒"
    if (type === "order_status" || type === "order_status_changed") {
      return "Status porudžbine 📦"
    }
    if (type === "new_message") return "Nova poruka 💬"
    if (type === "new_review" || type === "new_buyer_review") {
      return "Nova recenzija ⭐"
    }
    return titleStr || "Obaveštenje"
  }
  return titleStr
}

export type ParsedPushRequest =
  | {
    ok: true
    userId: string
    title: string
    bodyText: string
    type: string
    fcmData: Record<string, string>
    isTriggerRecord: boolean
  }
  | {
    ok: false
    status: number
    error: string
    reason: "missing_body" | "missing_user_id"
    keys?: string[]
  }

/**
 * Validira i normalizuje zahtev za push notifikaciju (podržava i trigger `body.record`
 * i direktan poziv).
 */
export function parsePushNotificationRequest(body: unknown): ParsedPushRequest {
  if (!body || typeof body !== "object" || Array.isArray(body)) {
    return {
      ok: false,
      status: 400,
      error: "Request body is required",
      reason: "missing_body",
    }
  }

  const root = body as Record<string, unknown>
  const recordObj =
    root.record && typeof root.record === "object" && !Array.isArray(root.record)
      ? (root.record as Record<string, unknown>)
      : null
  const src = recordObj ?? root

  const rawUserId = typeof src.user_id === "string" ? src.user_id.trim() : ""
  if (!rawUserId) {
    return {
      ok: false,
      status: 400,
      error: "user_id required",
      reason: "missing_user_id",
      keys: Object.keys(root),
    }
  }

  const type = typeof src.type === "string" ? src.type : ""
  const title = personalizeNotificationTitle(src.title, type)
  const bodyText = src.body == null ? "" : String(src.body)

  const fcmData: Record<string, string> = {
    type,
    notification_id: String(
      recordObj ? (src.id ?? "") : (src.notification_id ?? src.id ?? ""),
    ),
    created_at: String(src.created_at ?? ""),
    order_id: String(src.order_id ?? ""),
    conversation_id: String(src.conversation_id ?? ""),
    ticket_id: String(src.ticket_id ?? ""),
    classified_ad_id: String(src.classified_ad_id ?? ""),
  }
  if (src.route) {
    fcmData.route = String(src.route)
  }

  if (!recordObj && root.data && typeof root.data === "object" && !Array.isArray(root.data)) {
    for (const [k, v] of Object.entries(root.data as Record<string, unknown>)) {
      if (v != null && !fcmData[k]) {
        fcmData[k] = String(v)
      }
    }
  }

  return {
    ok: true,
    userId: rawUserId,
    title,
    bodyText,
    type,
    fcmData,
    isTriggerRecord: recordObj !== null,
  }
}

/**
 * Proverava da li pozivalac sme da pošalje push zadatom `targetUserId` korisniku.
 */
export function canSendPushToTarget(params: {
  isSystemOrAdmin: boolean
  callerUid: string | null
  targetUserId: string
}): boolean {
  if (params.isSystemOrAdmin) return true
  return Boolean(params.callerUid) && params.callerUid === params.targetUserId
}

/**
 * Uklanja duplikate push tokena čuvajući poslednju platformu (podrazumevano "android").
 */
export function dedupePushTokens(
  rows: ReadonlyArray<{ token?: string | null; platform?: string | null }>,
): Array<{ token: string; platform: string }> {
  const uniqueMap = new Map<string, string>()
  for (const row of rows) {
    if (row.token) {
      uniqueMap.set(row.token, row.platform || "android")
    }
  }
  return Array.from(uniqueMap.entries()).map(([token, platform]) => ({
    token,
    platform,
  }))
}

/**
 * Sklapa FCM HTTP v1 payload za Android ili iOS uređaj.
 */
export function buildFcmMessagePayload(params: {
  token: string
  platform?: string | null
  title: string
  lockscreenBody: string
  bodyText: string
  fcmData: Record<string, string>
}): Record<string, unknown> {
  const platform = params.platform || "android"
  const message: Record<string, unknown> = {
    token: params.token,
    data: { ...params.fcmData, title: params.title, body: params.bodyText },
  }

  if (platform === "ios") {
    message.notification = { title: params.title, body: params.lockscreenBody }
    message.apns = {
      headers: { "apns-priority": "10" },
      payload: {
        aps: {
          alert: { title: params.title, body: params.lockscreenBody },
          sound: "default",
          badge: 1,
        },
      },
    }
    return message
  }

  const isOrder =
    params.fcmData.type === "new_order" ||
    params.fcmData.type === "order_status" ||
    params.fcmData.type === "order_status_changed"
  const channelId = isOrder ? "orders_high_v2" : "mleko_urgent_v2"

  message.android = {
    priority: "HIGH",
    ttl: "86400s",
    notification: {
      channel_id: channelId,
      title: params.title,
      body: params.lockscreenBody,
      sound: "default",
      default_vibrate_timings: true,
      default_sound: true,
      visibility: "PUBLIC",
      notification_priority: "PRIORITY_HIGH",
      icon: "ic_notification",
      color: "#1B5E20",
    },
  }
  return message
}
