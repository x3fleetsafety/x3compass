# X3 Compass — Affiliate Program

## Structure
- **30% lifetime recurring** on Direct customer subscriptions (Starter / Pro / Enterprise)
- **$200 one-time bounty** on every approved Compass Partner
- **No tier system.** Same rate for everyone — no gatekeeping, no quotas.
- **30-day cookie window** — referrer of a click gets credit for any signup within 30 days
- **Stripe Express payouts** on the 15th of each month
- **Real-time dashboard** at affiliate.x3compass.com — tracks clicks → signups → conversions

## Audiences we target
1. **Trucking content creators** (YouTube, TikTok, podcasts, Instagram)
2. **Insurance brokers** serving small motor carriers
3. **CPAs/accountants** specializing in trucking
4. **Driver community moderators** (forums, Facebook groups)
5. **Trucking schools** (graduates start carriers)
6. **Existing Compass customers** (peer referral)
7. **Industry consultants** who aren't a fit for Partner tier

## Application + approval flow
1. Apply at x3compass.com/affiliate (60-second form)
2. Audience review by our partnerships team
3. Approval within 24 hours
4. Stripe Express onboarding for payouts
5. Custom UTM-tagged link: `x3compass.com/?ref=YOURNAME`
6. Asset library access: banners, video scripts, email templates

## Tracking + attribution
- **First-touch attribution** within 30-day cookie window
- **Visitor cookie** stores `?ref=` parameter for 30 days
- **localStorage backup** for cookie-disabled browsers
- **IP hash** (privacy-preserving) as secondary signal
- **All signups** include `affiliate_ref` field on tenant record
- **Database table** `affiliate_conversions` joins affiliate to tenant

## Commission lifecycle
| Event | Affiliate earns |
|---|---|
| Click on affiliate link | $0 (tracked) |
| Visitor signs up (free tier) | $0 (tracked) |
| Visitor upgrades to paid Starter ($79) | $23.70/mo recurring |
| Visitor upgrades to Pro ($299) | $89.70/mo recurring |
| Visitor upgrades to Enterprise ($999) | $299.70/mo recurring |
| Visitor approved as Partner ($499/mo) | $200 one-time + (no recurring on Partner tier) |
| Customer cancels | Commission stops next billing cycle |

## Anti-fraud
- Self-referrals disallowed
- Same-IP / same-email duplicates flagged
- Clawback if customer cancels within 60 days
- Stripe Express KYC required before payout

## Real-numbers projections
| Affiliate tier | Direct refs / mo | Partner refs / mo | Mo income | Year-1 income |
|---|---|---|---|---|
| Casual (1 ref/mo) | 1 Starter | 0 | ~$24 | ~$285 |
| Side-hustle | 5 Pro | 1 | ~$1,300 | ~$15K |
| Engaged influencer | 20 Pro | 3 | ~$5,300 | ~$63K |
| Pro affiliate / consultant | 50 Pro + 10 Partners | | ~$15K | ~$180K |
| Industry leader | 200 Pro + 30 Partners | | ~$55K | ~$660K |

## What we provide affiliates
- 30 pre-built banner ads (multiple sizes)
- 10 email templates (cold + warm)
- 5 video scripts (60 / 90 / 180 second)
- Landing page templates
- Expert-fronted YouTube clips (free to embed)
- Real-time dashboard with attribution
- Monthly affiliate-only webinar with X3 leadership

## Top-affiliate accelerator
Affiliates over $5K/month MRR get:
- Quarterly 1:1 strategy call
- Co-marketing opportunities (sponsored content)
- Early access to new Compass features
- Affiliate-of-the-Year recognition (annual)

## Legal
- Standard affiliate agreement (will be drafted by counsel before launch)
- FTC-compliant disclosure required ("affiliate link" or "I may earn commission")
- Compliance with state seller registration where applicable
