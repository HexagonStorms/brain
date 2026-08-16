---
name: project_stash_storage_dashboard
description: stash-storage dashboard ranks Stash creators by disk use and surfaces reduction candidates.
metadata: 
  node_type: memory
  type: project
  originSessionId: b020d9d7-230a-4370-8573-628bdc1d03b0
  modified: 2026-07-22T18:15:55.450Z
---

`stash-storage` (built 2026-07-22): a standing dashboard that ranks Stash
creators (performers) by storage and surfaces reduction levers. Read-only, it
never deletes; it points at what to trim.

- **Where:** `~/Code/elowynn-media-server/stash-storage/` (source + service in one
  folder, tracked in the elowynn-media-server repo). Compose service `stash-storage`,
  port `127.0.0.1:8801`, public at `https://storage.plaza.codes` behind HTTP basic
  auth (`STORAGE_USER`/`STORAGE_PASS` in `.env`). Zero-dependency Node.
- **How it works:** talks to `stash:9999` GraphQL, reads no media files (sizes come
  from GraphQL), so no `/media` mount. Aggregation pass runs on startup + hourly +
  on the Refresh button; snapshot is in-memory (recomputed, not persisted). ~9s pass.
- **Levers:** per creator: biggest files (deep-linked to Stash), oversized photos
  (>4K edge, ties to [[stash-creator-fetch skill]] prune-oversized.py), phash
  duplicate waste (`findDuplicateScenes`), cold bulk (0 O-counter + 0 plays).
- **Attribution caveat:** a scene's bytes count toward EVERY performer on it, so
  per-creator totals sum above the library total (compilations/collabs). The UI
  labels this; it's the "who costs me space" view, not a partition.
- **First run insight:** ~1.98 TB video, of which ~950 GB is cold (never watched),
  ~29 GB duplicate waste, ~14 GB oversized photos.

**How to apply:** to add reduction levers, edit `aggregate.mjs` (snapshot shape) +
`dashboard.html` (render). v1 is intentionally read-only; guarded delete/prune
buttons wired to existing scripts are the obvious next step if Jo wants action from
the UI. Rebuild: `docker compose build stash-storage && docker compose up -d stash-storage`.
