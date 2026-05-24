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

---

## Hetzner VPS — Plaza Codes Hosting Platform

### SSH Setup

Before you can connect, ensure the SSH config entry exists. Add this to
`~/.ssh/config` if it's not already there:

```
Host hetzner
    HostName 5.78.148.196
    User root
    IdentityFile ~/.ssh/hetzner_rsa
```

The private key `~/.ssh/hetzner_rsa` must be copied to this machine from an
authorized device. Without it, SSH will fail. Permissions must be `chmod 600
~/.ssh/hetzner_rsa`.

### Server Details

- **Provider:** Hetzner
- **IP:** 5.78.148.196
- **SSH:** `ssh hetzner`
- **OS:** Ubuntu 24.04.3 LTS
- **Spec:** CX22 — 2 vCPU, 4GB RAM, 75GB SSD
- **Stack:** Nginx 1.28, PHP 8.3-FPM, MariaDB 11.x, PostgreSQL, Let's Encrypt
- **Firewall:** UFW (ports 22, 80, 443) + Fail2ban
- **Backups:** Daily automated
- **Domain:** plaza.codes (staging subdomains: *.plaza.codes)
- **Site types:** WordPress, PHP/Laravel, Node.js, Python, static

### What This Server Does

This is a panelless, CLI-driven multi-tenant WordPress hosting platform for
Plaza Codes (freelance web dev agency). No cPanel, no Plesk — everything is
managed via scripts and direct config.

Each hosted client site gets:
- Isolated Linux user + dedicated PHP-FPM pool
- Own MariaDB database
- Own Nginx server block + Let's Encrypt SSL cert
- `plaza-billing` plugin (Stripe subscriptions, $9–15/mo per client)

### Currently Hosted Sites

- **myartstarz.plaza.codes** — WordPress staging site for MyArtStarz
  (children's art school, San Antonio TX)

### Key Paths on the Server

Site management scripts live in the server's provisioning repo
(`plaza-codes-vps`). Key operations:
- `site-add.sh` — provisions a new client site (user, DB, Nginx, SSL)
- `site-remove.sh` — tears down a client site
- WordPress sites live under each site user's home directory
