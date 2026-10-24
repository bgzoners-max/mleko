// Unit testovi za čiste helper funkcije send-push Edge funkcije.
// Pokretanje: `deno test supabase/functions/send-push/push_helpers.test.ts`
// (bez permisija — modul ne pristupa env-u niti mreži).
import {
  getLockscreenBody,
  isLogLevelEnabled,
  redactText,
  resolveLogLevel,
  shortId,
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
