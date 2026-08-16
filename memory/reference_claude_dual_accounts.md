---
name: claude-dual-accounts
description: Jo alternates between two Claude Code logins (personal vs work); the work org restricts features like Remote Control (/rc).
metadata:
  type: reference
---

Jo runs Claude Code under two different Anthropic accounts and switches between them daily, independent of which machine he's on:

- **Personal** — `plazajosue2@gmail.com`. Max 20x rate tier. No org restrictions seen. `/rc` (Remote Control) works.
- **Work** — `josh.plaza@autoamtiq.com`. Max 5x rate tier. Account shows `cachedExtraUsageDisabledReason: org_level_disabled` in `~/.claude.json`. Remote Control (`/rc`) is disabled by org policy on this account.

**Why:** Confirmed 2026-07-24 while debugging `/rc` missing on Polaris. It looked like a client bug or version skew (Polaris was 61 patch versions behind, which was real and worth fixing, but wasn't the actual cause). The `userID` hash in `~/.claude.json` differed between the two logins, confirming separate accounts rather than one shared subscription.

**How to apply:** Before treating a "feature X is missing/disabled" report as a client bug, check which account is currently logged in — compare `userID` in `~/.claude.json` and `subscriptionType`/`rateLimitTier` in `~/.claude/.credentials.json` (or the Windows equivalent under `%USERPROFILE%`). Org-gated features track the active login, not the machine or Claude Code version.
