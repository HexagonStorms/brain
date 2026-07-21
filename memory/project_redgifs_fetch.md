---
name: project_redgifs_fetch
description: RedGifs user grabber that folds every clip into Stash and compiles them into one compilation.
metadata:
  type: project
---

The `/redgifs-fetch` skill ([[skill-redgifs-fetch]]) grabs every video from a RedGifs user into Stash and stitches them into ONE compilation. Tooling: `~/Code/elowynn-media-server/redgifs/redgifs-fetch.mjs`.

**How it works:** yt-dlp expands the `redgifs.com/users/<user>` playlist itself (no auth; it fetches its own token), downloads the whole catalog to `/media/data/stash/Unsorted/redgifs/<user>/`, scans into Stash, bulk-sets performer=<user> + studio=RedGifs + tag redgifs on every scene, then runs `stash-compile.mjs <user>`. RedGifs clips are all short, so the compile yields a single Shorts comp; then set-cover on it.

**How to apply:** `cd .../redgifs && node redgifs-fetch.mjs "https://www.redgifs.com/users/<user>"` (background). `--limit N` for test slices, `--no-compile` to defer stitching. Download-archive makes reruns incremental; rerun + `stash-compile <user> --migrate` folds new clips into the existing comp. No prune (video scenes, not a photo gallery). Verified 2026-07-21 (pinkdroid462, ~638 clips).

Related batch tooling this session: `compilations/compile-all.sh` (waits for OF grabs, then prunes+compiles each creator serially, ntfy per creator), `instagram/queue-retry.sh` (waits out an IG anonymous throttle then runs [[project_ig_fetch]]).
