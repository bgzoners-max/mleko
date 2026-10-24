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
