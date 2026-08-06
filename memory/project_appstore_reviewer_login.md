---
name: project_appstore_reviewer_login
description: "App-store reviewer login to plfog, and the unresolved in-process vs over-HTTP bug that still blocks it."
metadata: 
  node_type: memory
  type: project
  originSessionId: 0a0c512b-e546-4d73-8fb9-0d9174b21bd6
  modified: 2026-08-05T23:38:13.543Z
---

plfog login is passwordless email codes, which store reviewers can't receive. As of 2026-08-05 (PR #175, merged, live in v0.23.49) the carve-out is a **golden ticket**: `GoldenTicketConfirmLoginCodeForm` accepts `PLAY_REVIEW_CODE` at *verification* time for any pending login, in addition to the real emailed code. Jo chose "any email" knowingly; it is a master key, and an `ADMIN_DOMAINS` address gets `is_superuser`. `PLAY_REVIEW_EMAIL` is no longer read by anything.

## STATUS: STILL BROKEN over HTTP. Root cause unknown.

The core mystery, unchanged and now proven twice:

- **In-process it works.** Driving the real allauth views with Django's test client inside a Render one-off job logs in successfully. Since `generate_login_code` is gone, the stashed code is random, so only the golden ticket could have done it.
- **Over real HTTPS it fails.** Same account, same code, `members.pastlives.space`: a genuine `id_code_error` "Incorrect code", no session.

Ruled out by direct measurement, do not re-check these:
- Env vars set; active User + linked Member exist.
- The pending login in the HTTPS-created session **does** have a user (`session["account_login"]["user"]`).
- Right service (only one web service) and right code (live site reports the same `VERSION` as `main`).
- `allauth.account.middleware.AccountMiddleware` is in `MIDDLEWARE`, so `allauth.core.context.request` is populated.
- `request._login_stage` is the correct attribute (`allauth/account/internal/decorators.py:34`).
- Before the golden ticket, the old mechanism was *also* confirmed working in-process and failing over HTTP, so this defeats two independent mechanisms.

## Traps that cost hours here

1. **A one-off job using Django's test client bypasses the HTTP layer and passes while the browser flow fails.** Never accept it as proof. Drive `https://members.pastlives.space/accounts/login/code/` with curl and a real cookie jar.
2. **Assert on `id_code_error`, never on page text.** The changelog modal puts "Incorrect code", "rate limit", "expired", "Dashboard" and "Log Out" on every page, so naive greps give false positives both ways.
3. **Faked test fixtures prove nothing about allauth internals.** Unit tests that hand-build `SimpleNamespace(_login_stage=...)` pass regardless of whether the real structure matches.
4. See [[project_plfog_context_blocks_dont_run]] for the `context_` specs-that-never-run trap.

## Render one-off jobs give NO usable signal. Do not diagnose with them.

Proven with controls on 2026-08-05, all of which reported **succeeded**:

| Command | Expected | Actual |
|---|---|---|
| `manage.py shell -c` ... `sys.exit(1)` | failed | **succeeded** |
| `manage.py shell -c` ... `assert False` | failed | **succeeded** |
| plain `python -c` ... `sys.exit(1)` | failed | **succeeded** |

Job status is not derived from the process exit code. Stdout does **not** reach `render logs` (only ~4 startup lines survive) and **no request-time logs at all** reach the stream. So a one-off job can tell you *nothing* — and it fails silently in the direction of "everything is fine", which is the worst possible failure mode.

**This invalidated an entire day of debugging.** Two separate rounds of conclusions (env vars set, account exists, session contents, deployed source, allauth version, in-process login working) were all built on this non-signal and were all worthless. If you cannot name a control that proved your channel live, you do not have a channel.

**Channels that do work:** direct HTTP observation with curl (status codes, response bodies) against prod, and a local prod-shaped replica. For getting values *out of* the prod web process, the untried options are Sentry (`SENTRY_DSN` is configured) or a temporary secret-gated diagnostic view; both need a deploy. `PROD_DATABASE_URL` in the repo `.env` is **empty**, so there is no direct local DB access; read the prod DB by loading sessions inside a one-off job. `SENTRY_DSN` is configured and is probably the best untried channel for getting values out of the web process.

**Next step not yet tried:** reproduce locally under gunicorn (not the test client) against a real DB, which would tell you whether the break is the HTTP path generally or something Render-specific. See [[reference_plfog_pr_ops]].
