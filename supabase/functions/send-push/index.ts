// Push notifikacije – FCM HTTP v1 API (Legacy je ugašen od jula 2024)
import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import * as jose from "https://deno.land/x/jose@v5.2.0/index.ts"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

async function getAccessToken(serviceAccountJson: string): Promise<string> {
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
  return data.access_token
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    )

    let body = await req.json()
    let user_id: string
    let title: string
    let bodyText: string
    let data: Record<string, string> = {}

    console.log("FCM: Primljena zahteva:", {
      has_record: !!body.record,
      keys: Object.keys(body).slice(0, 10),
    })

    if (body.record) {
      const record = body.record
      user_id = record.user_id
      title = record.title ?? "Obaveštenje"
      bodyText = record.body ?? ""
      data = { type: record.type ?? "", order_id: record.order_id ?? "" }
    } else {
      user_id = body.user_id
      title = body.title ?? "Obaveštenje"
      bodyText = body.body ?? ""
      data = { type: body.type ?? "", order_id: body.order_id ?? "" }
    }

    console.log("FCM: Procesuirana notifikacija:", {
      user_id,
      title,
      bodyText: bodyText.slice(0, 50),
      type: data.type,
    })

    if (!user_id) {
      console.error("FCM: Nedostaje user_id")
      return new Response(
        JSON.stringify({ error: "user_id required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    const { data: tokens, error } = await supabase
      .from("user_push_tokens")
      .select("token, platform")
      .eq("user_id", user_id)

    console.log("FCM: Pretraga tokena:", {
      user_id,
      token_count: tokens?.length || 0,
      error: error?.message,
    })

    if (error || !tokens?.length) {
      console.warn(`FCM: Nema tokena za korisnika ${user_id}`)
      return new Response(
        JSON.stringify({ message: "No push tokens", sent: 0, token_count: tokens?.length || 0 }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    let serviceAccountJson = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON")
    if (!serviceAccountJson) {
      console.error("FCM_SERVICE_ACCOUNT_JSON not set")
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
    const accessToken = await getAccessToken(serviceAccountJson)

    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`

    let sent = 0
    const errors: string[] = []
    for (const row of tokens) {
      const platform = (row.platform ?? "android") as string
      const baseMessage: Record<string, unknown> = {
        token: row.token,
        notification: { title, body: bodyText },
        data: { ...data, title, body: bodyText },
      }

      console.log(`FCM: Slanje notifikacije (${platform}):`, {
        title,
        body: bodyText,
        type: data.type,
        order_id: data.order_id,
        token: row.token.slice(0, 20) + "...",
      })

      if (platform === "ios") {
        baseMessage.apns = {
          headers: { "apns-priority": "10" },
          payload: {
            aps: {
              alert: { title, body: bodyText },
              sound: "default",
              badge: 1,
            },
          },
        }
      } else {
        const isOrder = data.type === "new_order" || data.type === "order_status" || data.type === "order_status_changed";
        const channelId = isOrder ? "orders_high" : "mleko_urgent";
        baseMessage.android = {
          priority: "HIGH",
          notification: {
            channel_id: channelId,
            sound: "default",
            default_vibrate_timings: true,
            visibility: "PUBLIC",
            notification_priority: "PRIORITY_HIGH",
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
          sent++
          console.log(`FCM: Uspešno poslano (${platform})`)
        } else {
          const errBody = await res.text()
          const errMsg = `token[${row.token.slice(0, 15)}] ${res.status}: ${errBody.slice(0, 200)}`
          console.error("FCM error:", errMsg)
          errors.push(errMsg)
          if (res.status === 404) {
            console.log("FCM: Token ne postoji, uklanjam iz DB")
            await supabase.from("user_push_tokens").delete().eq("token", row.token)
          }
        }
      } catch (err) {
        const errMsg = `Greška pri slanju: ${String(err).slice(0, 100)}`
        console.error(errMsg)
        errors.push(errMsg)
      }
    }

    return new Response(
      JSON.stringify({ message: "OK", sent, errors }),
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
