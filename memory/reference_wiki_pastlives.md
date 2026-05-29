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
