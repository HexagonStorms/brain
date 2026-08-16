---
name: project-actual-budget
description: Actual Budget self-hosted setup at budget.plaza.codes — accounts, income, bank sync, in-progress starting-budget generation.
metadata:
  type: project
---

Actual Budget is self-hosted at `budget.plaza.codes` (2026-08-15), Docker container `actual-budget` (`actualbudget/actual-server`, port 5006) in `elowynn-media-server/docker-compose.yml`, fronted by the elowynn Cloudflare Tunnel. Server password lives in `elowynn-media-server/.env` as `ACTUAL_SERVER_PASSWORD`.

Bank sync is via SimpleFIN Bridge ($1.50/mo or $15/yr) — all of Jo's bank accounts are imported with transaction history.

**Income/accounts (as of 2026-08-16, verify before trusting):** Paycheck currently lands in USAA. Jo may eventually move direct deposit to OnPoint Community Credit Union checking — no timeline given, don't assume it's happened without checking. Jo's own estimate of discretionary take-home is ~$9k/month; the plan is to verify this against actual USAA deposit history rather than trust the estimate.

**In progress:** building a starting zero-based budget by reading ~6 months of transaction history via `@actual-app/api`, clustering recurring payees into fixed-bill categories and bucketing variable spending by payee-name heuristics (no merchant-categorization API available, so labels need Jo's eyeball-check). Working script is throwaway, in the session scratchpad — not yet promoted into the repo as a reusable tool. Output gets proposed in chat first; nothing is written to the live budget without explicit sign-off, per [[feedback-consult-before-budget-changes]].

**How to apply:** Before doing budget-related work in a future session, re-verify this state (income, pay account, whether the starting budget was ever finished/applied) rather than assuming it's still current — this is exactly the kind of snapshot that goes stale fast.
