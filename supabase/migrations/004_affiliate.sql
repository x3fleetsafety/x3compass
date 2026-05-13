-- Affiliate program

create type affiliate_status as enum ('pending', 'active', 'paused', 'terminated');

create table affiliates (
  id              uuid primary key default gen_random_uuid(),
  name            text not null,
  email           text unique not null,
  ref_code        text unique not null,
  audience_type   text,                          -- 'influencer', 'broker', 'cpa', 'community', 'school', 'customer'
  audience_size   text,
  channel_url     text,
  status          affiliate_status default 'pending',
  stripe_connect_account text,
  payout_method   text default 'stripe',
  commission_pct  numeric(5,2) default 30.00,   -- 30% lifetime recurring
  partner_bounty_usd int default 200,            -- one-time per approved Partner
  total_referrals int default 0,
  total_paid_usd  numeric(10,2) default 0,
  applied_at      timestamptz default now(),
  approved_at     timestamptz
);

-- Tracks every click from an affiliate link (used to set the 30-day cookie attribution)
create table affiliate_clicks (
  id              uuid primary key default gen_random_uuid(),
  affiliate_id    uuid not null references affiliates(id),
  visitor_id      text,                          -- cookie-tracked
  ip_hash         text,                          -- privacy: hash, not raw
  referrer        text,
  landing_page    text,
  user_agent      text,
  created_at      timestamptz default now()
);

-- A conversion happens when a referred visitor signs up + pays
create table affiliate_conversions (
  id              uuid primary key default gen_random_uuid(),
  affiliate_id    uuid not null references affiliates(id),
  tenant_id       uuid not null references tenants(id),
  conversion_type text,                          -- 'direct_subscription', 'partner_signup'
  plan_tier       plan_tier,
  attributed_at   timestamptz default now()
);

-- Commission payouts (Stripe transfers)
create table affiliate_payouts (
  id              uuid primary key default gen_random_uuid(),
  affiliate_id    uuid not null references affiliates(id),
  period_start    date,
  period_end      date,
  amount_usd      numeric(10,2),
  stripe_transfer_id text,
  paid_at         timestamptz,
  created_at      timestamptz default now()
);
