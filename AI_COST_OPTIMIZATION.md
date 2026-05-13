# X3 Compass — AI Cost Optimization Playbook

**Goal:** Keep Anthropic API spend below 12% of revenue at every scale tier. Maximize Claude Max plan / batched usage. Make the unit economics work for $79/month customers.

---

## The cost math at scale

| Customers | Avg interactions/customer/day | Total daily interactions | Avg tokens per interaction (in+out) | Daily token volume | Monthly cost @ Sonnet blended | Cost % of revenue |
|---|---|---|---|---|---|---|
| 100 | 15 | 1,500 | 7,000 | 10.5M | $945 | 4.5% |
| 1,000 | 12 | 12,000 | 7,000 | 84M | $7,560 | 3.6% |
| 10,000 | 10 | 100,000 | 7,000 | 700M | $63,000 | 3.0% |
| 30,000 | 8 | 240,000 | 7,000 | 1.68B | $151,200 | 2.5% |

Assumes per-customer ACV of ~$150/mo blended. Note cost-percentage DECREASES with scale (interactions per customer trend down as users self-serve).

---

## Five cost-compression techniques (in priority order)

### 1. Multi-model routing (the biggest lever)

Not every question needs Sonnet. Many need Haiku. A few need Opus.

Implemented in `supabase/functions/compass-agent/_shared/llm.ts`:

| Workflow | Default model | When upgraded |
|---|---|---|
| Q&A (most questions) | **Sonnet** ($3 / $15 per M tok) | If contains fatality / litigation / unsat rating keywords → Opus |
| Audit prep | **Sonnet** | (always Sonnet) |
| Coaching draft | **Haiku** ($1 / $5 per M tok) | If complexity exceeds 1000 input tokens → Sonnet |
| Safety meeting | **Haiku** | (always Haiku — template work) |
| DataQ dispute | **Sonnet** | (always Sonnet) |
| Doc generation | **Haiku** | (always Haiku — template fill) |

Trivial queries ("when does this expire") drop to Haiku regardless of workflow.

**Cost impact:** ~40% reduction vs Sonnet-only baseline.

### 2. Prompt caching (Anthropic API native feature)

For high-traffic workflows, cache the system prompt + skill RAG content for 5 minutes:

```typescript
{
  "system": [
    { "type": "text", "text": "X3 Compass operating rules...", "cache_control": { "type": "ephemeral" } },
    { "type": "text", "text": skillContent, "cache_control": { "type": "ephemeral" } }
  ],
  ...
}
```

Cache hits are billed at **10% of normal input cost**. For repeated queries on the same workflow, this is a 9x cost reduction on the input side.

**Implementation:** Cache invalidates every 5 min naturally; for popular skills it stays hot.
**Cost impact:** ~30% reduction on input-token spend.

### 3. Context window discipline

Don't dump 50 skills into every prompt.

- Workflow-default skills only (3–5 skills per workflow)
- Keyword-triggered skills (1–3 more if relevant)
- Last 10 conversation turns max (not the whole history)
- Tenant context: name, plan tier, fleet size summary only — no raw driver list

**Average input tokens per query: 5,000–8,000** instead of 30,000+ if we dumped everything.

### 4. Response length caps

`max_tokens` capped per workflow:

| Workflow | max_tokens |
|---|---|
| Q&A | 1,500 |
| Coaching draft | 800 |
| Safety meeting | 2,000 |
| Audit prep | 4,000 |
| DataQ dispute | 1,500 |
| Doc generation | 3,000 |

If response truncates, user can ask follow-up. Better than always paying for 8K-token responses.

### 5. Batched + asynchronous workflows

Some workflows don't need real-time:
- **Audit prep generation** — happens overnight; batched and queued
- **Calendar reminder drafting** — pre-generated weekly, batched
- **Safety meeting agendas** — pre-generated for next 4 weeks, batched
- **DataQ dispute initial drafts** — generated within 24 hours, not real-time

Anthropic offers **batch API** at 50% discount for these. Real-time only when the customer is actively chatting.

**Cost impact:** ~25% reduction overall (40% of workflows can be batched).

---

## Claude Max plan strategy

If we're using a Max plan (vs pay-per-use):
- Allocate ~70% of Max budget to Sonnet usage during business hours
- Run batched workflows (audit prep, scheduled summaries) overnight to use remaining capacity
- Track per-minute usage; throttle if approaching cap

Claude Max gives us predictable monthly spend + unlimited tokens within the plan. The architecture above optimizes for it.

---

## Per-tenant usage caps

Free tier:
- 30 messages/month
- Haiku-only access (Sonnet locked)
- 800 max output tokens per message

Starter tier:
- 300 messages/month
- Sonnet default
- 1,500 max output tokens

Pro tier:
- 1,500 messages/month
- Sonnet default + Opus for high-stakes
- 3,000 max output tokens

Enterprise tier:
- Unlimited messages
- Full model access
- 4,000 max output tokens

This protects against runaway costs from a single customer and creates clear upgrade incentive.

---

## Daily monitoring

`ai_usage_daily` table (per migration 005) rolls up per-tenant, per-model token usage daily. Alerts:
- Any tenant exceeding $50/day → review usage pattern
- Daily total exceeding $500 → engineering review
- Model mix > 30% Opus → review prompt routing (likely false-trigger)
- Hallucination flags > 5% → emergency review

---

## Edge cases that drive cost up

- **Customer pastes a 50-page driver handbook** asking for review → cap input at 20K tokens; chunked review
- **Customer asks 200 follow-up questions in one conversation** → enforce per-conversation token budget
- **our compliance review team's office hours session** — recorded and transcribed; not real-time Claude
- **Audit-prep for 500-driver fleet** — batched + offered as add-on service (charged $499 separately)

---

## Anthropic relationship

Apply for **Anthropic Startup Program** as a vertical AI SaaS customer:
- Volume discount tier
- Co-marketing potential
- Direct technical contact for prompt optimization
- Early access to new models

This relationship is worth a 10–20% discount + faster issue resolution.

---

## Cost optimization KPIs (track weekly)

| KPI | Target |
|---|---|
| AI cost as % of revenue | < 12% |
| Cost per active customer per month | < $5 |
| Average tokens per interaction | < 8,000 |
| Cache hit rate on system prompts | > 60% |
| Haiku / Sonnet / Opus split | 40 / 55 / 5 |
| Daily Opus interactions | < 50 (Y1), < 500 (Y3) |
| Hallucination flags resolved | < 24 hours |

---

## Bottom line

A $79/mo customer generating $5–$15 of AI cost = **80–94% gross margin**. The architecture above keeps the floor at 84%+. The team executes on this discipline from day one.
