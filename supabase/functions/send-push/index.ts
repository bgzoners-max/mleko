// Push notifikacije – FCM HTTP v1 API (Legacy je ugašen od jula 2024)
import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import * as jose from "https://deno.land/x/jose@v5.2.0/index.ts"
import type { Database, Json } from "../../types/database.types.ts"
import {
  getLockscreenBody,
  isLogLevelEnabled,
  redactText,
  resolveLogLevel,
  shortId,
  type LogLevel,
} from "./push_helpers.ts"

// Dozvoljeni domeni za CORS (ograniči attack surface)
const PROD_ALLOWED_ORIGINS = [
  "https://domacimarket.rs",
  "https://www.domacimarket.rs",
]

// Dozvoli lokalne adrese samo u development okruženju
const isDev = (Deno.env.get("ENVIRONMENT") || "").toLowerCase() === "development" ||
  (Deno.env.get("DENO_ENV") || "").toLowerCase() === "development" ||
  Deno.env.get("ALLOW_LOCAL_CORS") === "true"

const ALLOWED_ORIGINS = isDev
  ? [...PROD_ALLOWED_ORIGINS, "http://localhost:3000", "http://localhost:8080"]
  : PROD_ALLOWED_ORIGINS


function getCorsHeaders(req: Request): Record<string, string> {
  const origin = req.headers.get("origin") || ""
  const isAllowed = ALLOWED_ORIGINS.includes(origin)
  
  return {
    "Access-Control-Allow-Origin": isAllowed ? origin : ALLOWED_ORIGINS[0],
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
  }
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

  // S2 Security Fix: Zahtevaj kriptografski verifikovanu 'service_role' autorizaciju.
  // Javni anon ključ ili obični korisnički JWT ne smeju imati pristup slanju push-a.
  const authHeader = req.headers.get("Authorization") ?? req.headers.get("authorization")
  if (!authHeader || !authHeader.toLowerCase().startsWith("bearer ")) {
    log("warn", "FCM: Odbijen zahtev - nedostaje Authorization header")
    return new Response(
      JSON.stringify({ error: "Missing or invalid authorization header" }),
      { status: 401, headers: { ...getCorsHeaders(req), "Content-Type": "application/json" } }
    )
  }

  const token = authHeader.slice(7).trim()
  const expectedServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")
  const jwtSecret = Deno.env.get("SUPABASE_JWT_SECRET")

  let authorized = false
  let isSystemOrAdmin = false
  let callerUid: string | null = null

  // 1. Neposredno poklapanje sa tajnim service_role_key-em (koji šalje postgres trigger preko pg_net)
  if (expectedServiceKey && token === expectedServiceKey) {
    authorized = true
    isSystemOrAdmin = true
  } else if (jwtSecret) {
    // 2. Kriptografska provera potpisa JWT tokena pomoću SUPABASE_JWT_SECRET
    try {
      const secretBytes = new TextEncoder().encode(jwtSecret)
      const { payload } = await jose.jwtVerify(token, secretBytes)
      if (payload.role === "service_role") {
        authorized = true
        isSystemOrAdmin = true
      } else if (payload.role === "authenticated") {
        callerUid = (payload.sub as string) || null
        const payloadAny = payload as Record<string, any>
        const isAdmin = payloadAny.is_admin === true ||
          payloadAny.app_metadata?.is_admin === true ||
          payloadAny.user_metadata?.is_admin === true
        if (isAdmin) {
          isSystemOrAdmin = true
          authorized = true
        } else if (callerUid) {
          authorized = true
        } else {
          log("warn", "FCM: Odbijen zahtev - authenticated JWT bez validnog sub claim-a")
          return new Response(
            JSON.stringify({ error: "Unauthorized: invalid user claim" }),
            { status: 401, headers: { ...getCorsHeaders(req), "Content-Type": "application/json" } }
          )
        }
      } else {
        log("warn", `FCM: Neovlašćen pristup sa role '${payload.role}' umesto 'service_role' ili 'authenticated'`)
        return new Response(
          JSON.stringify({ error: "Forbidden: insufficient permissions" }),
          { status: 403, headers: { ...getCorsHeaders(req), "Content-Type": "application/json" } }
        )
      }
    } catch (verifyErr) {
      log("warn", "FCM: Odbijen zahtev - nevalidan JWT potpis:", String(verifyErr))
      return new Response(
        JSON.stringify({ error: "Invalid authorization token signature" }),
        { status: 401, headers: { ...getCorsHeaders(req), "Content-Type": "application/json" } }
      )
    }
  } else {
    // 3. Ako SUPABASE_JWT_SECRET nije ubačen u runtime environment, token se MORA poklapati
    // sa expectedServiceKey vrednošću (odbacujemo neproverene nepotpisane tokene).
    log("warn", "FCM: Odbijen zahtev - token se ne poklapa sa service_role_key a SUPABASE_JWT_SECRET nije konfigurisan.")
    return new Response(
      JSON.stringify({ error: "Unauthorized: Signature verification required" }),
      { status: 401, headers: { ...getCorsHeaders(req), "Content-Type": "application/json" } }
    )
  }

  if (!authorized) {
    return new Response(
      JSON.stringify({ error: "Forbidden: insufficient permissions" }),
      { status: 403, headers: { ...getCorsHeaders(req), "Content-Type": "application/json" } }
    )
  }

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
        await supabase.from("push_delivery_logs").insert({
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
      } catch (logErr) {
        log("error", "FCM: upis push_delivery_logs nije uspeo", String(logErr))
      }
    }

    let body: any
    try {
      body = await req.json()
    } catch {
      return new Response(
        JSON.stringify({ error: "Invalid JSON body" }),
        { status: 400, headers: { ...getCorsHeaders(req), "Content-Type": "application/json" } }
      )
    }

    if (!body) {
      return new Response(
        JSON.stringify({ error: "Request body is required" }),
        { status: 400, headers: { ...getCorsHeaders(req), "Content-Type": "application/json" } }
      )
    }

    let user_id: string
    let title: string
    let bodyText: string
    let fcmData: Record<string, string> = {}
    let type: string = ""

    log("debug", "FCM: Primljena zahteva:", {
      has_record: !!body.record,
      keys: Object.keys(body).slice(0, 10),
    })

    if (body.record) {
      const record = body.record
      user_id = record.user_id
      title = record.title
      bodyText = record.body ?? ""
      type = record.type ?? ""
      fcmData = {
        type,
        notification_id: String(record.id ?? ""),
        created_at: String(record.created_at ?? ""),
        order_id: String(record.order_id ?? ""),
        conversation_id: String(record.conversation_id ?? ""),
        ticket_id: String(record.ticket_id ?? ""),
        classified_ad_id: String(record.classified_ad_id ?? ""),
      }
      if (record.route) {
        fcmData.route = String(record.route)
      }
    } else {
      user_id = body.user_id
      title = body.title
      bodyText = body.body ?? ""
      type = body.type ?? ""
      fcmData = {
        type,
        notification_id: String(body.notification_id ?? body.id ?? ""),
        created_at: String(body.created_at ?? ""),
        order_id: String(body.order_id ?? ""),
        conversation_id: String(body.conversation_id ?? ""),
        ticket_id: String(body.ticket_id ?? ""),
        classified_ad_id: String(body.classified_ad_id ?? ""),
      }
      if (body.route) {
        fcmData.route = String(body.route)
      }
      if (body.data && typeof body.data === "object") {
        for (const [k, v] of Object.entries(body.data)) {
          if (v != null && !fcmData[k]) fcmData[k] = String(v)
        }
      }
    }

    // Poboljšanje personalizacije naslova na osnovu tipa
    if (!title || title === "Obaveštenje" || title === "Notification") {
      if (type === "new_order") title = "Nova porudžbina 🛒";
      else if (type === "order_status" || type === "order_status_changed") title = "Status porudžbine 📦";
      else if (type === "new_message") title = "Nova poruka 💬";
      else if (type === "new_review" || type === "new_buyer_review") title = "Nova recenzija ⭐";
      else title = title || "Obaveštenje";
    }

    log("debug", "FCM: Procesuirana notifikacija:", {
      user_id: shortId(user_id),
      title: redactText(title),
      type: fcmData.type,
    })

    if (!user_id) {
      log("error", "FCM: Nedostaje user_id")
      await writeDeliveryLog({
        status: "invalid_request",
        errors: ["user_id required"],
        payload: { keys: Object.keys(body || {}) },
      })
      return new Response(
        JSON.stringify({ error: "user_id required" }),
        { status: 400, headers: { ...getCorsHeaders(req), "Content-Type": "application/json" } }
      )
    }

    // Bezbednosna provera: Običan korisnik sme slati push notifikaciju ISKLJUČIVO sebi (request.auth.uid === user_id)
    if (!isSystemOrAdmin) {
      if (!callerUid || callerUid !== user_id) {
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
    }

    // Preuzimamo sve tokene, ali filtriramo jedinstvene u memoriji 
    // kako bismo izbegli dupliranje ako korisnik ima više instalacija na istom uređaju
    const { data: allTokens, error } = await supabase
      .from("user_push_tokens")
      .select("token, platform")
      .eq("user_id", user_id)

    // Jedinstveni tokeni (ako isti token postoji pod više installation_id)
    const uniqueTokensMap = new Map<string, string>();
    (allTokens || []).forEach(t => {
      if (t.token) uniqueTokensMap.set(t.token, t.platform || "android");
    });
    
    const tokens = Array.from(uniqueTokensMap.entries()).map(([token, platform]) => ({ token, platform }));

    log("debug", "FCM: Pretraga tokena:", {
      user_id: shortId(user_id),
      total_found: allTokens?.length || 0,
      unique_count: tokens.length,
      error: error?.message,
    })

    if (error || !tokens?.length) {
      log("warn", `FCM: Nema tokena za korisnika ${shortId(user_id)}`)
      await writeDeliveryLog({
        userId: user_id,
        title,
        type: fcmData.type,
        tokenCount: tokens?.length ?? 0,
        sentCount: 0,
        status: "no_tokens",
        errors: error ? [error.message] : [],
        payload: { body_len: bodyText.length },
      })
      return new Response(
        JSON.stringify({ message: "No push tokens", sent: 0, token_count: tokens?.length || 0 }),
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
    const accessToken = await getAccessToken(sa)

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
      const platform = (row.platform ?? "android") as string
      const baseMessage: Record<string, unknown> = {
        token: row.token,
        data: { ...fcmData, title, body: bodyText },
      }

      if (platform === "ios") {
        baseMessage.notification = { title, body: lockscreenBody }
        baseMessage.apns = {
          headers: { "apns-priority": "10" },
          payload: {
            aps: {
              alert: { title, body: lockscreenBody },
              sound: "default",
              badge: 1,
            },
          },
        }
      } else {
        const isOrder = fcmData.type === "new_order" || fcmData.type === "order_status" || fcmData.type === "order_status_changed";
        const channelId = isOrder ? "orders_high_v2" : "mleko_urgent_v2";
        baseMessage.android = {
          priority: "HIGH",
          ttl: "86400s",
          notification: {
            channel_id: channelId,
            title,
            body: lockscreenBody,
            sound: "default",
            default_vibrate_timings: true,
            default_sound: true,
            visibility: "PUBLIC",
            notification_priority: "PRIORITY_HIGH",
            icon: "ic_notification",
            color: "#1B5E20",
          },
        }
      }

      try {
        const res = await fetch(fcmUrl, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "Authorization": `Bearer ${accessToken}`,
          },
          body: JSON.stringify({ message: baseMessage }),
        })

        if (res.ok) {
          return { success: true, token: row.token }
        } else {
          const errBody = await res.text()
          // Ne loguj pun token — samo kratki, ne-reverzibilni prefiks.
          const errMsg = `token[${row.token.slice(0, 8)}…] ${res.status}: ${errBody.slice(0, 200)}`

          // Označi invalid token za brisanje
          let errorCode: string | undefined
          try {
            errorCode = JSON.parse(errBody)?.error?.details?.[0]?.errorCode
          } catch { /* nije JSON */ }
          if (res.status === 404 || errorCode === "UNREGISTERED" || errorCode === "INVALID_ARGUMENT") {
            invalidTokens.push(row.token)
          }

          // Ako je 401, invalidiraj access token cache
          // Sledeći zahtjev će generiusti novi token
          if (res.status === 401) {
            log("warn", "FCM: Unauthorized (401) - cache token je istekao, briši cache")
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
          await supabase.from("user_push_tokens").delete().in("token", chunk)
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
        request_source: body.record ? "db_trigger" : "direct_call",
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
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { ...getCorsHeaders(req), "Content-Type": "application/json" } }
    )
  }
})
