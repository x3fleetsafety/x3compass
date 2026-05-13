// X3 Compass — AI Agent Edge Function
// Cost-optimized: routes simple queries to Haiku, complex ones to Sonnet, rare ones to Opus
// Skills repo loaded as RAG context (no fine-tuning, no embeddings needed for v1)

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { resolveModel, loadSkills, estimateCost, buildSystemPrompt } from "./_shared/llm.ts";

const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

interface AgentRequest {
  tenant_id: string;
  user_id?: string;
  conversation_id?: string;
  workflow: "qa" | "audit_prep" | "coaching_draft" | "safety_meeting" | "dataq_dispute" | "doc_gen";
  message: string;
  context?: Record<string, unknown>;
}

interface AgentResponse {
  conversation_id: string;
  message_id: string;
  reply: string;
  citations: Array<{ cfr: string; description: string }>;
  model: string;
  cost_usd: number;
}

serve(async (req: Request) => {
  if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });
  const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  try {
    const body = await req.json() as AgentRequest;
    const { tenant_id, user_id, workflow, message, context } = body;

    // 1) Get or create conversation
    let conversation_id = body.conversation_id;
    if (!conversation_id) {
      const { data: conv } = await sb.from("conversations").insert({
        tenant_id, user_id, workflow,
        title: message.substring(0, 80),
      }).select("id").single();
      conversation_id = conv?.id;
    }

    // 2) Pull conversation history (last 10 turns for context)
    const { data: history } = await sb.from("messages")
      .select("role, content")
      .eq("conversation_id", conversation_id)
      .order("created_at", { ascending: true })
      .limit(10);

    // 3) Route to appropriate model based on workflow + content complexity
    const model = resolveModel(workflow, message);

    // 4) Load relevant skills as RAG context
    //    Skill selection: workflow-default + keyword-triggered
    const skills = await loadSkills(workflow, message);

    // 5) Build system prompt grounded on skills
    const system = buildSystemPrompt({
      workflow,
      skills,
      tenant_id,
      context,
    });

    // 6) Save user message
    const { data: userMsg } = await sb.from("messages").insert({
      conversation_id,
      role: "user",
      content: message,
    }).select("id").single();

    // 7) Call Claude
    const claudeResp = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "x-api-key": ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
      },
      body: JSON.stringify({
        model,
        max_tokens: workflow === "audit_prep" ? 4000 : 1500,
        system,
        messages: [
          ...(history || []).map(m => ({ role: m.role === "assistant" ? "assistant" : "user", content: m.content })),
          { role: "user", content: message },
        ],
      }),
    });
    const claudeData = await claudeResp.json();
    const reply = claudeData.content[0]?.text || "Sorry, I couldn't generate a response.";
    const input_tokens = claudeData.usage?.input_tokens || 0;
    const output_tokens = claudeData.usage?.output_tokens || 0;
    const cost_usd = estimateCost(model, input_tokens, output_tokens);

    // 8) Extract CFR citations (regex on the response)
    const citationMatches = reply.match(/49 CFR (\d+\.\d+(?:\([a-z0-9]+\))?)/g) || [];
    const citations = citationMatches.map(c => ({ cfr: c, description: "" }));

    // 9) Save assistant message + log usage
    const { data: asstMsg } = await sb.from("messages").insert({
      conversation_id,
      role: "assistant",
      content: reply,
      model,
      input_tokens,
      output_tokens,
      cost_usd,
      citations,
    }).select("id").single();

    // 10) Update daily AI usage rollup (for cost monitoring)
    const today = new Date().toISOString().slice(0, 10);
    await sb.rpc("upsert_ai_usage", {
      p_date: today,
      p_tenant_id: tenant_id,
      p_model: model,
      p_input_tokens: input_tokens,
      p_output_tokens: output_tokens,
      p_cost: cost_usd,
    });

    const response: AgentResponse = {
      conversation_id: conversation_id!,
      message_id: asstMsg?.id || "",
      reply,
      citations,
      model,
      cost_usd,
    };

    return new Response(JSON.stringify(response), {
      headers: { "content-type": "application/json" },
    });
  } catch (err) {
    console.error("Agent error:", err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { "content-type": "application/json" },
    });
  }
});
