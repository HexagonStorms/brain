---
name: fix-movie-poster
description: >-
  Fix a movie's poster in Jellyfin on the elowynn media server when it is showing
  the wrong image. Use this whenever Jo says a movie's poster is wrong, missing,
  broken, ugly, "not a poster", a screenshot, or a random frame from the film,
  even if he does not say the word "poster" (e.g. "the Joker thumbnail is a
  screencap", "why does Avatar show a movie still"). The usual root cause is
  Jellyfin storing an embedded/extracted frame grab as the Primary image instead
  of the real poster art; the fix is to pull the correct TMDB poster (via Radarr)
  and upload it as the Jellyfin Primary image. Handles one or several titles at
  once.
---

# Fix a movie poster on elowynn

Jellyfin usually shows the right poster, but some releases carry an embedded cover
**frame** (a still from the film) inside the container. Jellyfin extracts that and
stores it as the movie's Primary image, where it outranks the poster it downloaded.
The tell: the "poster" is **landscape** (e.g. 1920x1080), a movie still, while a
real poster is **portrait** (2:3, e.g. 2000x3000). This skill diagnoses that,
pulls the correct poster, replaces it, and verifies.

The correct art already exists — Radarr tracks the right TMDB poster URL for every
movie in the library. This skill just copies it into Jellyfin's Primary slot.

## Just run the script

The whole flow is bundled in `scripts/fix-poster.zsh`. Pass one or more movie
names exactly as Jo describes them:

```
zsh ~/.claude/skills/fix-movie-poster/scripts/fix-poster.zsh "Joker" "Basquiat" "Avatar"
```

It prints a `was ... -> now ...` line per title with the before/after dimensions,
so the fix is self-verifying. Relay that back to Jo. If a title is already portrait
it says so and skips it (nothing to fix); add `--force` before the names to replace
anyway (use this when the poster loads fine but Jo just wants different art).

After it runs, tell Jo to refresh his client — the image tag changes with the new
upload, so most clients re-pull on their own, but a stuck app may need one refresh
(web: hard reload; mobile/TV app: clear cache).

## What it does, so you can debug it

Facts the script depends on, in case something breaks:

- Keys come from the stack: `JELLYFIN_API_KEY` in
  `~/Code/elowynn-media-server/.env`, Radarr's `<ApiKey>` in
  `~/Code/elowynn-media-server/radarr/config.xml`. Jellyfin is `localhost:8096`,
  Radarr `localhost:7878`.
- **Find the movie via the search endpoint**, not the single-item one. On this
  Jellyfin `GET /Items/{id}` returns "Error processing request"; use
  `GET /Items?searchTerm=NAME&IncludeItemTypes=Movie&Recursive=true` instead. If
  the search returns more than one movie the script refuses to guess and lists the
  matches — give it a more specific name (or add the year).
- **Diagnose by shape**: download the current Primary and read its dimensions with
  `file`. Note `file` prints an embedded-thumbnail size (often `1x1`) first, so the
  real WxH is the *last* `NxN` on the line. Width > height means a frame grab.
- **Get the poster** from Radarr's `/api/v3/movie` (match on `tmdbId`, take the
  `coverType == "poster"` `remoteUrl`), falling back to Radarr's TMDB lookup if the
  movie is not in the library.
- **Upload** with `POST /Items/{id}/Images/Primary`, body = **base64** of the jpeg,
  header `Content-Type: image/jpeg`. Success is **HTTP 204**.
- **Verify** by re-fetching the Primary image and confirming it is now portrait.

## If it reverts later

A normal metadata refresh leaves a user-set image alone. But a Jellyfin refresh
run with **"Replace existing images"** checked can re-grab the embedded frame and
undo this. If that keeps happening for a title, the durable fix is a local
`poster.jpg` in the movie's folder under `/media/data/media/movies/<Title>/` — a
local `poster.jpg` outranks the extracted frame permanently. Offer that only if the
revert actually recurs; the script is the normal path.
