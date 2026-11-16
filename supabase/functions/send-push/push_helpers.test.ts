// Unit testovi za čiste helper funkcije send-push Edge funkcije.
// Pokretanje: `deno test supabase/functions/send-push/push_helpers.test.ts`
// (bez permisija — modul ne pristupa env-u niti mreži).
import {
  authorizePushRequest,
  buildCorsHeaders,
  buildFcmMessagePayload,
  canSendPushToTarget,
  dedupePushTokens,
  extractBearerToken,
  getLockscreenBody,
  isLogLevelEnabled,
  parsePushNotificationRequest,
  redactText,
  resolveLogLevel,
  shortId,
  shouldDeletePushToken,
} from "./push_helpers.ts"
import { assert, assertEquals } from "jsr:@std/assert"

Deno.test("shortId: prazan/undefined/null → (nepoznato)", () => {
  assertEquals(shortId(undefined), "(nepoznato)")
  assertEquals(shortId(null), "(nepoznato)")
  assertEquals(shortId(""), "(nepoznato)")
})

Deno.test("shortId: pun UUID se skraćuje na prva 8 karaktera", () => {
  const uuid = "3f2b8c1a-9d4e-4f7b-b2c1-8e9f0a1b2c3d"
  assertEquals(shortId(uuid), "3f2b8c1a…")
})

Deno.test("shortId: kraći ID od 8 karaktera prolazi ceo uz elipsu", () => {
  // Originalna semantika: uvek dodaje "…" — i za kratke identifikatore.
  assertEquals(shortId("abc"), "abc…")
})

Deno.test("redactText: null/undefined/prazan → prazan string", () => {
  assertEquals(redactText(null), "")
  assertEquals(redactText(undefined), "")
  assertEquals(redactText(""), "")
  assertEquals(redactText("     "), "")
})

Deno.test("redactText: trimuje surrounding whitespace", () => {
  assertEquals(redactText("  poruka o porudžbini  "), "poruka o porudžbini")
})

Deno.test("redactText: tekst unutar maxLen se ne seče", () => {
  assertEquals(redactText("Novo obaveštenje", 30), "Novo obaveštenje")
})

Deno.test("redactText: duži tekst se seče na maxLen uz elipsu", () => {
  const long = "Ovo je veoma dugačka push poruka koja prevazilazi prag"
  assertEquals(redactText(long, 30), `${long.slice(0, 30)}…`)
})

Deno.test("getLockscreenBody: normalizuje višestruke razmake i nove redove", () => {
  assertEquals(getLockscreenBody("Vas   sir\nje   poslat"), "Vas sir je poslat")
})

Deno.test("getLockscreenBody: tekst ≤ maxLen se ne seče", () => {
  assertEquals(getLockscreenBody("Porudžbina prihvaćena", 88), "Porudžbina prihvaćena")
})

Deno.test("getLockscreenBody: duži tekst se seče na granici reči", () => {
  // 112 karaktera — prelazi podrazumevani prag od 88; poslednja reč unutar
  // praga je "bi" (pozicija razmaka 81 > 24), pa se sečenje zaustavlja tamo.
  const input =
    "Vasa porudzbina za domaci sir, med i jaja je prihvacena od strane gazdinstva i bi isporucena u sredu posle podne"
  assertEquals(
    getLockscreenBody(input),
    "Vasa porudzbina za domaci sir, med i jaja je prihvacena od strane gazdinstva i bi...",
  )
})

Deno.test("getLockscreenBody: bez razmaka seče hard na maxLen", () => {
  const noSpaces = "x".repeat(100)
  const result = getLockscreenBody(noSpaces, 88)
  assertEquals(result, `${"x".repeat(88)}...`)
})

Deno.test("resolveLogLevel: undefined/null/prazan → info", () => {
  assertEquals(resolveLogLevel(undefined), "info")
  assertEquals(resolveLogLevel(null), "info")
  assertEquals(resolveLogLevel(""), "info")
})

Deno.test("resolveLogLevel: case-insensitive", () => {
  assertEquals(resolveLogLevel("DEBUG"), "debug")
  assertEquals(resolveLogLevel("Warn"), "warn")
  assertEquals(resolveLogLevel(" ERROR "), "error")
})

Deno.test("resolveLogLevel: neprepoznata vrednost → info", () => {
  assertEquals(resolveLogLevel("verbose"), "info")
  assertEquals(resolveLogLevel("critical"), "info")
})

Deno.test("isLogLevelEnabled: redosled po ozbiljnosti", () => {
  // prag debug → sve vidljivo
  assert(isLogLevelEnabled("debug", "debug"))
  assert(isLogLevelEnabled("info", "debug"))
  assert(isLogLevelEnabled("warn", "debug"))
  assert(isLogLevelEnabled("error", "debug"))
  // prag info → debug sakriven
  assert(!isLogLevelEnabled("debug", "info"))
  assert(isLogLevelEnabled("info", "info"))
  assert(isLogLevelEnabled("error", "info"))
  // prag error → samo error
  assert(!isLogLevelEnabled("warn", "error"))
  assert(isLogLevelEnabled("error", "error"))
})

Deno.test("buildCorsHeaders: ne vraća Access-Control-Allow-Origin za nedozvoljen ili prazan origin", () => {
  const allowed = ["https://domacimarket.rs", "https://www.domacimarket.rs"]
  const okHeaders = buildCorsHeaders("https://www.domacimarket.rs", allowed)
  assertEquals(okHeaders["Access-Control-Allow-Origin"], "https://www.domacimarket.rs")
  assertEquals(okHeaders["Vary"], "Origin")

  const badHeaders = buildCorsHeaders("https://evil.example", allowed)
  assertEquals(badHeaders["Access-Control-Allow-Origin"], undefined)
  assertEquals(badHeaders["Vary"], "Origin")

  const emptyHeaders = buildCorsHeaders(null, allowed)
  assertEquals(emptyHeaders["Access-Control-Allow-Origin"], undefined)
})

Deno.test("shouldDeletePushToken: razlikuje mrtav token od greške payload-a", () => {
  assert(shouldDeletePushToken(404, "{}"))
  assert(
    shouldDeletePushToken(
      404,
      JSON.stringify({ error: { status: "NOT_FOUND", details: [{ errorCode: "UNREGISTERED" }] } }),
    ),
  )
  assert(
    shouldDeletePushToken(
      400,
      JSON.stringify({
        error: {
          message: "The registration token is not a valid FCM registration token",
          details: [{ errorCode: "INVALID_ARGUMENT" }],
        },
      }),
    ),
  )
  assert(
    !shouldDeletePushToken(
      400,
      JSON.stringify({
        error: {
          message: "Invalid TTL value in android config",
          details: [{ errorCode: "INVALID_ARGUMENT" }],
        },
      }),
    ),
  )
})

Deno.test("extractBearerToken i authorizePushRequest: pokrivaju sve autorizacione grane", async () => {
  assertEquals(extractBearerToken(null), null)
  assertEquals(extractBearerToken("Basic abc"), null)
  assertEquals(extractBearerToken("bearer  tok-123  "), "tok-123")

  const noHeader = await authorizePushRequest({
    authHeader: null,
    expectedServiceKey: "srv-key",
    jwtSecret: "jwt-sec",
    verifyJwt: () => Promise.resolve({}),
  })
  assert(!noHeader.ok && noHeader.status === 401)

  const serviceDirect = await authorizePushRequest({
    authHeader: "Bearer srv-key",
    expectedServiceKey: "srv-key",
    jwtSecret: null,
    verifyJwt: () => Promise.resolve({}),
  })
  assert(serviceDirect.ok && serviceDirect.isSystemOrAdmin)

  const noSecretFallback = await authorizePushRequest({
    authHeader: "Bearer other-key",
    expectedServiceKey: "srv-key",
    jwtSecret: null,
    verifyJwt: () => Promise.resolve({}),
  })
  assert(!noSecretFallback.ok && noSecretFallback.status === 401)

  const userJwt = await authorizePushRequest({
    authHeader: "Bearer signed-jwt",
    expectedServiceKey: "srv-key",
    jwtSecret: "jwt-sec",
    verifyJwt: () => Promise.resolve({ role: "authenticated", sub: "user-1" }),
  })
  assert(userJwt.ok && !userJwt.isSystemOrAdmin)
  assertEquals(userJwt.callerUid, "user-1")

  const adminJwt = await authorizePushRequest({
    authHeader: "Bearer admin-jwt",
    expectedServiceKey: "srv-key",
    jwtSecret: "jwt-sec",
    verifyJwt: () =>
      Promise.resolve({
        role: "authenticated",
        sub: "admin-1",
        app_metadata: { is_admin: true },
      }),
  })
  assert(adminJwt.ok && adminJwt.isSystemOrAdmin)

  const anonRole = await authorizePushRequest({
    authHeader: "Bearer anon-jwt",
    expectedServiceKey: "srv-key",
    jwtSecret: "jwt-sec",
    verifyJwt: () => Promise.resolve({ role: "anon" }),
  })
  assert(!anonRole.ok && anonRole.status === 403)

  const badSig = await authorizePushRequest({
    authHeader: "Bearer tampered",
    expectedServiceKey: "srv-key",
    jwtSecret: "jwt-sec",
    verifyJwt: () => Promise.reject(new Error("invalid signature")),
  })
  assert(!badSig.ok && badSig.status === 401)
})

Deno.test("parsePushNotificationRequest i canSendPushToTarget: trigger vs direktan poziv", () => {
  const missingBody = parsePushNotificationRequest(null)
  assert(!missingBody.ok && missingBody.reason === "missing_body")

  const missingUser = parsePushNotificationRequest({ title: "Hej" })
  assert(!missingUser.ok && missingUser.reason === "missing_user_id")

  const fromTrigger = parsePushNotificationRequest({
    record: {
      id: "notif-1",
      user_id: "u-1",
      title: "Obaveštenje",
      body: "Stigla porudžbina",
      type: "new_order",
      order_id: "ord-9",
      route: "/orders",
    },
  })
  assert(fromTrigger.ok && fromTrigger.isTriggerRecord)
  assertEquals(fromTrigger.title, "Nova porudžbina 🛒")
  assertEquals(fromTrigger.fcmData.order_id, "ord-9")
  assertEquals(fromTrigger.fcmData.route, "/orders")

  const directCall = parsePushNotificationRequest({
    user_id: "u-2",
    title: "Prilagođeni naslov",
    body: "Poruka",
    type: "new_message",
    conversation_id: "conv-1",
    data: { conversation_id: "override-attempt", custom_key: 42 },
  })
  assert(directCall.ok && !directCall.isTriggerRecord)
  assertEquals(directCall.fcmData.conversation_id, "conv-1")
  assertEquals(directCall.fcmData.custom_key, "42")

  assert(canSendPushToTarget({ isSystemOrAdmin: false, callerUid: "u-1", targetUserId: "u-1" }))
  assert(!canSendPushToTarget({ isSystemOrAdmin: false, callerUid: "u-1", targetUserId: "u-2" }))
  assert(canSendPushToTarget({ isSystemOrAdmin: true, callerUid: "admin-1", targetUserId: "u-2" }))
})

Deno.test("dedupePushTokens i buildFcmMessagePayload: platformski payload i kanal", () => {
  const deduped = dedupePushTokens([
    { token: "t1", platform: "android" },
    { token: "t1", platform: "android" },
    { token: "t2", platform: null },
    { token: "", platform: "ios" },
    { token: "t3", platform: "ios" },
  ])
  assertEquals(deduped, [
    { token: "t1", platform: "android" },
    { token: "t2", platform: "android" },
    { token: "t3", platform: "ios" },
  ])

  const androidOrder = buildFcmMessagePayload({
    token: "t1",
    platform: "android",
    title: "Nova porudžbina 🛒",
    lockscreenBody: "Detalji...",
    bodyText: "Puni tekst",
    fcmData: { type: "new_order" },
  })
  assertEquals(
    ((androidOrder.android as Record<string, unknown>).notification as Record<string, unknown>).channel_id,
    "orders_high_v2",
  )

  const iosMsg = buildFcmMessagePayload({
    token: "t3",
    platform: "ios",
    title: "Nova poruka 💬",
    lockscreenBody: "Ćao",
    bodyText: "Ćao",
    fcmData: { type: "new_message" },
  })
  assert(iosMsg.apns !== undefined)
  assertEquals((iosMsg.notification as Record<string, unknown>).title, "Nova poruka 💬")
})
