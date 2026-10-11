import { createClient, type EmailOtpType } from "@supabase/supabase-js";
import { resolvePublicBaseUrl } from "./_shared/preview-utils.js";

declare const process: any;

export async function handleAuthConfirm(request: Request, env?: any): Promise<Response> {
  let publicBaseUrl = "https://www.domacimarket.rs";
  try {
    const url = new URL(request.url);
    publicBaseUrl = resolvePublicBaseUrl(url.origin);
    const tokenHash = url.searchParams.get("token_hash");
    const type = url.searchParams.get("type") as EmailOtpType | null;
    const next = url.searchParams.get("next") || "/auth/confirmed";

    if (!tokenHash || !type) {
      return new Response(null, {
        status: 302,
        headers: {
          Location: `${publicBaseUrl}/#/login?error=${encodeURIComponent(
            "Link za potvrdu nije validan ili je nepotpun."
          )}`,
          "Cache-Control": "no-store, max-age=0",
        },
      });
    }

    const supabaseUrl =
      env?.SUPABASE_URL ||
      (typeof process !== "undefined"
        ? process.env?.SUPABASE_URL || process.env?.NEXT_PUBLIC_SUPABASE_URL
        : undefined);
    const supabaseAnonKey =
      env?.SUPABASE_ANON_KEY ||
      (typeof process !== "undefined"
        ? process.env?.SUPABASE_ANON_KEY || process.env?.NEXT_PUBLIC_SUPABASE_ANON_KEY
        : undefined);

    if (!supabaseUrl || !supabaseAnonKey) {
      return new Response(null, {
        status: 302,
        headers: {
          Location: `${publicBaseUrl}/#/login?error=${encodeURIComponent(
            "Sistemska greška: Supabase konfiguracija nije dostupna."
          )}`,
          "Cache-Control": "no-store, max-age=0",
        },
      });
    }

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const { data, error } = await supabase.auth.verifyOtp({
      token_hash: tokenHash,
      type,
    });

    if (error) {
      return new Response(null, {
        status: 302,
        headers: {
          Location: `${publicBaseUrl}/#/login?error=${encodeURIComponent(
            error.message || "Link za verifikaciju je istekao ili je već iskorišćen."
          )}`,
          "Cache-Control": "no-store, max-age=0",
        },
      });
    }

    const cleanNext = next.startsWith("/") ? next : `/${next}`;
    let targetUrl = `${publicBaseUrl}/#${cleanNext}`;
    if (data?.session) {
      const params = new URLSearchParams({
        access_token: data.session.access_token,
        refresh_token: data.session.refresh_token,
        expires_in: String(data.session.expires_in),
        token_type: "bearer",
        type: type,
      });
      targetUrl = `${publicBaseUrl}/#${cleanNext}#${params.toString()}`;
    }

    return new Response(null, {
      status: 302,
      headers: {
        Location: targetUrl,
        "Cache-Control": "no-store, max-age=0",
      },
    });
  } catch (err: any) {
    return new Response(null, {
      status: 302,
      headers: {
        Location: `${publicBaseUrl}/#/login?error=${encodeURIComponent(
          err?.message || "Greška pri obradi zahteva za verifikaciju."
        )}`,
        "Cache-Control": "no-store, max-age=0",
      },
    });
  }
}

export const onRequestGet: PagesFunction = async (context) => {
  return handleAuthConfirm(context.request, context.env);
};

export async function GET(request: Request): Promise<Response> {
  return handleAuthConfirm(request);
}
