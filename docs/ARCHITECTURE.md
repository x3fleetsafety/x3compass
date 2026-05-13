# X3 Compass — Architecture

## Stack

| Layer | Technology |
|---|---|
| Frontend (marketing + app) | Static HTML/CSS/JS on Cloudflare Pages |
| Database + Auth + Storage | Supabase (Postgres 15+, RLS) |
| Backend / API | Supabase Edge Functions (Deno) |
| AI | Anthropic Claude API (Haiku / Sonnet / Opus, multi-routed) |
| Billing | Stripe (Checkout + Customer Portal + Connect for Partners) |
| Email | Resend |
| SMS | Twilio (A2P 10DLC) |
| File storage | Supabase Storage (S3-compatible) |
| Analytics | Plausible (privacy-respecting) |
| Error monitoring | Sentry (free tier sufficient initially) |
| Domain | x3compass.com (Cloudflare DNS + Pages) |

## Multi-tenancy model

```
tenants
├── type: carrier_direct  (small carrier customer)
├── type: partner         (white-label safety consultant)
└── type: carrier_via_partner  (carrier served BY a Partner)
                                   └── parent_tenant → points to Partner

Partner sees: their own tenant + all child tenants
Carrier sees: their own tenant only
```

Row-level security (RLS) enforced at Postgres level via `user_tenant_ids(auth.uid())` function.

## Data flow

```
User opens chat
  ↓
POST /api/compass-agent
  ↓
Edge Function: compass-agent
  ↓ 1. Load conversation history (last 10 messages)
  ↓ 2. resolveModel(workflow, message) → Haiku/Sonnet/Opus
  ↓ 3. loadSkills(workflow, message) → 3-8 relevant SKILL.md files
  ↓ 4. buildSystemPrompt(skills, tenant_context)
  ↓ 5. Call Anthropic API with caching
  ↓ 6. Parse citations from response
  ↓ 7. Log message + cost to messages table
  ↓ 8. Update ai_usage_daily rollup
  ↓
Return reply + citations + cost
```

## Edge Functions

| Function | Purpose |
|---|---|
| compass-agent | Main AI chat |
| compass-onboarding | New tenant setup + driver intake |
| partner-billing | Partner subscription management + Stripe Connect |
| affiliate-tracker | Click attribution + conversion logging |
| reminders-cron | Daily sweep of upcoming compliance events |
| safety-meeting-generator | Weekly batched meeting agenda generation |
| audit-prep-async | Long-running audit prep document builds |
| dataq-scanner | Scan inspection events for contestable violations |
| usage-aggregator | Daily AI cost rollup |
| webhook-stripe | Subscription event handling |

## Skill loading (RAG)

Skills live in github.com/x3fleetsafety/skills (Apache 2.0). At Edge Function start:
1. Workflow → 3–5 default skill names
2. Message keywords → 1–3 additional skill names (deduplicated)
3. Fetch each skill's `SKILL.md` from raw.githubusercontent.com
4. In-memory cache (per Edge Function instance, ~5 minute lifetime)
5. Concatenate skill bodies into system prompt with cache control headers

No vector DB needed for v1. Keyword routing + workflow-default works at <100 skills.

## Why no vector DB?

At 100 skills, simple keyword routing is good enough. Vector embedding cost + infrastructure complexity isn't worth it. Reconsider at 500+ skills.

## Why Edge Functions vs Workers?

Supabase Edge Functions = same auth/DB context, simpler. Cloudflare Workers possible for high-traffic public endpoints later (affiliate-tracker, click logging).

## Security

- RLS on every tenant-scoped table
- Service role key only on Edge Functions (never client-side)
- API keys in environment variables (Supabase Vault for prod)
- Audit log on every customer interaction
- E&O insurance covers AI-driven advice
- SOC2 path planned for Year 2 (when serving Enterprise tier seriously)
