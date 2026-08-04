---
name: project_appstore_reviewer_login
description: How app-store reviewers log into plfog past the passwordless email-code gate (Play + Apple).
metadata: 
  node_type: memory
  type: project
  originSessionId: 3f8a5580-39c1-4cf4-ae23-44529e574596
  modified: 2026-07-28T18:44:30.495Z
---

plfog's login is passwordless email codes, which store reviewers can't receive. `generate_login_code` in `plfog/adapters.py` has a fixed-code override: when BOTH `PLAY_REVIEW_EMAIL` and `PLAY_REVIEW_CODE` env vars are set on Render prod, the one matching email gets that fixed code instead of a random emailed one, so a reviewer signs in without an inbox (the code carries the login; email delivery is irrelevant).

- **Review account:** `appreview@pastlives.app` — a plain ACTIVE Member, member-level (NOT admin). Created via a Render one-off job (`Member.objects.create` / `AddMemberForm.create_member` path). The fixed code value lives ONLY in Render env (secret) — not recorded here.
- **Hard constraint:** the review email must NOT be on an admin domain. Prod `ADMIN_DOMAINS = pastlives.space, roaming-panda.com` — an address on either auto-grants `is_superuser` via `_sync_permissions`. `pastlives.app` and gmail are safe.
- Login-code TTL is 5 min (`ACCOUNT_LOGIN_BY_CODE_TIMEOUT = 300`); request-rate limit `3/h` per email. Reviewer enters promptly, so fine.

**Why:** app-store submissions need working demo credentials, but the app has no password. **How to apply:** to change the review email, update `PLAY_REVIEW_EMAIL`, create/repoint the Member, and **redeploy** (a single-var env PUT via the Render API does NOT auto-deploy — the running process only picks up env on restart). Verify by a one-off job that calls `generate_login_code` with the email in a `RequestFactory` POST and asserts it equals `PLAY_REVIEW_CODE`. Render ops live in [[reference_hetzner_vps]]-style API access via `RENDER_API_KEY` in the repo `.env` (service `srv-d6j2331drdic73ak0s30`).
