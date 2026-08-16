---
name: plaza-codes-cloudflare-cache
description: plaza.codes is behind Cloudflare with 1y immutable static caching; replaced assets must get new filenames
metadata: 
  node_type: memory
  type: project
  originSessionId: 1d008565-787c-4713-989e-e1dbf43eaac7
  modified: 2026-07-24T02:36:58.177Z
---

plaza.codes is proxied through Cloudflare (workspace CLAUDE.md's DNS table claims it points directly at the Hetzner VPS; that is outdated). The nginx vhost serves images/fonts/js/css with `expires 1y` + `Cache-Control: public, immutable`, so Cloudflare caches them for up to a year.

**Why:** In July 2026 a replaced headshot (`me.jpg`) kept serving the old bytes from Cloudflare's edge even after rsync deploy; had to rename it `me-2.jpg` to bust the cache.

**How to apply:** When any static asset on plaza.codes changes content, give it a new filename and update references (Astro-hashed `_astro/*` files do this automatically; hand-placed files in `public/` do not). Alternative: purge via the Cloudflare dashboard. The `CLOUDFLARE_API_TOKEN` in the Polaris WSL env can read zones but lacks purge permission (auth error code 10000 on purge_cache). Zone ID for plaza.codes: 95fdedff31bc28decdfae9ff49d18d4b. See [[hetzner-vps]].
