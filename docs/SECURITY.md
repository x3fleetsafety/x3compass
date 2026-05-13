# X3 Compass — Security

## Data classification

| Class | Examples | Storage |
|---|---|---|
| Public | Marketing site, skill content | CDN, public repo |
| Customer | Driver names, fleet roster, conversation history | Supabase encrypted at rest |
| Sensitive | SSN snippets, drug test results, medical examiner notes | Supabase encrypted + field-level encryption (Phase 2) |
| Credentials | API keys, integration tokens | Supabase Vault |

## Authentication
- Supabase Auth (email + password, magic link, OAuth)
- MFA optional Phase 1, mandatory Enterprise tier
- Session length: 30 days (refresh tokens)
- Force re-auth on sensitive actions (billing changes, white-label rebrand)

## Authorization
- Row-level security (RLS) on every tenant-scoped table
- Service role only on Edge Functions
- API keys never client-side
- Audit log on every privileged action

## Encryption
- In transit: TLS 1.3
- At rest: Supabase managed (AES-256)
- Field-level encryption (Phase 2): SSN partial, medical examiner notes

## API security
- Anthropic API key: env variable in Edge Function (Vault prod)
- Stripe: server-only secret key
- Webhook signature verification on Stripe + Twilio inbound

## Compliance posture
- Privacy policy + ToS reviewed annually by counsel
- DPA available for Enterprise customers
- GDPR + CCPA data subject request handling
- Path to SOC2 Type II in Year 2 (when Enterprise tier scales)
- HIPAA NOT in scope (we don't handle PHI directly)

## Incident response
- Cyber incident detection: Sentry + Cloudflare WAF
- Response: documented playbook in carrier-disaster-recovery-and-bcp skill
- Notification: customers within 72 hours of confirmed breach
- Insurance: cyber liability $2M coverage
- External breach-response firm on retainer

## Pen testing
- Annual third-party pen test (Year 2+)
- Bug bounty program (Year 3+)
