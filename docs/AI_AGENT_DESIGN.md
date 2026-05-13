# X3 Compass — AI Agent Design

## Principles

1. **Skill-grounded, not opinion-based.** Every workflow loads relevant SKILL.md files as RAG context. Claude's output is filtered through those skills, not its training data alone.

2. **CFR citation enforced.** Every regulatory claim must name the 49 CFR section. Validated post-generation via regex match against known section format.

3. **Confidence + humility.** When uncertain, the agent says so. Better to say "verify with counsel" than to fabricate.

4. **Tone calibrated to audience.** Direct customer? Friendly + professional. Partner-served carrier (white-label)? Partner's brand voice (configurable). Driver-facing message draft? Plain English, respectful.

5. **Cost-aware.** Each query routes to the cheapest model that can handle it (see `AI_COST_OPTIMIZATION.md`).

## Workflows

Each workflow has:
- Default model (Haiku / Sonnet / Opus)
- Default skill set (3–5 SKILL.md files always loaded)
- Keyword-triggered additional skills
- Max output tokens cap
- System-prompt template

### Q&A (most common)
Customer asks a regulatory question. Compass answers with CFR citation.
- Model: Sonnet (Opus for high-stakes triggers)
- Skills: foundations + topic-triggered
- Max tokens: 1,500

### Audit prep
Generate audit-ready punchlist + document templates.
- Model: Sonnet
- Skills: dot-audit-readiness, new-entrant-safety-audit-prep, driver-qualification-file, etc.
- Max tokens: 4,000
- Often batched + async

### Coaching draft
Draft a coaching conversation for a driver event.
- Model: Haiku (template-driven)
- Skills: driver-coaching-conversations, driver-discipline-and-progressive-correction
- Max tokens: 800
- Event-aware (uses driver context)

### Safety meeting
Generate a weekly safety meeting agenda.
- Model: Haiku
- Skills: safety-meeting-agenda-templates, safety-culture-and-management
- Max tokens: 2,000
- Batched (pre-generated for the week)

### DataQ dispute
Draft a DataQ challenge letter.
- Model: Sonnet
- Skills: dataq-disputes, crash-preventability-determination, roadside-inspection-levels
- Max tokens: 1,500
- Real-time (customer engagement moment)

### Document generation
Fill templates: safety policy, DQF, drug-test policy.
- Model: Haiku
- Skills: relevant compliance skills + template
- Max tokens: 3,000
- Template-driven

## Tools (agent can call these)

(Phase 2 — not in MVP but planned)

- `get_driver(driver_id)` — fetch driver record for context
- `list_expiring_events(days)` — pull upcoming compliance events
- `flag_dataq_candidate(inspection_id)` — mark an inspection for review
- `generate_doc(template, fields)` — create a PDF document
- `send_reminder(driver_id, channel, message)` — trigger SMS/email
- `schedule_audit_prep(target_date)` — queue async audit-prep job

## Hallucination defense

1. **CFR validation:** parse citations, regex check against valid format, optionally verify against ecfr.gov
2. **Confidence scoring:** if response includes hedging language ("might be" / "I think"), surface to user with verify-with-counsel prompt
3. **Thumbs-down feedback:** every message has thumbs up/down; downs queued for our compliance review team weekly review
4. **Adversarial test set:** weekly batch of 100 prompts run by our compliance review team to spot regressions
5. **Hallucination flagging:** customer can flag a response; auto-creates ticket in ai_quality_log
