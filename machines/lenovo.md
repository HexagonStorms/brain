# Lenovo

The user's laptop. Hostname is `public`, but in the brain this machine is "Lenovo." Mixed-use: both Automatiq work and personal code live here (`~/Code/automatiq`, `~/Code/plfog`, `~/Code/brain`), so the shared brain stays slim and content-neutral on this host — lab-specific or personal-only context belongs in `machines/elowynn.md`, not in `CLAUDE.shared.md`.

This machine has no assistant-name assigned yet — when running Claude on Lenovo, fall back to the shared identity in `CLAUDE.shared.md` unless the user gives the holding a name.

---

## Hardware

- **CPU:** 11th Gen Intel Core i7-11850H @ 2.50 GHz (8 cores / 16 threads)
- **GPU:** NVIDIA RTX 3070 Laptop GPU (8 GB), driver 596.36
- **RAM:** 16 GB
- **Swap:** 4 GB
- **OS:** Windows 11 host, WSL2 distro Ubuntu 26.04 LTS (Resolute Raccoon)

Form factor is a laptop (3070 *Laptop* GPU, H-series CPU).

---

## Storage

- **Windows C:** 476 GB SSD, ~240 GB used (51%). Visible inside WSL at `/mnt/c`.
- **WSL root:** 1 TB virtual disk (`/dev/sdd`) mounted at `/`, ~7.5 GB used. Plenty of headroom for Linux-side work.
- No additional drives.

## Network

- `eth0`: `192.168.32.240/20` (WSL NAT)
- **Tailscale is installed on the Windows side**, node name **`legato`** (`100.113.220.68`). The old `lenovo`/`lenovo-ssh` tailnet nodes are stale enrollments from before the rename. No WSL-side tailscaled; outbound tailnet traffic from WSL rides the Windows client, which is enough for ssh out.
- **SSH out (set up 2026-07-24):** dedicated keypair `~/.ssh/legato` (comment `josh@legato`), authorized on elowynn (`jo@100.90.245.125`, `~/.ssh/authorized_keys`) and polaris (`plaza@100.116.170.117`, `C:\ProgramData\ssh\administrators_authorized_keys`).

---

## Claude Code on Lenovo

Claude Code runs in **WSL only** on this machine — never Windows native. `~/.claude/` lives inside WSL, and `setup.sh` runs there unchanged.

The brain is wired up: `~/.claude/settings.json` is a symlink to `~/Code/brain/settings.json`, and the memory directory is a symlink to `~/Code/brain/memory`. `CLAUDE.md` is the composed file. Note that the hostname (`public`) doesn't match the brain name (`lenovo`) — `setup.sh` has a `*public*` case that maps to `machines/lenovo.md`.

## Dev tooling present

`git`, `zsh`, `bash`, `docker`, `node` (v25), `npm`, `python3` (3.14), `gh`, `claude` (2.1.133), `curl`, `jq`, `make`.

Notably **not** installed: `pnpm`, `bun`, `tailscale`, `rg` (ripgrep), `fzf`, `ssh` (the discover probe failed — worth confirming).

git is configured as `Josh Plaza <plazajosue2@gmail.com>` with an Automatiq-scoped include for `~/Code/automatiq/`.
