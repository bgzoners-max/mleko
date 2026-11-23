// Cloudflare Pages Function: /api/eur-rate
// Vraća zvanični dnevni srednji kurs evra (EUR/RSD) Narodne banke Srbije (NBS)
// preuzet putem javnog JSON servisa kurs.resenje.org, uz Cloudflare CDN keširanje (6h).

type KursResenjeResponse = {
  code?: string;
  date?: string;
  date_from?: string;
  number?: number;
  parity?: number;
  exchange_middle?: number;
  exchange_buy?: number;
  exchange_sell?: number;
};

type EurRatePayload = {
  code: "EUR";
  middle: number;
  date: string | null;
  listNumber: number | null;
  source: string;
  provider: string;
  isFallback: boolean;
};

const UPSTREAM_URL = "https://kurs.resenje.org/api/v1/currencies/eur/rates/today";
const FALLBACK_MIDDLE_RATE = 117.65;
const SOURCE_NAME = "Narodna banka Srbije (NBS)";
const PROVIDER_NAME = "kurs.resenje.org";

function jsonResponse(
  payload: EurRatePayload,
  cacheControl: string,
): Response {
  return new Response(JSON.stringify(payload), {
    status: 200,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": cacheControl,
      "access-control-allow-origin": "*",
      "x-content-type-options": "nosniff",
    },
  });
}

export const onRequestGet: PagesFunction = async () => {
  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 5000);
    let upstreamRes: Response;
    try {
      upstreamRes = await fetch(UPSTREAM_URL, {
        headers: {
          accept: "application/json",
          "user-agent": "DomaciMarket/1.0 (+https://www.domacimarket.rs)",
        },
        signal: controller.signal,
      });
    } finally {
      clearTimeout(timeoutId);
    }

    if (upstreamRes.ok) {
      const data = (await upstreamRes.json()) as KursResenjeResponse;
      const middle =
        typeof data.exchange_middle === "number"
          ? data.exchange_middle
          : Number(data.exchange_middle);

      if (Number.isFinite(middle) && middle > 50 && middle < 300) {
        const payload: EurRatePayload = {
          code: "EUR",
          middle: Number(middle.toFixed(4)),
          date:
            typeof data.date === "string" && data.date.trim().length > 0
              ? data.date.trim()
              : null,
          listNumber:
            typeof data.number === "number" && Number.isFinite(data.number)
              ? data.number
              : null,
          source: SOURCE_NAME,
          provider: PROVIDER_NAME,
          isFallback: false,
        };

        return jsonResponse(
          payload,
          "public, max-age=3600, s-maxage=21600, stale-while-revalidate=86400",
        );
      }
    }
  } catch {
    // Fallback ispod kada je upstream privremeno nedostupan
  }

  return jsonResponse(
    {
      code: "EUR",
      middle: FALLBACK_MIDDLE_RATE,
      date: null,
      listNumber: null,
      source: SOURCE_NAME,
      provider: PROVIDER_NAME,
      isFallback: true,
    },
    "public, max-age=300, s-maxage=300",
  );
};
