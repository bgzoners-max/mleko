// Edge Function: prima tiket i upisuje ga u DB.
// Push obaveštenje adminu ide preko DB triggera na notifications tabeli.
import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

interface TicketPayload {
  user_id: string
  user_email: string
  user_name: string
  category: "bug" | "pitanje" | "sugestija" | "ostalo"
  subject: string
  body: string
}

const CATEGORY_LABELS: Record<string, string> = {
  bug: "Greška / bug",
  pitanje: "Pitanje",
  sugestija: "Sugestija",
  ostalo: "Ostalo",
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders })
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    )

    const payload: TicketPayload = await req.json()

    // Validacija
    const { user_id, user_email, user_name, category, subject, body } = payload
    if (!user_id || !category || !subject || !body) {
      return new Response(JSON.stringify({ error: "Nedostaju obavezna polja" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      })
    }
    if (!["bug", "pitanje", "sugestija", "ostalo"].includes(category)) {
      return new Response(JSON.stringify({ error: "Nevažeća kategorija" }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      })
    }

    // Ubaci tiket u bazu (service role — zaobilazi RLS da bi trigger za ticket_number radio)
    const { data: ticket, error: dbError } = await supabase
      .from("support_tickets")
      .insert({ user_id, user_email, user_name, category, subject, body })
      .select("id, ticket_number")
      .single()

    if (dbError) throw dbError

    return new Response(
      JSON.stringify({ ticketNumber: ticket.ticket_number, id: ticket.id }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    )
  } catch (err) {
    console.error("send-support-ticket error:", err)
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    })
  }
})
