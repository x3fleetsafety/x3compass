-- Already created in 001 — extending here for AI-specific events

create table ai_usage_daily (
  date            date not null,
  tenant_id       uuid not null references tenants(id) on delete cascade,
  model           text not null,                 -- 'claude-haiku-4-5', 'claude-sonnet-4-6', 'claude-opus-4-6'
  input_tokens    bigint default 0,
  output_tokens   bigint default 0,
  conversations   int default 0,
  cost_usd        numeric(12,4) default 0,
  primary key (date, tenant_id, model)
);

create table ai_quality_log (
  id              uuid primary key default gen_random_uuid(),
  message_id      uuid not null references messages(id),
  thumbs          int,                            -- 1 = up, -1 = down
  feedback_text   text,
  cfr_citations_validated boolean,
  hallucination_flagged boolean default false,
  reviewed_by     text,
  created_at      timestamptz default now()
);
