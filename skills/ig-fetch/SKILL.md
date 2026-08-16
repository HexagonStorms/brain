---
name: ig-fetch
description: Use when Jo wants to pull an Instagram account's photos into Stash keeping only shots of the person and dropping scenery. Triggers on an instagram.com profile URL with "grab"/"fetch"/"rip"/"pull"/"download", or asking for someone's IG photos filtered to just pictures of them (not landscapes, flowers, food, objects). Downloads with gallery-dl, keeps photos containing a prominent person via a YOLOX detector, folds survivors into one Stash gallery.
---

# Grab an Instagram account's person-photos into Stash

Downloads a public IG account's photos, keeps only images with a **prominent
person** (drops scenery, flowers, food, objects, pages), and folds the survivors
into one growable Stash gallery `<user> (photos)` with the user as performer,
studio **Instagram**, and an `instagram` tag. Runs on elowynn; no GPU needed.

Orchestrator: `~/Code/elowynn-media-server/instagram/ig-fetch.mjs`.

## Run it

```
cd ~/Code/elowynn-media-server/instagram
node ig-fetch.mjs "https://www.instagram.com/<user>/" > /tmp/ig-<user>.log 2>&1 &
tail -f /tmp/ig-<user>.log
```

Options:
- `--min-person N` person box must be >= this fraction of frame height (default
  0.35; lower to keep more distant shots, raise for tighter close-ups).
- `--conf N` detector confidence (default 0.5).
- `--limit N` only the first N posts (test slices).
- `--no-prune` skip the oversized-photo prune.

## What it does, in order

1. gallery-dl downloads the account's photos (videos skipped) to a staging dir,
   with a download-archive so reruns are incremental.
2. `personfilter.py` (venv, OpenCV + YOLOX on CPU) keeps images with a person
   whose box height >= `--min-person` of the frame; the rest are discarded.
3. Scans survivors into Stash; the folder becomes gallery `<user> (photos)`.
4. Attaches performer `<user>`, studio **Instagram**, tag `instagram`.
5. Prunes oversized photos if the gallery has >= 250, runs Stash Clean, wipes
   staging.
6. ntfy on success/failure with the kept/dropped counts and gallery link.

## Auth reality

- **Public accounts** work **anonymously** but IG rate-caps hard, so a big
  account may only partially download per run (rerun to continue; the archive
  skips what's done).
- **Private accounts or full/complete grabs** need a logged-in session: export a
  Netscape `cookies.txt` from a browser signed into a **burner** IG account
  (scraping breaches IG's ToS) and set `IG_COOKIES` (or drop it at
  `instagram/cookies.txt`). The orchestrator uses it automatically when present.

## Known limits

- It detects **people, not faces** (chosen because lifestyle IG has full-body
  poses, sunglasses, and angled shots a face detector misses). Consequence:
  **human statues** (e.g. cemetery angels) can read as people and slip through.
  Rare outside statue-heavy accounts; cull by eye if needed.
- A person tiny in a wide landscape is dropped by the size guard (that's the
  point); lower `--min-person` if you want those.
- gallery-dl + IG is fragile (throttling, session challenges) in a way the
  OnlyFans path is not. A partial run is normal; rerun to continue.
