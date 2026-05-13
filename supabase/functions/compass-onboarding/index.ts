// X3 Compass — Onboarding Edge Function
// Handles new tenant signup + AI-led onboarding flow
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const STRIPE_SECRET = Deno.env.get("STRIPE_SECRET")!;

serve(async (req) => {
  if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });
  const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  const body = await req.json();

  // 1) Create tenant
  const { data: tenant } = await sb.from("tenants").insert({
    type: "carrier_direct",
    name: body.carrier_name,
    contact_email: body.email,
    contact_phone: body.phone,
    dot_number: body.dot_number,
    state: body.state,
    plan_tier: body.tier || "free",
    affiliate_ref: body.ref || null,
  }).select().single();

  // 2) Create user record
  const { data: user } = await sb.from("users").insert({
    email: body.email,
    name: body.name,
  }).select().single();

  // 3) Link user to tenant as owner
  await sb.from("tenant_users").insert({
    tenant_id: tenant?.id,
    user_id: user?.id,
    role: "owner",
  });

  // 4) Log affiliate conversion if applicable
  if (body.ref) {
    const { data: aff } = await sb.from("affiliates").select("id").eq("ref_code", body.ref).single();
    if (aff) {
      await sb.from("affiliate_conversions").insert({
        affiliate_id: aff.id,
        tenant_id: tenant?.id,
        conversion_type: "direct_subscription",
        plan_tier: body.tier || "free",
      });
    }
  }

  // 5) For paid tiers, create Stripe checkout session
  let checkout_url = null;
  if (body.tier && body.tier !== "free") {
    // Stripe Checkout (paid tiers)
    // ... implementation calls Stripe API and creates a checkout session
    checkout_url = `https://x3compass.com/app/onboarding-complete.html?tenant=${tenant?.id}`;
  } else {
    checkout_url = `/app/dashboard.html`;
  }

  return new Response(JSON.stringify({
    tenant_id: tenant?.id,
    user_id: user?.id,
    redirect: checkout_url,
  }), { headers: { "content-type": "application/json" } });
});
