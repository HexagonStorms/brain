---
name: project-seerr-content-filtering
description: "Seerr discovery filtering on elowynn — keyword blocklist for porn docs, daily cron hides theatrical-only movies until streamable"
metadata: 
  node_type: memory
  type: project
  originSessionId: 0da70bb5-becd-4c74-8894-29ea4ec006da
---

Jo's Seerr (ghcr.io/seerr-team/seerr, port 127.0.0.1:5055) has layered content filtering, set up 2026-06-05:

1. `blocklistedTags` in jellyseerr/settings.json: TMDB keywords (softcore, erotica, pornography, sexploitation, sex industry) auto-blocklist ~4,500 titles; native job re-sweeps every 7 days. `hideBlocklisted: true` makes the UI strip blocklisted items from every page. Note: the /api/v1/blocklist listing hides tag entries; count them in the sqlite DB, not via API.
2. Home discover sliders: Trending/Popular Movies/Upcoming Movies disabled; custom "Popular on Streaming" slider (type 20, US providers) instead.
3. `~/Code/elowynn-media-server/seerr-hide-theatrical.sh` via crontab daily 4:25am: blocklists popular/trending movies with zero US watch providers, un-blocklists when providers appear (or 365-day failsafe). State in seerr-theatrical-state.json (gitignored, machine-local like the crontab itself).
4. Radarr minimumAvailability=released blocks CAM/bootleg grabs regardless.

**Why:** Jo hates porn-doc clutter and bootleg-bait (in-theaters titles) in discovery; wants movies visible only once legitimately rentable/streamable.

**How to apply:** Don't re-enable the disabled sliders or touch entries in seerr-theatrical-state.json by hand; the script owns them. Hidden titles also don't appear in Seerr search, by design.
