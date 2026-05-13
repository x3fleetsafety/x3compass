# X3 Compass

> **The AI Virtual Safety Director for small motor carriers.**

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![Powered by X3 Skills](https://img.shields.io/badge/powered_by-100_X3_skills-1B3A6B)](https://github.com/x3fleetsafety/skills)
[![Live at x3compass.com](https://img.shields.io/badge/live-x3compass.com-2DD4BF)](https://x3compass.com)

X3 Compass replaces a $130K/year Safety Director with an AI agent that knows 49 CFR cold, watches every driver file, flags every audit risk, drafts every safety meeting, and answers every regulatory question — for $79–$999/month, self-serve, 100% automated.

Built on the **[X3 100-skill open-source corpus](https://github.com/x3fleetsafety/skills)** + Claude. Reviewed by Mike Perry, 20-year NY State Police CMV inspector.

---

## Two revenue rails

### 🧭 Direct (carriers buy Compass themselves)
- **Free** — 1 truck, viral lead-gen
- **Starter $79/mo** — 1–10 trucks
- **Pro $299/mo** — 11–50 trucks
- **Enterprise $999/mo** — 51–250 trucks

### 🤝 Partner (safety consultants license Compass)
- **$499/mo flat** — unlimited carrier seats, white-label, reseller license, monthly Mike Perry office hours

**5-year combined target: $72M ARR** with ~15 person team.

---

## Architecture

```
┌──────────────────────────────────────────────────────┐
│  x3compass.com — Cloudflare Pages (marketing + app)  │
└────────┬─────────────────────────────────────────────┘
         │
┌────────▼─────────────────────────────────────────────┐
│  Supabase (multi-tenant Postgres + Auth + Storage)   │
│  • carriers, drivers, vehicles, partners             │
│  • conversations, audit_log                          │
│  • Stripe sync                                       │
└────────┬─────────────────────────────────────────────┘
         │
┌────────▼─────────────────────────────────────────────┐
│  Edge Functions (Deno)                               │
│  • compass-agent      — chat + workflows             │
│  • compass-onboarding — new carrier setup            │
│  • partner-billing    — white-label routing          │
│  • affiliate-tracker  — referral attribution         │
└────────┬─────────────────────────────────────────────┘
         │
┌────────▼─────────────────────────────────────────────┐
│  Claude (Anthropic API)                              │
│  • Haiku  — routing + classification (cheap)         │
│  • Sonnet — workflows + advice (default)             │
│  • Opus   — complex audit/legal scenarios (rare)     │
│  • Skills repo as RAG (no fine-tuning)               │
└──────────────────────────────────────────────────────┘
```

## Repository layout

```
x3compass/
├── README.md                    — you are here
├── BUSINESS_PLAN.md             — vision, ICP, financials
├── ROADMAP.md                   — 90-day MVP → 5-year plan
├── MONETIZATION.md              — 7 revenue streams
├── AFFILIATE_PROGRAM.md         — referral economics + tracking
├── AI_COST_OPTIMIZATION.md      — Anthropic spend compression playbook
├── BRAND.md                     — voice, palette, naming
├── PARTNER_PROGRAM.md           — white-label reseller model
├── LICENSE                      — Apache 2.0
├── site/                        — public marketing site
│   ├── index.html               — hero, value props, social proof
│   ├── pricing.html             — Direct tier pricing
│   ├── partners.html            — Partner program landing
│   ├── mike.html                — Mike Perry credibility page
│   ├── affiliate.html           — affiliate program signup
│   ├── about.html               — story + team
│   ├── skills.html              — 100-skill catalog (uses x3fleetsafety/skills)
│   ├── faq.html                 — common questions
│   ├── compare.html             — vs JJ Keller / Foley / Compliance Navigator
│   └── assets/                  — css, js, images
├── app/                         — customer-facing application
│   ├── signup.html              — self-serve signup
│   ├── onboarding.html          — AI-led onboarding
│   ├── dashboard.html           — main app
│   ├── chat.html                — AI chat interface
│   ├── drivers.html             — driver roster
│   ├── calendar.html            — compliance calendar
│   ├── audit-prep.html          — audit prep generator
│   ├── settings.html            — account settings
│   └── partner/                 — partner-only views
│       ├── partner-dashboard.html
│       ├── partner-carriers.html
│       ├── partner-onboarding.html
│       └── partner-branding.html — white-label config
├── supabase/
│   ├── migrations/
│   │   ├── 001_init.sql
│   │   ├── 002_partners.sql
│   │   ├── 003_billing.sql
│   │   ├── 004_affiliate.sql
│   │   └── 005_audit_log.sql
│   └── functions/
│       ├── compass-agent/       — main AI chat
│       ├── compass-onboarding/  — new carrier setup
│       ├── partner-billing/     — white-label revenue routing
│       └── affiliate-tracker/   — referral attribution
├── docs/
│   ├── ARCHITECTURE.md
│   ├── DATA_MODEL.md
│   ├── AI_AGENT_DESIGN.md
│   ├── PARTNER_ONBOARDING.md
│   ├── COMPLIANCE_WORKFLOWS.md  — the 30 core workflows
│   └── SECURITY.md
├── scripts/
│   ├── deploy.sh
│   ├── seed-demo-data.sh
│   └── sync-skills.sh           — pull latest 100 skills from x3fleetsafety/skills
└── brand/
    ├── logo.svg
    ├── palette.css
    └── voice.md
```

## Quick start (after fork or clone)

```bash
# Install
git clone https://github.com/x3fleetsafety/x3compass.git
cd x3compass

# Sync skills (pulls latest from x3fleetsafety/skills)
./scripts/sync-skills.sh

# Deploy
./scripts/deploy.sh
```

## Status

This is the **initial vision build (May 2026)**. MVP launch target: August 2026.

- ✅ Repo + structure
- ✅ Marketing site shell
- ✅ Multi-tenant schema
- ✅ AI agent Edge Function
- ✅ Partner program design
- ✅ Affiliate program design
- ✅ Monetization framework
- ⏳ Beta with 30 closed customers (target: July 2026)
- ⏳ Public Direct launch (target: August 2026)
- ⏳ Partner program launch (target: November 2026)

## License

Apache 2.0. The X3 100-skill corpus this is built on is also Apache 2.0. Fork freely.

## Maintained by

**X3 Fleet Safety** — DOT compliance for small US motor carriers.
Senior regulatory advisor: **Mike Perry**, 20-year NY State Police CMV inspector, 10,000+ inspections.
Founder: **Joshua Kovarik** (joshua@x3fleetsafety.com).
