# Legato

The user's mobile laptop. Hostname, username, and Tailscale node are all `legato`. **Historical names: this same machine was called "Lenovo" in the brain and had hostname `public`** — `machines/lenovo.md` was renamed to this file on 2026-08-04, and `setup.sh` maps `*legato*`, `*lenovo*`, and `*public*` all here. There is only one laptop; if you see "lenovo" anywhere it means this host.

Mixed-use: both Automatiq work and personal code live here (`~/Code/automatiq`, `~/Code/plfog`, `~/Code/brain`, `~/Code/legato-yarg-app`), so the shared brain stays slim and content-neutral on this host — lab-specific or personal-only context belongs in `machines/elowynn.md`, not in `CLAUDE.shared.md`.

This machine has no assistant-name assigned yet — fall back to the shared identity in `CLAUDE.shared.md` unless the user names it.

---

## Hardware

- **CPU:** 11th Gen Intel Core i7-11850H @ 2.50 GHz (8 cores / 16 threads)
- **GPU:** NVIDIA RTX 3070 Laptop GPU (8 GB)
- **RAM:** 16 GB / **Swap:** 4 GB
- **OS:** Windows 11 host, WSL2 distro Ubuntu 26.04 LTS (Resolute Raccoon)

Form factor is a laptop (3070 *Laptop* GPU, H-series CPU). It's the machine Jo works from when away from the desk — Polaris and elowynn are the stationary boxes.

---

## Storage

- **Windows C:** 1.9 TB, ~206 GB used (11%). Visible inside WSL at `/mnt/c`.
- **WSL root:** 1 TB virtual disk (`/dev/sdf`) mounted at `/`, ~4.6 GB used.

## Network

- `eth0`: `172.29.36.148/20` (WSL NAT — this is DHCP-assigned and changes across reboots; don't hardcode it)
- **Tailscale is installed on the Windows side**, node name **`legato`** (`100.113.220.68`). The old `lenovo`/`lenovo-ssh` tailnet nodes are stale enrollments from before the rename. No WSL-side `tailscaled`; outbound tailnet traffic from WSL rides the Windows client, which is enough for ssh out.
- **SSH out (verified working 2026-08-04):** `ssh elowynn` and `ssh polaris` both work from WSL. Both use the **`siloh`** key. Full key layout in memory: `reference_legato_ssh_keys`.
  - The `legato` keypair is for personal GitHub (HexagonStorms) and Bluehost — it is **not** authorized on polaris, despite an earlier note here claiming it was.

## Git identity

Global default is personal: `Josh Plaza <plazajosue2@gmail.com>`. Work identity is scoped by an `[includeIf "gitdir:~/Code/automatiq/"]` in `~/.gitconfig` pointing at `~/.gitconfig-automatiq` (`josh.plaza@automatiq.com`).

Fixed 2026-08-04: the global email had been set to the *Automatiq* address with no `includeIf` wired, so personal repos were committing under the work identity. Verify with `git -C <repo> config user.email` after touching this.

Automatiq repos clone via the `github-automatiq` SSH alias (`~/.ssh/id_ed25519`); personal via plain `github.com` (`~/.ssh/legato`).

## Claude Code on legato

Claude Code runs in **WSL only** on this machine — never Windows native. `~/.claude/` lives inside WSL, and `setup.sh` runs there unchanged.

The brain is wired up as of 2026-08-04: `~/.claude/CLAUDE.md` is composed, `settings.json` / `commands` / `agents` are symlinks into `~/Code/brain/`, and `memory/` is linked into each personal cwd under `~/.claude/projects/`. `~/Code/automatiq` is in `WORK_PARENTS` and is deliberately **not** given a memory symlink.

## Shell

**zsh is the login shell** as of 2026-08-04 (installed and `chsh`'d that day — it was bash-only before, which is why older notes claiming zsh was present were wrong). `~/.zshrc` carries the linuxbrew shellenv, `~/.local/bin` on PATH, and a guarded `SSH_AUTH_SOCK` export for the 1Password agent.

## Dev tooling present

`git` (2.53), `zsh`, `bash`, `node` (v22.22.1), `npm`, `python3` (3.14.4), `gh`, `claude` (2.1.220), `curl`, `jq`, `fzf`, `rg`, `make`, `ssh`. `docker` resolves to Docker Desktop on the Windows side (`/mnt/c/Program Files/Docker/...`).

Notably **not** installed: `pnpm`, `bun`, WSL-side `tailscale` (the Windows client covers it).

## Automatiq commit signing — blocked

Automatiq requires signed commits via 1Password SSH. **1Password is not installed on the Windows host** as of 2026-08-04, which blocks the whole runbook. See memory `project_automatiq_1password_signing` for the step-by-step.
