// Push notifikacije – FCM HTTP v1 API (Legacy je ugašen od jula 2024)
import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import * as jose from "https://deno.land/x/jose@v5.2.0/index.ts"
import type { Database, Json } from "../../types/database.types.ts"
import {
  authorizePushRequest,
  buildCorsHeaders,
  buildFcmMessagePayload,
  canSendPushToTarget,
  dedupePushTokens,
  getLockscreenBody,
  isLogLevelEnabled,
  parsePushNotificationRequest,
  redactText,
  resolveLogLevel,
  shortId,
  shouldDeletePushToken,
  type LogLevel,
} from "./push_helpers.ts"

// Dozvoljeni domeni za CORS (ograniči attack surface)
const PROD_ALLOWED_ORIGINS = [
  "https://domacimarket.rs",
  "https://www.domacimarket.rs",
  "https://staging.domacimarket.rs",
]

// Dozvoli lokalne adrese samo u development okruženju
const isDev = (Deno.env.get("ENVIRONMENT") || "").toLowerCase() === "development" ||
  (Deno.env.get("DENO_ENV") || "").toLowerCase() === "development" ||
  Deno.env.get("ALLOW_LOCAL_CORS") === "true"

const ALLOWED_ORIGINS = isDev
  ? [...PROD_ALLOWED_ORIGINS, "http://localhost:3000", "http://localhost:8080"]
  : PROD_ALLOWED_ORIGINS


function getCorsHeaders(req: Request): Record<string, string> {
  return buildCorsHeaders(req.headers.get("origin"), ALLOWED_ORIGINS)
}

// Cache za FCM access token – izbegava skupu JWT generisanje
interface TokenCache {
  token: string
  expiresAt: number // milliseconds
}

const tokenCache = new Map<string, TokenCache>() // Key: project_id

// ─── Logging ───────────────────────────────────────────────────────────────
// Centralizovano logovanje sa nivom (env LOG_LEVEL: debug|info|warn|error).
// Podrazumevano "info". U produkciji se PII (user_id, sadržaj poruke) NE loguje
// sirovo — koriste se kratki, deterministički prefiksi radi debugging-a.
const LOG_LEVEL = resolveLogLevel(Deno.env.get("LOG_LEVEL"))

function logLevelEnabled(level: LogLevel): boolean {
  return isLogLevelEnabled(level, LOG_LEVEL)
}

// shortId/redactText/getLockscreenBody su izdvojeni u push_helpers.ts radi
// unit-testiranja (deno test push_helpers.test.ts) — uvoz je na vrhu fajla.

function log(level: LogLevel, message: string, data?: unknown) {
  if (!logLevelEnabled(level)) return
  const line = data === undefined ? message : `${message} ${JSON.stringify(data)}`
  if (level === "error") console.error(line)
  else if (level === "warn") console.warn(line)
  else console.log(line)
}

async function getAccessToken(sa: any): Promise<string> {
  const projectId = sa.project_id
  // Prvo proveri cache
  const cached = tokenCache.get(projectId)
  if (cached && Date.now() < cached.expiresAt) {
    log("debug", "FCM: Korišćen cached token za", { projectId })
    return cached.token
  }

  // Generisanje novog token-a ako cache nije validan
  log("debug", "FCM: Generiši novi token za", { projectId })
  
  // Fix literal \n in private key
  const privateKey = sa.private_key.includes('\n') 
    ? sa.private_key 
    : sa.private_key.replace(/\\n/g, '\n')
    
  const key = await jose.importPKCS8(privateKey, "RS256")
  const jwt = await new jose.SignJWT({ scope: "https://www.googleapis.com/auth/firebase.messaging" })
    .setProtectedHeader({ alg: "RS256" })
    .setIssuer(sa.client_email)
    .setSubject(sa.client_email)
    .setAudience("https://oauth2.googleapis.com/token")
    .setIssuedAt()
    .setExpirationTime("5m") // 5 minuta je dovoljno za razmenu
    .sign(key)

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  })
  const data = await res.json()
  if (data.error) throw new Error(data.error_description ?? data.error)

  const accessToken = data.access_token
  const expiresIn = data.expires_in || 3600 // Default 1 hour

  // Cache token sa 5 minuta margine
  const expiresAt = Date.now() + (expiresIn - 300) * 1000
  tokenCache.set(projectId, { token: accessToken, expiresAt })

  log("debug", "FCM: Token cache-ovan", { expiresInMin: Math.round((expiresAt - Date.now()) / 60000) })
  return accessToken
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: getCorsHeaders(req) })
  }

  // S2 Security Fix: Zahtevaj kriptografski verifikovanu 'service_role', admin ili self-send JWT autorizaciju.
  const authResult = await authorizePushRequest({
    authHeader: req.headers.get("Authorization") ?? req.headers.get("authorization"),
    expectedServiceKey: Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"),
    jwtSecret: Deno.env.get("SUPABASE_JWT_SECRET"),
    verifyJwt: async (token, secret) => {
      const secretBytes = new TextEncoder().encode(secret)
      const { payload } = await jose.jwtVerify(token, secretBytes)
      return payload as Record<string, unknown>
    },
  })

  if (!authResult.ok) {
    log("warn", authResult.logMessage)
    return new Response(
      JSON.stringify({ error: authResult.error }),
      { status: authResult.status, headers: { ...getCorsHeaders(req), "Content-Type": "application/json" } }
    )
  }

  const { isSystemOrAdmin, callerUid } = authResult

  try {
    const requestId = crypto.randomUUID()
    const supabase = createClient<Database>(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    )

    const writeDeliveryLog = async (params: {
      userId?: string
      title?: string
      type?: string
      tokenCount?: number
      sentCount?: number
      status: "success" | "partial" | "error" | "no_tokens" | "invalid_request"
      errors?: string[]
      payload?: Record<string, unknown>
    }) => {
      try {
        const failedCount = Math.max((params.tokenCount ?? 0) - (params.sentCount ?? 0), 0)
        const { error: insertErr } = await supabase.from("push_delivery_logs").insert({
          request_id: requestId,
          user_id: params.userId ?? null,
          title: params.title ?? null,
          type: params.type ?? null,
          token_count: params.tokenCount ?? 0,
          sent_count: params.sentCount ?? 0,
          failed_count: failedCount,
          status: params.status,
          errors: (params.errors ?? []) as NonNullable<Json>,
          payload: (params.payload ?? {}) as NonNullable<Json>,
        })
        if (insertErr) {
          log("error", "FCM: upis push_delivery_logs vratio grešku", insertErr.message)
        }
      } catch (logErr) {
        log("error", "FCM: upis push_delivery_logs nije uspeo", String(logErr))
      }
    }

    let body: unknown
    try {
      body = await req.json()
    } catch {
      return new Response(
        JSON.stringify({ error: "Invalid JSON body" }),
        { status: 400, headers: { ...getCorsHeaders(req), "Content-Type": "application/json" } }
      )
    }

    const parsedReq = parsePushNotificationRequest(body)
    if (!parsedReq.ok) {
      if (parsedReq.reason === "missing_user_id") {
        log("error", "FCM: Nedostaje user_id")
        await writeDeliveryLog({
          status: "invalid_request",
          errors: [parsedReq.error],
          payload: { keys: parsedReq.keys ?? [] },
        })
      }
      return new Response(
        JSON.stringify({ error: parsedReq.error }),
        { status: parsedReq.status, headers: { ...getCorsHeaders(req), "Content-Type": "application/json" } }
      )
    }

    const { userId: user_id, title, bodyText, fcmData, isTriggerRecord } = parsedReq

    log("debug", "FCM: Procesuirana notifikacija:", {
      user_id: shortId(user_id),
      title: redactText(title),
      type: fcmData.type,
    })

    // Bezbednosna provera: Običan korisnik sme slati push notifikaciju ISKLJUČIVO sebi (request.auth.uid === user_id)
    if (!canSendPushToTarget({ isSystemOrAdmin, callerUid, targetUserId: user_id })) {
      log("warn", "FCM: Odbijen pokušaj slanja notifikacije drugom korisniku", {
        callerUid: shortId(callerUid),
        targetUserId: shortId(user_id),
      })
      await writeDeliveryLog({
        userId: user_id,
        title,
        type: fcmData.type,
        tokenCount: 0,
        sentCount: 0,
        status: "invalid_request",
        errors: ["Forbidden: cannot send push notifications to other users"],
      })
      return new Response(
        JSON.stringify({ error: "Forbidden: cannot send push notifications to other users" }),
        { status: 403, headers: { ...getCorsHeaders(req), "Content-Type": "application/json" } }
      )
    }

    // Preuzimamo sve tokene, ali filtriramo jedinstvene u memoriji
    // kako bismo izbegli dupliranje ako korisnik ima više instalacija na istom uređaju
    const { data: allTokens, error } = await supabase
      .from("user_push_tokens")
      .select("token, platform")
      .eq("user_id", user_id)

    const tokens = dedupePushTokens(allTokens || [])

    log("debug", "FCM: Pretraga tokena:", {
      user_id: shortId(user_id),
      total_found: allTokens?.length || 0,
      unique_count: tokens.length,
      error: error?.message,
    })

    if (error) {
      log("error", `FCM: Greška pri čitanju tokena za korisnika ${shortId(user_id)}:`, error.message)
      await writeDeliveryLog({
        userId: user_id,
        title,
        type: fcmData.type,
        tokenCount: 0,
        sentCount: 0,
        status: "error",
        errors: [error.message],
        payload: { body_len: bodyText.length },
      })
      return new Response(
        JSON.stringify({ error: "Failed to query push tokens", request_id: requestId }),
        { status: 500, headers: { ...getCorsHeaders(req), "Content-Type": "application/json" } }
      )
    }

    if (!tokens?.length) {
      log("warn", `FCM: Nema tokena za korisnika ${shortId(user_id)}`)
      await writeDeliveryLog({
        userId: user_id,
        title,
        type: fcmData.type,
        tokenCount: 0,
        sentCount: 0,
        status: "no_tokens",
        errors: [],
        payload: { body_len: bodyText.length },
      })
      return new Response(
        JSON.stringify({ message: "No push tokens", sent: 0, token_count: 0 }),
        { status: 200, headers: { ...getCorsHeaders(req), "Content-Type": "application/json" } }
      )
    }

    let serviceAccountJson = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON")
    if (!serviceAccountJson) {
      log("error", "FCM_SERVICE_ACCOUNT_JSON not set")
      await writeDeliveryLog({
        userId: user_id,
        title,
        type: fcmData.type,
        tokenCount: tokens.length,
        sentCount: 0,
        status: "error",
        errors: ["FCM_SERVICE_ACCOUNT_JSON not set"],
      })
      return new Response(
        JSON.stringify({ error: "FCM not configured" }),
        { status: 500, headers: { ...getCorsHeaders(req), "Content-Type": "application/json" } }
      )
    }
    if (!serviceAccountJson.trimStart().startsWith("{")) {
      try {
        serviceAccountJson = atob(serviceAccountJson)
      } catch {
        // nije base64, koristi kao JSON
      }
    }

    const sa = JSON.parse(serviceAccountJson)
    const projectId = sa.project_id
    let currentAccessToken = await getAccessToken(sa)
    let refreshInFlight: Promise<string> | null = null

    const refreshAccessToken = (): Promise<string> => {
      if (!refreshInFlight) {
        tokenCache.delete(projectId)
        refreshInFlight = getAccessToken(sa).finally(() => {
          refreshInFlight = null
        })
      }
      return refreshInFlight
    }

    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`

    // Optimizacija: Batch slanje tokena sa max 100 istovremeno (umesto sekvencijalnog)
    const BATCH_SIZE = 100
    let sent = 0
    const errors: string[] = []
    const invalidTokens: string[] = [] // Tokeni koji su 404/400 – za bulk delete

    // Pre-calculate content once per request
    const lockscreenBody = getLockscreenBody(bodyText)

    // Helper: Prati jedan token i vraća {success: boolean, token: string, error?: string}
    const sendSingleMessage = async (row: { token: string; platform: string }): Promise<{
      success: boolean
      token: string
      error?: string
    }> => {
      const baseMessage = buildFcmMessagePayload({
        token: row.token,
        platform: row.platform,
        title,
        lockscreenBody,
        bodyText,
        fcmData,
      })

      try {
        const postFcm = (token: string) =>
          fetch(fcmUrl, {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              "Authorization": `Bearer ${token}`,
            },
            body: JSON.stringify({ message: baseMessage }),
          })

        let res = await postFcm(currentAccessToken)

        // Ako je 401, osveži OAuth token jednom (uz spajanje paralelnih osvežavanja) i ponovi zahtev
        if (res.status === 401) {
          log("warn", "FCM: Unauthorized (401) - osvežavam cache token i ponavljam slanje")
          await res.body?.cancel().catch(() => {})
          currentAccessToken = await refreshAccessToken()
          res = await postFcm(currentAccessToken)
        }

        if (res.ok) {
          return { success: true, token: row.token }
        } else {
          const errBody = await res.text()
          // Ne loguj pun token — samo kratki, ne-reverzibilni prefiks.
          const errMsg = `token[${row.token.slice(0, 8)}…] ${res.status}: ${errBody.slice(0, 200)}`

          if (shouldDeletePushToken(res.status, errBody)) {
            invalidTokens.push(row.token)
          }

          if (res.status === 401) {
            log("warn", "FCM: Unauthorized (401) i nakon osvežavanja tokena, brišem cache")
            tokenCache.delete(projectId)
          }

          return { success: false, token: row.token, error: errMsg }
        }
      } catch (err) {
        const errMsg = `Greška pri slanju: ${String(err).slice(0, 100)}`
        return { success: false, token: row.token, error: errMsg }
      }
    }

    // Slanje u batch-evima (max 100 istovremeno)
    for (let i = 0; i < tokens.length; i += BATCH_SIZE) {
      const batch = tokens.slice(i, i + BATCH_SIZE)
      log("debug", `FCM: Slanje batch-a (${i + 1}-${Math.min(i + BATCH_SIZE, tokens.length)} od ${tokens.length})`)

      // Promise.all() čini sve requste u batch-u istovremeno
      const results = await Promise.all(batch.map(sendSingleMessage))

      // Prikupi rezultate
      for (const result of results) {
        if (result.success) {
          sent++
        } else {
          errors.push(result.error || "Nepoznata greška")
        }
      }

      log("info", `FCM: Batch gotov - poslano: ${results.filter((r) => r.success).length}/${batch.length}`)
    }

    // Obriši sve invalid tokene u chunk-ovima od max 50 kako ne bismo prebili PostgREST URL limit (HTTP 414)
    if (invalidTokens.length > 0) {
      log("info", `FCM: Brisanje ${invalidTokens.length} invalid tokena u chunk-ovima`)
      const DELETE_CHUNK_SIZE = 50
      for (let i = 0; i < invalidTokens.length; i += DELETE_CHUNK_SIZE) {
        const chunk = invalidTokens.slice(i, i + DELETE_CHUNK_SIZE)
        try {
          const { error: delErr } = await supabase
            .from("user_push_tokens")
            .delete()
            .in("token", chunk)
          if (delErr) {
            log("error", "FCM: Brisanje chunk-a tokena vratilo grešku:", delErr.message)
          }
        } catch (delErr) {
          log("error", "FCM: Greška pri brisanju chunk-a tokena:", String(delErr))
        }
      }
    }

    await writeDeliveryLog({
      userId: user_id,
      title,
      type: fcmData.type,
      tokenCount: tokens.length,
      sentCount: sent,
      status: errors.length === 0 ? "success" : sent > 0 ? "partial" : "error",
      errors,
      payload: {
        request_source: isTriggerRecord ? "db_trigger" : "direct_call",
        order_id: fcmData.order_id,
      },
    })

    return new Response(
      JSON.stringify({ message: "OK", sent, errors, request_id: requestId }),
      { status: 200, headers: { ...getCorsHeaders(req), "Content-Type": "application/json" } }
    )
  } catch (err) {
    log("error", "FCM: Neuhvaćena greška", String(err))
    return new Response(
      JSON.stringify({ error: "Interna greška na serveru." }),
      { status: 500, headers: { ...getCorsHeaders(req), "Content-Type": "application/json" } }
    )
  }
})
