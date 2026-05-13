// X3 Compass — Affiliate Tracker Edge Function
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

serve(async (req) => {
  const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  const url = new URL(req.url);

  if (req.method === "POST" && url.pathname.endsWith("/click")) {
    const body = await req.json();
    const { data: aff } = await sb.from("affiliates").select("id").eq("ref_code", body.ref).single();
    if (!aff) return new Response("not found", { status: 404 });
    await sb.from("affiliate_clicks").insert({
      affiliate_id: aff.id,
      visitor_id: body.visitor_id,
      ip_hash: body.ip_hash,
      referrer: body.referrer,
      landing_page: body.landing_page,
      user_agent: body.user_agent,
    });
    return new Response("ok");
  }

  // payout-cycle (cron) — stub for now
  return new Response(JSON.stringify({ status: "ok" }), {
    headers: { "content-type": "application/json" },
  });
});
