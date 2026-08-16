---
name: frontpage-override-and-proxy-cache
description: "Homepage is served from wp_template DB override post 5168, and Bluehost's proxy cache needs an HTTP PURGE after content updates."
metadata: 
  node_type: memory
  type: project
  originSessionId: 71ebb7b3-a0a9-4d25-bb88-39fe4a0492cc
  modified: 2026-07-24T00:35:29.840Z
---

Two cascaderescue.org gotchas beyond the header/footer overrides documented in CLAUDE.md:

1. The front page template also has a DB override: `wp_template` post **5168** (a stale duplicate, post 5162, also exists but is not resolved). Like the header (5219) and footer (5169), the DB copy wins over `templates/front-page.html`, so homepage edits must go to both the theme file and post 5168.

2. Bluehost fronts the site with a proxy cache (`x-server-cache: true`, `x-proxy-cache: HIT`) that keeps serving stale HTML after `wp post update` / deploys. `wp cache flush` does not clear it. An external `curl -X PURGE https://cascaderescue.org/<path>` returns 204 and purges that URL.

**Why:** Without these, a deploy looks like it silently failed (as of July 2026 upgrade of the homepage: hero CTAs, featured beagles via `[adoptapet_pets count="3"]`, how-to-help cards).

**How to apply:** After changing homepage content, update post 5168, then PURGE the affected URLs and re-curl to confirm `x-proxy-cache: MISS`.
