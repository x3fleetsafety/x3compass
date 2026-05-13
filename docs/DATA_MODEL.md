# X3 Compass — Data Model

See `supabase/migrations/001_init.sql` through `005_audit_log.sql` for the canonical schema.

## Core entities

```
tenants ─┬─ drivers
         ├─ vehicles
         ├─ conversations ─ messages
         ├─ compliance_events
         ├─ subscriptions
         ├─ users (via tenant_users)
         └─ audit_log

partner_applications  (pipeline)
office_hours_sessions ─ office_hours_rsvps  (Partner monthly calls)

affiliates ─┬─ affiliate_clicks (tracking)
            ├─ affiliate_conversions (signups)
            └─ affiliate_payouts (Stripe transfers)

ai_usage_daily  (cost rollup)
ai_quality_log  (thumbs / hallucination flags)
```

## Key design decisions

1. **`tenant_type` enum** distinguishes direct carriers from partners from child carriers. Self-referential FK on `parent_tenant` lets partners see their children.

2. **`brand_config` JSONB on tenants** holds white-label config for Partners (logo URL, custom domain, primary/accent colors).

3. **`plan_tier` enum** is shared across direct and partner tiers (free / starter / pro / enterprise / partner). Easier billing logic.

4. **`compliance_events` table** is the single source of truth for "what's expiring when." Auto-seeded by trigger on driver insert when CDL or medical cert dates present.

5. **`messages.citations` JSONB** stores parsed CFR citations for audit defense ("we cited 49 CFR 382.701 in our advice").

6. **`audit_log` table** captures every customer-affecting action. Retained 7 years for compliance defense.

## RLS philosophy

- Service role bypasses RLS (Edge Functions and back-office)
- Authenticated users see only their tenants (and child tenants if partner)
- Anonymous users see only public marketing data
