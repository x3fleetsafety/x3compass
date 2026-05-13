# X3 Compass — Compliance Workflows

The 30 core workflows that Compass automates. Each is one or more skills wired into an AI agent flow.

## Daily workflows
1. **Driver expiry sweep** — CDL, medical card, MVR due dates → reminders
2. **New driver onboarding** — DQF completeness check + missing-item escalation
3. **Driver coaching draft** — dashcam event + AI-generated coaching message
4. **Roadside inspection logging** — driver reports inspection → DataQ candidate flagging
5. **Drug test scheduling** — random selection + collector site coordination

## Weekly workflows
6. **Safety meeting generation** — agenda + driver-facing email
7. **CSA percentile review** — trends + intervention recommendations
8. **Open coaching events** — outstanding driver coaching tasks
9. **Fleet maintenance review** — PM compliance + overdue items
10. **Driver scorecard update** — combined safety + ops + retention metrics

## Monthly workflows
11. **Compliance calendar review** — what's due in the next 30 days
12. **CSA monitoring digest** — month-over-month change per BASIC
13. **DataQ candidate review** — disputable violations + recommended actions
14. **Driver retention analysis** — turnover by dispatcher / by route
15. **Insurance claim review** — open + closed + LTV impact

## Quarterly workflows
16. **DOT audit readiness check** — full DQF + maintenance + 396 record sweep
17. **Annual MVR review** — every driver pulled + reviewed
18. **Clearinghouse annual query** — limited query per driver
19. **Drug & alcohol testing pool review** — eligibility + sample sizes
20. **Insurance renewal prep** — claim history + safety metrics + broker handoff
21. **Quarterly business review (Partner-served carriers)** — outcomes deck

## Annual workflows
22. **Annual safety policy refresh** — review handbook + drug policy + harassment policy
23. **Annual driver review** — performance + compensation + retention
24. **Insurance renewal** — broker engagement + market quote
25. **Tax filing prep** — 2290 HVUT + IFTA + per diem records
26. **MCS-150 biennial update** — when due

## Event-triggered workflows
27. **Crash response** — first-hour playbook + post-accident drug test + insurance notification
28. **OOS event response** — vehicle / driver out-of-service handling
29. **Substance-use disclosure** — SAP referral + Clearinghouse coordination + return-to-duty
30. **DOT audit notification** — 30-day audit prep sprint + document assembly + interview prep

Each workflow maps to specific skills (see x3fleetsafety/skills) + specific Edge Function logic. Together they represent the core Safety Director job — automated.
