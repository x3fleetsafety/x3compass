// X3 Compass — LLM cost optimization layer
// Routes by complexity, loads skills as RAG, estimates cost

const MODELS = {
  haiku:  { name: "claude-haiku-4-5-20251001", input_per_mtok: 1.00,  output_per_mtok: 5.00 },
  sonnet: { name: "claude-sonnet-4-6",         input_per_mtok: 3.00,  output_per_mtok: 15.00 },
  opus:   { name: "claude-opus-4-6",           input_per_mtok: 15.00, output_per_mtok: 75.00 },
};

// Workflow → default model
const WORKFLOW_MODEL: Record<string, keyof typeof MODELS> = {
  qa:               "sonnet",        // Most Q&A needs reasoning
  audit_prep:       "sonnet",        // Heavy doc work
  coaching_draft:   "haiku",         // Simple drafting
  safety_meeting:   "haiku",         // Template-driven
  dataq_dispute:    "sonnet",        // Needs regulatory reasoning
  doc_gen:          "haiku",         // Template fill
};

// Phrases that trigger Opus upgrade (high-stakes scenarios)
const OPUS_TRIGGERS = [
  /fatality|fatal crash/i,
  /class action|federal court|litigation/i,
  /unsatisfactory rating/i,
  /imminent hazard/i,
  /complex audit defense/i,
];

// Phrases that drop to Haiku (super-simple queries)
const HAIKU_TRIGGERS = [
  /^(what is|when is|where is|how do i find)/i,
  /reminder|due date|expiry|expiration/i,
];

export function resolveModel(workflow: string, message: string): string {
  // Opus override for high-stakes
  if (OPUS_TRIGGERS.some(rx => rx.test(message))) {
    return MODELS.opus.name;
  }
  // Haiku override for trivial
  if (HAIKU_TRIGGERS.some(rx => rx.test(message))) {
    return MODELS.haiku.name;
  }
  // Default by workflow
  const tier = WORKFLOW_MODEL[workflow] || "sonnet";
  return MODELS[tier].name;
}

export function estimateCost(model: string, in_tokens: number, out_tokens: number): number {
  let m = MODELS.sonnet;
  if (model.includes("haiku")) m = MODELS.haiku;
  if (model.includes("opus")) m = MODELS.opus;
  return (in_tokens / 1_000_000) * m.input_per_mtok + (out_tokens / 1_000_000) * m.output_per_mtok;
}

// SKILL CATALOG
// Mapped to workflow → relevant skill files from x3fleetsafety/skills
const WORKFLOW_SKILLS: Record<string, string[]> = {
  qa: [
    "dot-compliance-fundamentals",
    "hours-of-service",
    "driver-qualification-file",
    "drug-and-alcohol-testing",
    "fmcsa-clearinghouse-workflow",
  ],
  audit_prep: [
    "dot-audit-readiness",
    "new-entrant-safety-audit-prep",
    "fmcsa-pre-employment-investigation-deep-dive",
    "driver-qualification-file",
    "vehicle-maintenance-records",
  ],
  coaching_draft: [
    "driver-coaching-conversations",
    "driver-discipline-and-progressive-correction",
    "fleet-safety-scorecard-design",
  ],
  safety_meeting: [
    "safety-meeting-agenda-templates",
    "safety-culture-and-management",
  ],
  dataq_dispute: [
    "dataq-disputes",
    "crash-preventability-determination",
    "roadside-inspection-levels",
  ],
  doc_gen: [
    "driver-qualification-file",
    "drug-and-alcohol-testing",
    "dot-compliance-fundamentals",
  ],
};

// Keyword-triggered skill loading (overrides / supplements workflow defaults)
const KEYWORD_SKILLS: Array<{ pattern: RegExp; skill: string }> = [
  { pattern: /hazmat|hazardous material|placard/i,           skill: "hazmat-basics" },
  { pattern: /cargo securement|tie-?down|chain/i,            skill: "cargo-securement" },
  { pattern: /clearinghouse/i,                                skill: "fmcsa-clearinghouse-workflow" },
  { pattern: /CSA|BASIC|percentile/i,                         skill: "csa-bsi-scoring" },
  { pattern: /DataQ|dispute|RDR/i,                            skill: "dataq-disputes" },
  { pattern: /medical (cert|card|exam)/i,                     skill: "medical-certification" },
  { pattern: /MVR|motor vehicle record/i,                     skill: "mvr-and-monitoring" },
  { pattern: /ELD|electronic logging/i,                       skill: "eld-mandate-compliance" },
  { pattern: /IFTA/i,                                         skill: "ifta-quarterly-prep" },
  { pattern: /2290|HVUT|heavy vehicle use tax/i,              skill: "state-trucking-taxes" },
  { pattern: /Canada|Canadian border/i,                       skill: "canada-cross-border-operations" },
  { pattern: /Mexico|Mexican border/i,                        skill: "mexico-cross-border-operations" },
  { pattern: /lease|TRAC|operating lease/i,                   skill: "lease-vs-buy-tractor-decision" },
  { pattern: /CPM|cost per mile/i,                            skill: "carrier-cost-per-mile-modeling" },
  { pattern: /MPG|fuel economy|fuel surcharge/i,              skill: "fuel-management-and-mpg-optimization" },
  { pattern: /retread|tire/i,                                 skill: "tire-management-program" },
  { pattern: /mental health|EAP|suicide|988/i,                skill: "trucker-mental-health-resources" },
  { pattern: /electric truck|EV|Tesla Semi/i,                 skill: "electric-truck-readiness" },
  { pattern: /autonomous|self-driving/i,                      skill: "autonomous-truck-implications" },
  { pattern: /BCP|disaster recovery|continuity/i,             skill: "carrier-disaster-recovery-and-bcp" },
];

// Load skill MD files from the skills repo (cached in Edge Function memory)
const SKILLS_BASE_URL = "https://raw.githubusercontent.com/x3fleetsafety/skills/main/skills";
const skillCache = new Map<string, string>();

export async function loadSkills(workflow: string, message: string): Promise<string[]> {
  const candidates = new Set<string>();
  // Workflow default skills
  for (const s of WORKFLOW_SKILLS[workflow] || []) candidates.add(s);
  // Keyword-triggered skills
  for (const { pattern, skill } of KEYWORD_SKILLS) {
    if (pattern.test(message)) candidates.add(skill);
  }

  // Fetch each skill's SKILL.md content (with caching)
  const contents: string[] = [];
  for (const skill of candidates) {
    if (skillCache.has(skill)) {
      contents.push(skillCache.get(skill)!);
      continue;
    }
    try {
      const r = await fetch(`${SKILLS_BASE_URL}/${skill}/SKILL.md`);
      if (r.ok) {
        const text = await r.text();
        skillCache.set(skill, text);
        contents.push(text);
      }
    } catch (e) {
      console.warn(`Failed to load skill ${skill}:`, e);
    }
  }
  return contents;
}

export function buildSystemPrompt(opts: {
  workflow: string;
  skills: string[];
  tenant_id: string;
  context?: Record<string, unknown>;
}): string {
  return `You are X3 Compass — the AI Virtual Safety Director for US motor carriers, operating in the "${opts.workflow}" workflow.

# Operating rules (always apply)

1. **Cite the CFR.** Every regulatory statement names the 49 CFR section. If you don't know the exact section, say so.
2. **Math over rhetoric.** Show the work on numbers.
3. **No legal advice.** For court / criminal / litigation, recommend transportation counsel.
4. **No medical advice.** For driver fitness questions, recommend a Certified Medical Examiner.
5. **Driver-first language.** Never "asset"; always "driver."
6. **Audit-ready by default.** Every recommendation considers what a DOT auditor would see.
7. **Confidence with humility.** When uncertain, say "I'd want to verify this with [specific source]."
8. **Reviewed by Mike Perry** — 20-year NY State Police CMV inspector. Match that standard.

# Knowledge base (loaded for this workflow)

${opts.skills.join("\n\n---\n\n")}

# Workflow guidance

${WORKFLOW_GUIDANCE[opts.workflow] || ""}

# Context

${JSON.stringify(opts.context || {}, null, 2)}

Tenant ID: ${opts.tenant_id}

Now respond to the user's question, applying the operating rules and grounded on the knowledge base above. Cite 49 CFR sections explicitly. Be concise unless the workflow calls for detail (audit_prep, doc_gen).`;
}

const WORKFLOW_GUIDANCE: Record<string, string> = {
  qa: "Answer the regulatory question with citations. Keep response under 300 words unless complexity requires more.",
  audit_prep: "Generate audit-prep content: punchlist, gap analysis, document templates. Be thorough.",
  coaching_draft: "Draft a coaching conversation script. Empathetic tone. Reference the specific event.",
  safety_meeting: "Generate a 15-30 minute safety meeting agenda. Topic-focused. Include 1 driver Q&A prompt.",
  dataq_dispute: "Draft a DataQ dispute. Cite the violation code. State the contestation ground clearly. Reference evidence requirements.",
  doc_gen: "Generate the requested document. Use plain language. Include all required FMCSA fields.",
};
