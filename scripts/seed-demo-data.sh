#!/bin/bash
# Seed demo data for development / beta testing
set -e
psql "$DATABASE_URL" << SQL
-- Demo direct carrier
insert into tenants (id, type, name, contact_email, plan_tier, dot_number, state)
values ('00000000-0000-0000-0000-000000000001', 'carrier_direct', 'Apex Demo Transport', 'demo@apex.test', 'pro', '1234567', 'MI');

-- Demo partner
insert into tenants (id, type, name, contact_email, plan_tier, brand_config)
values ('00000000-0000-0000-0000-000000000002', 'partner', 'Smith Safety Solutions', 'demo@smithsafety.test', 'partner',
  '{"logo_url":"/assets/demo-partner-logo.png","custom_domain":"app.smithsafety.test","primary_color":"#1B3A6B","accent_color":"#FBBF24"}');

-- Demo carriers under partner
insert into tenants (type, parent_tenant, name, contact_email, plan_tier, dot_number)
values
  ('carrier_via_partner', '00000000-0000-0000-0000-000000000002', 'Acme Hauling', 'demo@acme.test', 'pro', '7654321'),
  ('carrier_via_partner', '00000000-0000-0000-0000-000000000002', 'Bravo Logistics', 'demo@bravo.test', 'pro', '5432167');

select 'Demo data seeded' as status;
SQL
