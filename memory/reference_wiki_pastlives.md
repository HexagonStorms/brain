---
name: reference-wiki-pastlives
description: "MediaWiki for Past Lives Makerspace at wiki.pastlives.space on the Hetzner VPS"
metadata:
  type: reference
---

Past Lives Makerspace wiki — a MediaWiki install on the [[reference-hetzner-vps]] (`ssh hetzner`).

- **URL**: https://wiki.pastlives.space
- **Docroot**: `/var/www/wiki.pastlives.space/public/` — `LocalSettings.php` lives there.
- **Stack**: Nginx + PHP-FPM 8.3 + MariaDB 11.4 (its own db/user via the host's `site-add.sh` convention). No Docker; runs directly on the host.
- A `mediawiki-1.43.1.tar.gz` was present in `/tmp` as of 2026-05-29 — likely a pending or in-progress core upgrade.

**Troubleshooting paths**: nginx logs `/var/log/nginx/` (per-site access/error), PHP-FPM 8.3 pool log, and MediaWiki's own debug log (set `$wgDebugLogFile` in `LocalSettings.php`). Maintenance scripts under `<docroot>/maintenance/` (e.g. `php maintenance/run.php update` for schema after upgrades on MW 1.40+).

**Client SSH access**: client is "plfog". Login user `wiki_pastlives_space` (uid 1004), home = `/var/www/wiki.pastlives.space` (NOT `/home/...`), so its keys live at `/var/www/wiki.pastlives.space/.ssh/authorized_keys`. sshd: pubkey-only (`PasswordAuthentication no` in `/etc/ssh/sshd_config.d/hardening.conf`); a `Match User wiki_pastlives_space` block only disables forwarding/X11/tunnel — it does NOT block pubkey. Client key on file: ed25519 `SHA256:rkE82/UxkTgOT9yV5UoTVTZ4cSnP+cUz/31Wi7cDcCk` (github@paranoidbob.com), installed 2026-05-29.

**DNS note**: `wiki.pastlives.space` resolves to **5.78.148.196** on public resolvers (correct). From elowynn's LAN it resolves to `10.0.0.10` (local split-horizon / pihole override) — a home-network quirk, not a server problem; use `curl --resolve wiki.pastlives.space:443:5.78.148.196` to test the real server from here.
