---
name: reference_hexagonstorms_github
description: How to commit/push to GitHub as the HexagonStorms account
metadata:
  node_type: memory
  type: reference
---

`gh` has two authed accounts: `joshplaza` (usually active) and `HexagonStorms`.

To create/push a repo as **HexagonStorms**:
- git identity: `user.name = HexagonStorms`, `user.email = 7490582+HexagonStorms@users.noreply.github.com`
- `gh auth switch --user HexagonStorms` before `gh repo create` / push, then switch back to `joshplaza` afterward.
- Push over HTTPS using the gh token to avoid SSH-key ambiguity: set the remote to `https://github.com/HexagonStorms/<repo>.git` and push with `git -c credential.helper='!gh auth git-credential' push`.

First repo created this way: `HexagonStorms/legato-yarg-app` (private) — see [[project_legato_yarg_app]]. The same account switch is needed for plfog PRs — see [[reference_plfog_pr_ops]]. Key layout: [[reference_legato_ssh_keys]].
