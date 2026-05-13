-- Partner-specific schema additions

-- Partner application pipeline
create type partner_app_status as enum ('pending', 'interview', 'approved', 'rejected', 'activated');
create table partner_applications (
  id              uuid primary key default gen_random_uuid(),
  name            text not null,
  email           text not null,
  experience_yrs  int,
  role            text,
  why_apply       text,
  current_clients int,
  status          partner_app_status default 'pending',
  reviewed_by     text,
  reviewed_at     timestamptz,
  notes           text,
  created_at      timestamptz default now()
);

-- Partner white-label configuration (extends tenants.brand_config)
-- This is a typed view over brand_config for partner tenants
create view v_partner_brand as
select
  t.id as tenant_id,
  t.name,
  (t.brand_config->>'logo_url') as logo_url,
  (t.brand_config->>'custom_domain') as custom_domain,
  (t.brand_config->>'primary_color') as primary_color,
  (t.brand_config->>'accent_color') as accent_color,
  (t.brand_config->>'company_url') as company_url
from tenants t
where t.type = 'partner';

-- Partner monthly office hours (Mike Perry)
create table office_hours_sessions (
  id              uuid primary key default gen_random_uuid(),
  scheduled_for   timestamptz not null,
  topic           text,
  zoom_url        text,
  recording_url   text,
  created_at      timestamptz default now()
);
create table office_hours_rsvps (
  session_id      uuid not null references office_hours_sessions(id),
  tenant_id       uuid not null references tenants(id),
  user_id         uuid references users(id),
  question        text,
  attended        boolean,
  primary key (session_id, tenant_id)
);

-- Partner-Carrier billing routing
-- Carrier-via-partner pays the partner. Partner pays X3 $499 flat.
-- Carrier payments to partner are NOT routed through X3 unless partner opts into payment hub.
create table partner_payment_hub_optin (
  partner_tenant_id uuid primary key references tenants(id) on delete cascade,
  stripe_connect_account text,
  hub_active      boolean default false,
  enabled_at      timestamptz,
  created_at      timestamptz default now()
);
