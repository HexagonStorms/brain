---
name: project_ig_fetch
description: Instagram photo grabber that keeps only photos of the person (not scenery), folding them into a Stash gallery.
metadata:
  type: project
---

The `/ig-fetch` skill ([[skill-ig-fetch]]) pulls a public Instagram account's photos into Stash keeping only shots with a **prominent person**, dropping scenery/flowers/food/objects. Tooling at `~/Code/elowynn-media-server/instagram/` (orchestrator `ig-fetch.mjs`, filter `personfilter.py`).

**Why person-detection, not face:** Jo first asked for "photos of the person's face." Testing on a real lifestyle account showed a lightweight face detector (YuNet) kept only clear frontal faces and missed most real photos of her (full-body poses, sunglasses selfies, angles) — 3/40. Switched to **YOLOX person detection** via OpenCV dnn (CPU, no torch), keeping images where a person's box height >= `--min-person` (default 0.35) of the frame. Jo chose this tradeoff.

**How to apply:**
- Run backgrounded: `cd .../instagram && node ig-fetch.mjs "https://www.instagram.com/<user>/"`. Options `--min-person 0.35 --conf 0.5 --limit N --no-prune`.
- Download is gallery-dl. **Public accounts work anonymously** but IG rate-caps, so big accounts download partially per run; rerun to continue (download-archive makes it incremental). Private/full grabs need a burner `cookies.txt` (Netscape) at `IG_COOKIES` or `instagram/cookies.txt`.
- Survivors fold into gallery `<user> (photos)` (performer <user>, studio Instagram, tag instagram). Reuses the >=250 prune + Stash Clean.
- **Known wart:** human statues (e.g. cemetery angels) read as people and slip through; rare, cull by eye.
- Stash gotcha (fixed): folder-scanned galleries have an EMPTY title; find them by `folder path`, not title, then set the title.
- Fresh checkout: `instagram/setup.sh` rebuilds the gitignored venv + yolox.onnx.

Verified end-to-end 2026-07-21 on slowthiisbird: 271 downloaded -> 125 kept / 146 dropped -> gallery 475.
