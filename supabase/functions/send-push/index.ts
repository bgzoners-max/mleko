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

    if (!user_id) {
      return new Response(
        JSON.stringify({ error: "user_id required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    const { data: tokens, error } = await supabase
      .from("user_push_tokens")
      .select("token, platform")
      .eq("user_id", user_id)

    if (error || !tokens?.length) {
      return new Response(
        JSON.stringify({ message: "No push tokens", sent: 0 }),
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
      } else {
        const errBody = await res.text()
        const errMsg = `token[${row.token.slice(0, 15)}] ${res.status}: ${errBody.slice(0, 200)}`
        console.error("FCM error:", errMsg)
        errors.push(errMsg)
        if (res.status === 404) {
          await supabase.from("user_push_tokens").delete().eq("token", row.token)
        }
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
