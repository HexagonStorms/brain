---
name: reference_legato_ssh_keys
description: SSH key layout on legato (the WSL2 laptop) — which key maps to which identity/host
metadata:
  node_type: memory
  type: reference
---

SSH keys in `~/.ssh/` on **legato** and their purpose:

- **`legato`** — personal GitHub (HexagonStorms) AND Bluehost (`cascader@50.87.184.214` for Cascade Rescue). Default identity for plain `git@github.com:...` clones. Aliased as `github-hexagonstorms`. See [[reference_hexagonstorms_github]].
- **`id_ed25519`** — work GitHub (joshplaza / Automatiq). Used via `git@github-automatiq:...`.
- **`siloh`** — both home hosts over Tailscale: `elowynn` (`jo@100.90.245.125`) and `polaris` (`plaza@100.116.170.117`). See [[reference_polaris_ssh]].

**Why:** Migrated from a Lenovo machine on 2026-06-06 — the personal key was originally named `lenovo` and was renamed to `legato` (matches this machine's hostname/username) at the user's request.

**How to apply:** When suggesting clone commands or ssh hosts, use the right alias for the account. Don't refer to the personal key as `lenovo` anymore — it's `legato`.

**Gotcha (corrected 2026-08-04):** the `legato` key is *not* authorized on polaris — only `siloh` is. An earlier note in `machines/legato.md` claimed otherwise; `ssh -i ~/.ssh/legato plaza@100.116.170.117` gets `Permission denied (publickey)`.

Both `elowynn` and `polaris` have `Host` entries in `~/.ssh/config` as of 2026-08-04, so plain `ssh elowynn` / `ssh polaris` work.
