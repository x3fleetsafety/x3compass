-- Billing + Stripe sync

create table stripe_products (
  id              text primary key,              -- Stripe prod_*
  name            text not null,
  plan_tier       plan_tier,
  audience        text,                          -- 'direct', 'partner'
  active          boolean default true,
  created_at      timestamptz default now()
);

create table stripe_prices (
  id              text primary key,              -- Stripe price_*
  product_id      text not null references stripe_products(id),
  unit_amount     int not null,
  currency        text default 'usd',
  interval        text default 'month',
  active          boolean default true,
  created_at      timestamptz default now()
);

create table subscriptions (
  id              uuid primary key default gen_random_uuid(),
  tenant_id       uuid not null references tenants(id) on delete cascade,
  stripe_subscription_id text unique,
  stripe_customer_id text,
  status          subscription_status,
  plan_tier       plan_tier,
  current_period_end timestamptz,
  cancel_at_period_end boolean default false,
  trial_end       timestamptz,
  created_at      timestamptz default now()
);

create table invoices (
  id              uuid primary key default gen_random_uuid(),
  tenant_id       uuid not null references tenants(id),
  stripe_invoice_id text unique,
  amount_paid     int,
  amount_due      int,
  status          text,
  paid_at         timestamptz,
  created_at      timestamptz default now()
);
