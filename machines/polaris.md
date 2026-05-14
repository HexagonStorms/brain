# Polaris

The user's home gaming PC and the other end of most cross-site transfers. Lives at home, not at the workshop. Different physical network from Elowynn; the two meet over Tailscale.

This machine has no assistant-name assigned yet — when running Claude on Polaris, fall back to the shared identity in `CLAUDE.shared.md` unless the user gives the holding a name.

---

## Hardware

- **CPU:** AMD Ryzen 7 7800X3D
- **GPU:** NVIDIA RTX 5080
- **RAM:** 64 GB Corsair Vengeance DDR5-6000
- **PSU:** 1200 W
- **OS drive:** 2 TB Timetec SSD
- **Data drive:** 5 TB WD Black HDD
- **OS:** Windows 11 Pro
- **Internet:** Astound Broadband, 1 Gbps symmetric (upload is not a bottleneck — online transfers to Elowynn are viable at sustained 100+ MB/s when Tailscale negotiates a direct connection)

---

## Role

Polaris is a workstation, not a server. I don't propose running services on it; it's the source of personal data flowing *into* the lab (game captures, photos, archives, anything Polaris-side that wants a long-term home on Elowynn's 16 TB).

Polaris is also a **mixed-use** machine: the user runs both personal and work Claude sessions here. The shared brain therefore stays slim and content-neutral on this host — lab-specific or personal-only context belongs in `machines/elowynn.md`, not in `CLAUDE.shared.md`.

## Claude Code on Polaris

Claude Code runs in **WSL only** on this machine — never Windows native. `~/.claude/` lives inside WSL, and `setup.sh` runs there unchanged. No `.ps1` equivalents needed.

WSL distro: Ubuntu 24.04 LTS (Noble). The WSL root is its own ~1 TB virtual disk; Windows-side drives are visible at `/mnt/c` (the 2 TB OS SSD) and `/mnt/d` (the 5 TB WD Black data drive).

SSH auth to GitHub as `HexagonStorms` is already configured.

---

## Networking

Polaris appears on Tailscale as **two** nodes that share the hostname root:

- `polaris-1` — Linux, `100.89.161.6` — the WSL side. This is the node Claude Code talks from.
- `polaris` — Windows, `100.116.170.117` — the Windows host itself.

When the user says "polaris" in a transfer context, default to the WSL node (`polaris-1`) unless something specifically needs the Windows side.

Nearest DERP relay is Seattle (~5–6 ms), and the link to Elowynn typically negotiates a direct UDP path rather than relaying.
