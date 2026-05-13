-- X3 Compass — Initial multi-tenant schema
-- Supabase Postgres 15+

-- =========================================================================
-- TENANT MODEL
-- =========================================================================
-- A "tenant" is either a direct carrier OR a partner (which contains carriers).
-- Direct carrier path: tenants → drivers, vehicles, conversations
-- Partner path:        tenants(parent) → tenants(child carriers) → drivers, vehicles
-- =========================================================================

create extension if not exists "pgcrypto";

create type tenant_type as enum ('carrier_direct', 'partner', 'carrier_via_partner');
create type plan_tier as enum ('free', 'starter', 'pro', 'enterprise', 'partner');
create type subscription_status as enum ('trialing', 'active', 'past_due', 'canceled', 'paused');

create table tenants (
  id              uuid primary key default gen_random_uuid(),
  type            tenant_type not null,
  parent_tenant   uuid references tenants(id),  -- carrier_via_partner points to partner
  name            text not null,
  legal_name      text,
  dot_number      text,
  mc_number       text,
  state           text,
  contact_email   text not null,
  contact_phone   text,
  brand_config    jsonb default '{}'::jsonb,    -- white-label config for partners
  plan_tier       plan_tier not null default 'free',
  status          subscription_status not null default 'trialing',
  trial_ends_at   timestamptz default (now() + interval '14 days'),
  stripe_customer text,
  stripe_subscription text,
  affiliate_ref   text,                          -- attribution
  partner_ref     uuid references tenants(id),  -- which partner brought them (alt to affiliate)
  created_at      timestamptz default now(),
  updated_at      timestamptz default now()
);
create index idx_tenants_parent on tenants(parent_tenant);
create index idx_tenants_type on tenants(type);
create index idx_tenants_status on tenants(status);

-- Users belong to one or many tenants (a partner sees both their own + child tenants)
create table users (
  id              uuid primary key default gen_random_uuid(),
  email           text unique not null,
  name            text,
  auth_user_id    uuid,                          -- Supabase auth.users link
  created_at      timestamptz default now()
);

create table tenant_users (
  tenant_id       uuid not null references tenants(id) on delete cascade,
  user_id         uuid not null references users(id) on delete cascade,
  role            text not null,                 -- owner, admin, dispatcher, driver, viewer
  created_at      timestamptz default now(),
  primary key (tenant_id, user_id)
);

-- =========================================================================
-- FLEET ENTITIES (per-tenant)
-- =========================================================================
create table drivers (
  id              uuid primary key default gen_random_uuid(),
  tenant_id       uuid not null references tenants(id) on delete cascade,
  first_name      text not null,
  last_name       text not null,
  email           text,
  phone           text,
  date_of_birth   date,
  cdl_number      text,
  cdl_state       text,
  cdl_class       text,
  cdl_expires_at  date,
  medical_cert_expires_at date,
  hire_date       date,
  termination_date date,
  clearinghouse_status text,
  notes           text,
  metadata        jsonb default '{}'::jsonb,
  created_at      timestamptz default now()
);
create index idx_drivers_tenant on drivers(tenant_id);
create index idx_drivers_cdl_expiry on drivers(cdl_expires_at);
create index idx_drivers_med_expiry on drivers(medical_cert_expires_at);

create table vehicles (
  id              uuid primary key default gen_random_uuid(),
  tenant_id       uuid not null references tenants(id) on delete cascade,
  unit_number     text not null,
  vin             text,
  year            int,
  make            text,
  model           text,
  vehicle_type    text,                          -- tractor, trailer, etc.
  in_service      boolean default true,
  metadata        jsonb default '{}'::jsonb,
  created_at      timestamptz default now()
);
create index idx_vehicles_tenant on vehicles(tenant_id);

-- =========================================================================
-- AI CONVERSATIONS
-- =========================================================================
create type message_role as enum ('user', 'assistant', 'system', 'tool');

create table conversations (
  id              uuid primary key default gen_random_uuid(),
  tenant_id       uuid not null references tenants(id) on delete cascade,
  user_id         uuid references users(id),
  workflow        text,                          -- 'qa', 'audit_prep', 'coaching_draft', etc.
  title           text,
  metadata        jsonb default '{}'::jsonb,
  created_at      timestamptz default now(),
  updated_at      timestamptz default now()
);
create index idx_conversations_tenant on conversations(tenant_id);

create table messages (
  id              uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references conversations(id) on delete cascade,
  role            message_role not null,
  content         text not null,
  model           text,                          -- 'claude-haiku-4-5', 'claude-sonnet-4-6', etc.
  input_tokens    int,
  output_tokens   int,
  cost_usd        numeric(10,6),
  citations       jsonb,                          -- CFR citations attached
  workflow_step   text,
  created_at      timestamptz default now()
);
create index idx_messages_convo on messages(conversation_id);

-- =========================================================================
-- CALENDAR + REMINDERS
-- =========================================================================
create table compliance_events (
  id              uuid primary key default gen_random_uuid(),
  tenant_id       uuid not null references tenants(id) on delete cascade,
  event_type      text not null,                 -- 'cdl_expiry', 'medical_expiry', 'mvr_due', 'audit_due', '2290_due', etc.
  related_driver  uuid references drivers(id),
  related_vehicle uuid references vehicles(id),
  due_date        date not null,
  reminder_30     boolean default false,
  reminder_14     boolean default false,
  reminder_7      boolean default false,
  reminder_1      boolean default false,
  completed_at    timestamptz,
  metadata        jsonb default '{}'::jsonb,
  created_at      timestamptz default now()
);
create index idx_events_tenant on compliance_events(tenant_id);
create index idx_events_due on compliance_events(due_date);

-- =========================================================================
-- AUDIT LOG (all customer interactions logged for compliance defense)
-- =========================================================================
create table audit_log (
  id              uuid primary key default gen_random_uuid(),
  tenant_id       uuid references tenants(id) on delete set null,
  user_id         uuid references users(id),
  action          text not null,
  resource_type   text,
  resource_id     uuid,
  details         jsonb,
  ip_address      inet,
  user_agent      text,
  created_at      timestamptz default now()
);
create index idx_audit_tenant on audit_log(tenant_id);
create index idx_audit_created on audit_log(created_at);

-- =========================================================================
-- RLS POLICIES
-- =========================================================================
alter table tenants enable row level security;
alter table drivers enable row level security;
alter table vehicles enable row level security;
alter table conversations enable row level security;
alter table messages enable row level security;
alter table compliance_events enable row level security;

-- Helper function: which tenants does this user have access to?
create or replace function user_tenant_ids(p_user_id uuid)
returns table (tenant_id uuid) language sql security definer set search_path = public as $$
  -- Direct membership
  select tu.tenant_id from tenant_users tu where tu.user_id = p_user_id
  union
  -- Partner sees their child carriers
  select t.id from tenants t
  inner join tenant_users tu on tu.tenant_id = t.parent_tenant
  where tu.user_id = p_user_id
$$;

create policy "tenants_select_own" on tenants for select
  using (id in (select tenant_id from user_tenant_ids(auth.uid())));
create policy "drivers_select_own" on drivers for select
  using (tenant_id in (select tenant_id from user_tenant_ids(auth.uid())));
create policy "vehicles_select_own" on vehicles for select
  using (tenant_id in (select tenant_id from user_tenant_ids(auth.uid())));
create policy "conversations_select_own" on conversations for select
  using (tenant_id in (select tenant_id from user_tenant_ids(auth.uid())));
create policy "messages_select_own" on messages for select
  using (conversation_id in (select id from conversations where tenant_id in (select tenant_id from user_tenant_ids(auth.uid()))));
create policy "events_select_own" on compliance_events for select
  using (tenant_id in (select tenant_id from user_tenant_ids(auth.uid())));

-- =========================================================================
-- TRIGGERS
-- =========================================================================
create or replace function touch_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;
create trigger trg_tenants_touch before update on tenants
  for each row execute function touch_updated_at();
create trigger trg_conversations_touch before update on conversations
  for each row execute function touch_updated_at();

-- Seed: when a driver is inserted with CDL expiry, auto-create compliance_event
create or replace function seed_driver_events()
returns trigger language plpgsql as $$
begin
  if new.cdl_expires_at is not null then
    insert into compliance_events (tenant_id, event_type, related_driver, due_date)
    values (new.tenant_id, 'cdl_expiry', new.id, new.cdl_expires_at);
  end if;
  if new.medical_cert_expires_at is not null then
    insert into compliance_events (tenant_id, event_type, related_driver, due_date)
    values (new.tenant_id, 'medical_expiry', new.id, new.medical_cert_expires_at);
  end if;
  return new;
end;
$$;
create trigger trg_seed_driver_events after insert on drivers
  for each row execute function seed_driver_events();
