---
name: reference_hexagonstorms_github
description: How to commit/push to GitHub as the HexagonStorms account
metadata:
  node_type: memory
  type: reference
---

`gh` has two authed accounts: `joshplaza` (work / Automatiq, usually active) and `HexagonStorms` (personal).

**Switching (legato, 2026-08-04):** `~/.zshrc` defines `ghwork`, `ghpersonal`, and `ghwho`. These affect the **`gh` CLI only** — git push/pull is routed by the `Host` aliases in `~/.ssh/config` (`github.com` → personal key, `github-automatiq` → work key), so switching gh accounts never changes which key a clone authenticates with. The two systems are independent; don't "fix" one by touching the other.

**Gotcha — stored joshplaza PATs go stale.** On legato, three separate `ghp_` tokens for joshplaza returned HTTP 401 "Bad credentials" before a freshly-minted one worked; the HexagonStorms token was valid the whole time. If a saved token 401s, don't re-copy it — mint a new classic PAT at github.com/settings/tokens (confirm the avatar says **joshplaza**, not HexagonStorms) with scopes `repo`, `read:org`, `workflow`, `gist`. Diagnose with a control before blaming the network:
```zsh
curl -s -o /dev/null -w "%{http_code}\n" -H "Authorization: token $TOKEN" https://api.github.com/user
```
The Automatiq org does **not** block the token — once valid, `gh api /orgs/automatiq-team`, repo reads, and `gh pr list` all work with no SAML authorization step.

To create/push a repo as **HexagonStorms**:
- git identity: `user.name = HexagonStorms`, `user.email = 7490582+HexagonStorms@users.noreply.github.com`
- `gh auth switch --user HexagonStorms` before `gh repo create` / push, then switch back to `joshplaza` afterward.
- Push over HTTPS using the gh token to avoid SSH-key ambiguity: set the remote to `https://github.com/HexagonStorms/<repo>.git` and push with `git -c credential.helper='!gh auth git-credential' push`.

First repo created this way: `HexagonStorms/legato-yarg-app` (private) — see [[project_legato_yarg_app]]. The same account switch is needed for plfog PRs — see [[reference_plfog_pr_ops]]. Key layout: [[reference_legato_ssh_keys]].
