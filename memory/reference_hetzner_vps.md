---
name: reference-hetzner-vps
description: "Hetzner VPS (plaza.codes hosting) — SSH access, stack, hosted sites, key paths"
metadata:
  type: reference
---

Plaza Codes production web host — where paying-client and Plaza/Past Lives sites live. NOT elowynn (that's the personal media server on residential internet).

- **SSH**: `ssh hetzner` (key `~/.ssh/hetzner_rsa`, config in `~/.ssh/config`). Note: this connection doubles its stdout — runs `ssh -o ControlMaster=no -o ControlPath=none` get cleaner output.
- **IP**: 5.78.148.196 — **Hostname**: plazacodes-hil-1
- **OS**: Ubuntu 24.04.3 LTS, kernel 6.8.0-106-generic
- **Spec**: Hetzner CX22 — 2 vCPU, 4GB RAM, 75GB SSD
- **Stack**: Nginx 1.28, PHP-FPM **8.3** (8.1/8.2 installed but inactive), MariaDB 11.4 (localhost:3306), Let's Encrypt (certbot)
- **Firewall**: UFW (22, 80, 443) + Fail2ban
- **Management**: panelless, CLI-driven; per-site scripts `site-add.sh` / `site-remove.sh` (each site gets its own Linux user, PHP-FPM pool, MariaDB db, Nginx block, SSL cert). Provisioning in `plaza-codes-vps` repo.
- **Monitoring**: push heartbeat to Uptime Kuma on elowynn (status.plaza.codes), alerting via ntfy.

**Nginx sites enabled** (verified 2026-05-29): guild-voting.plaza.codes, gus.plaza.codes, myartstarz.com, myartstarz.plaza.codes, pastlives.plaza.codes, plaza.codes, tempo.plaza.codes, wiki.pastlives.space (+ default). There is also a **gunicorn** Python app on 127.0.0.1:8001 (fronted by one of the nginx blocks).

See [[reference-wiki-pastlives]] for the MediaWiki install. Related: [[reference-plaza-codes]], [[reference-github]].
