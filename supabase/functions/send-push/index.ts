// Push notifikacije – FCM HTTP v1 API (Legacy je ugašen od jula 2024)
import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import * as jose from "https://deno.land/x/jose@v5.2.0/index.ts"
import type { Database } from "../../types/database.types.ts"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

// Cache za FCM access token – izbegava skupu JWT generisanje
interface TokenCache {
  token: string
  expiresAt: number // milliseconds
}

const tokenCache = new Map<string, TokenCache>() // Key: project_id

function getLockscreenBody(input: string, maxLen = 88): string {
  const trimmed = (input || "").replace(/\s+/g, " ").trim()
  if (trimmed.length <= maxLen) return trimmed
  const cut = trimmed.slice(0, maxLen)
  const lastSpace = cut.lastIndexOf(" ")
  const safe = lastSpace > 24 ? cut.slice(0, lastSpace) : cut
  return safe.trimEnd() + "..."
}

async function getAccessToken(serviceAccountJson: string, projectId: string): Promise<string> {
  // Prvo proveri cache
  const cached = tokenCache.get(projectId)
  if (cached && Date.now() < cached.expiresAt) {
    console.log(`FCM: Korišćen cached token za ${projectId}`)
    return cached.token
  }

  // Generisanje novog token-a ako cache nije validan
  console.log(`FCM: Generiši novi token za ${projectId}`)
  const sa = JSON.parse(serviceAccountJson)
  const key = await jose.importPKCS8(sa.private_key, "RS256")
  const jwt = await new jose.SignJWT({ scope: "https://www.googleapis.com/auth/firebase.messaging" })
    .setProtectedHeader({ alg: "RS256" })
    .setIssuer(sa.client_email)
    .setSubject(sa.client_email)
    .setAudience("https://oauth2.googleapis.com/token")
    .setIssuedAt()
    .setExpirationTime("1h")
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

  // Cache token sa 5 minut margine pre nego što istekne (55 minuta umesto 60)
  const expiresAt = Date.now() + (expiresIn - 300) * 1000
  tokenCache.set(projectId, { token: accessToken, expiresAt })

  console.log(`FCM: Token cache-ovan, važi još ${Math.round((expiresAt - Date.now()) / 60000)} minuta`)
  return accessToken
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
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
          errors: params.errors ?? [],
          payload: params.payload ?? {},
        })
      } catch (logErr) {
        console.error("FCM: upis push_delivery_logs nije uspeo", String(logErr))
      }
    }

    let body = await req.json()
    let user_id: string
    let title: string
    let bodyText: string
    let data: Record<string, string> = {}
    let type: string = ""

    console.log("FCM: Primljena zahteva:", {
      has_record: !!body.record,
      keys: Object.keys(body).slice(0, 10),
    })

    if (body.record) {
      const record = body.record
      user_id = record.user_id
      title = record.title
      bodyText = record.body ?? ""
      type = record.type ?? ""
      data = {
        type,
        order_id: record.order_id ?? "",
        conversation_id: record.conversation_id ?? "",
      }
    } else {
      user_id = body.user_id
      title = body.title
      bodyText = body.body ?? ""
      type = body.type ?? ""
      data = {
        type,
        order_id: body.order_id ?? "",
        conversation_id: body.conversation_id ?? "",
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

    console.log("FCM: Procesuirana notifikacija:", {
      user_id,
      title,
      bodyText: bodyText.slice(0, 50),
      type: data.type,
    })

    if (!user_id) {
      console.error("FCM: Nedostaje user_id")
      await writeDeliveryLog({
        status: "invalid_request",
        errors: ["user_id required"],
        payload: { keys: Object.keys(body || {}) },
      })
      return new Response(
        JSON.stringify({ error: "user_id required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
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

    console.log("FCM: Pretraga tokena:", {
      user_id,
      total_found: allTokens?.length || 0,
      unique_count: tokens.length,
      error: error?.message,
    })

    if (error || !tokens?.length) {
      console.warn(`FCM: Nema tokena za korisnika ${user_id}`)
      await writeDeliveryLog({
        userId: user_id,
        title,
        type: data.type,
        tokenCount: tokens?.length ?? 0,
        sentCount: 0,
        status: "no_tokens",
        errors: error ? [error.message] : [],
        payload: { body_len: bodyText.length },
      })
      return new Response(
        JSON.stringify({ message: "No push tokens", sent: 0, token_count: tokens?.length || 0 }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    let serviceAccountJson = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON")
    if (!serviceAccountJson) {
      console.error("FCM_SERVICE_ACCOUNT_JSON not set")
      await writeDeliveryLog({
        userId: user_id,
        title,
        type: data.type,
        tokenCount: tokens.length,
        sentCount: 0,
        status: "error",
        errors: ["FCM_SERVICE_ACCOUNT_JSON not set"],
      })
      return new Response(
        JSON.stringify({ error: "FCM not configured" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
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
    const accessToken = await getAccessToken(serviceAccountJson, projectId)

    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`

    // Optimizacija: Batch slanje tokena sa max 100 istovremeno (umesto sekvencijalnog)
    const BATCH_SIZE = 100
    let sent = 0
    const errors: string[] = []
    const invalidTokens: string[] = [] // Tokeni koji su 404/400 – za bulk delete

    // Helper: Prati jedan token i vraća {success: boolean, token: string, error?: string}
    const sendSingleMessage = async (row: { token: string; platform: string }): Promise<{
      success: boolean
      token: string
      error?: string
    }> => {
      const platform = (row.platform ?? "android") as string
      const lockscreenBody = getLockscreenBody(bodyText)
      const baseMessage: Record<string, unknown> = {
        token: row.token,
        data: { ...data, title, body: bodyText },
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
        const isOrder = data.type === "new_order" || data.type === "order_status" || data.type === "order_status_changed";
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
          const errMsg = `token[${row.token.slice(0, 15)}] ${res.status}: ${errBody.slice(0, 200)}`

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
            console.warn(`FCM: Unauthorized (401) - cache token je istekao, briši cache`)
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
      console.log(`FCM: Slanje batch-a (${i + 1}-${Math.min(i + BATCH_SIZE, tokens.length)} od ${tokens.length})`)

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

      console.log(`FCM: Batch gotov - poslano: ${results.filter((r) => r.success).length}/${batch.length}`)
    }

    // Obriši sve invalid tokene odjednom (umesto jedan po jedan)
    if (invalidTokens.length > 0) {
      console.log(`FCM: Brisanje ${invalidTokens.length} invalid tokena`)
      await supabase.from("user_push_tokens").delete().in("token", invalidTokens)
    }

    await writeDeliveryLog({
      userId: user_id,
      title,
      type: data.type,
      tokenCount: tokens.length,
      sentCount: sent,
      status: errors.length === 0 ? "success" : sent > 0 ? "partial" : "error",
      errors,
      payload: {
        request_source: body.record ? "db_trigger" : "direct_call",
        order_id: data.order_id,
      },
    })

    return new Response(
      JSON.stringify({ message: "OK", sent, errors, request_id: requestId }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  } catch (err) {
    console.error(err)
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  }
})
