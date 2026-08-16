---
name: redgifs-fetch
description: Use when Jo wants to grab every video from a RedGifs user and compile them into one compilation. Triggers on a redgifs.com/users/<name> URL with "grab"/"fetch"/"rip"/"pull"/"download every video", or asking to pull a RedGifs creator into Stash. Downloads the whole catalog with yt-dlp, folds the clips into Stash as scenes (performer + studio RedGifs), and stitches them into a single compilation.
---

# Grab a RedGifs user and compile into one

Downloads every video from a RedGifs user, folds them into Stash as scenes with
the username as **performer**, studio **RedGifs**, tag `redgifs`, then compiles
them into **one** compilation (RedGifs clips are all short, so the compile tool
produces a single Shorts comp). RedGifs is public; yt-dlp fetches its own token,
so no auth/cookies. Runs on elowynn.

Orchestrator: `~/Code/elowynn-media-server/redgifs/redgifs-fetch.mjs`.

## Run it

Full catalogs can be hundreds of clips; run in the background.

```
cd ~/Code/elowynn-media-server/redgifs
node redgifs-fetch.mjs "https://www.redgifs.com/users/<user>" > /tmp/redgifs-<user>.log 2>&1 &
tail -f /tmp/redgifs-<user>.log
```

Options:
- `--limit N` only the first N clips (test slices).
- `--no-compile` grab + tag only, skip the compile (compile later with
  `node stash-compile.mjs <user>` in `../compilations`).

## What it does, in order

1. yt-dlp downloads the user's whole catalog (it expands the user playlist
   itself) to `/media/data/stash/Unsorted/redgifs/<user>/`, with a
   download-archive so reruns are incremental.
2. Scans into Stash.
3. Bulk-attaches performer `<user>`, studio **RedGifs**, tag `redgifs` to every
   one of the user's scenes.
4. Compiles them with `stash-compile.mjs <user>` (all short => one Shorts comp),
   then sets a frame cover on the result.
5. ntfy on success/failure with the clip count.

## Notes

- Compiling archives the source clips and replaces them with the one comp scene
  (standard stash-compile behavior). Rerun grabbing later folds new clips in;
  use `stash-compile.mjs <user> --migrate` to add them to an existing comp.
- Heavy: the compile is one ffmpeg job. If another compile is running
  (e.g. compile-all), they contend but both finish. Serialize by hand if it
  matters.
- No prune step: RedGifs yields video scenes, not a photo gallery.
