---
name: fix-movie-poster
description: >-
  Fix a movie's or TV series's poster in Jellyfin on the elowynn media server
  when it is showing the wrong image, or not showing on some clients. Use this
  whenever Jo says a poster is wrong, missing, broken, ugly, "not a poster", a
  screenshot, a random frame from the film, or looks fine on one client (e.g. PC
  web) but is blank on another (e.g. a TV app) — even if he does not say the
  word "poster" (e.g. "the Joker thumbnail is a screencap", "why does Avatar
  show a movie still", "Archer isn't showing up on the TV but it's fine on my
  computer"). Two root causes: (1) Jellyfin stored an embedded/extracted frame
  grab as the Primary image instead of the real poster art (mostly movies), or
  (2) a TV series has season-level art but no series-level Primary image, so the
  web UI falls back to a season poster while TV apps show nothing (mostly TV).
  The fix is to pull the correct poster — TMDB via Radarr for movies, TVDB via
  Sonarr for series — and upload it as the Jellyfin Primary image. Handles one
  or several titles (movies and/or series, mixed) at once.
---

# Fix a movie or TV series poster on elowynn

Jellyfin usually shows the right poster, but two things go wrong in practice:

1. **Frame grab** (mostly movies): some releases carry an embedded cover
   **frame** (a still from the film) inside the container. Jellyfin extracts
   that and stores it as the Primary image, where it outranks the poster it
   downloaded. The tell: the "poster" is **landscape** (e.g. 1920x1080), a movie
   still, while a real poster is **portrait** (2:3, e.g. 2000x3000).
2. **Missing series poster** (TV only): a series has season-level art (Jellyfin
   scraped posters for each season fine) but no series-level Primary image at
   all — Jellyfin 404s on `/Items/{id}/Images/Primary` for the show itself. The
   tell Jo will report: it "looks fine on PC" (the web UI falls back to a season
   image when the series has none) but is **blank on a TV app** (which requests
   the series image directly and gets nothing).

This skill diagnoses which case it is, pulls the correct poster, replaces it,
and verifies.

The correct art already exists — Radarr tracks the right TMDB poster for every
movie it manages, Sonarr tracks the right TVDB poster for every series. This
skill just copies it into Jellyfin's Primary slot.

## Just run the script

The whole flow is bundled in `scripts/fix-poster.zsh`. Pass one or more titles
exactly as Jo describes them — movies and TV series can be mixed freely in one
call, the script figures out which is which:

```
zsh ~/.claude/skills/fix-movie-poster/scripts/fix-poster.zsh "Joker" "Hunter x Hunter" "Archer"
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
  `~/Code/elowynn-media-server/radarr/config.xml`, Sonarr's `<ApiKey>` in
  `~/Code/elowynn-media-server/sonarr/config.xml`. Jellyfin is `localhost:8096`,
  Radarr `localhost:7878`, Sonarr `localhost:8989`.
- **Find the item via the search endpoint**, not the single-item one. On this
  Jellyfin `GET /Items/{id}` returns "Error processing request"; use
  `GET /Items?searchTerm=NAME&IncludeItemTypes=Movie,Series&Recursive=true`
  instead (both types in one call — the result's `Type` field says which one
  matched). `searchTerm` must go through `curl -G --data-urlencode`, not raw
  string interpolation — a plain space in the URL makes curl reject it outright
  (`curl: (3) URL rejected: Malformed input to a URL function`), which used to
  read as a false "no match". If the search returns more than one item the
  script refuses to guess and lists the matches with their type — give it a more
  specific name (or add the year).
- **Diagnose by shape**: download the item's own Primary image (for a series,
  that's the series-level image, not any season's) and read its dimensions with
  `file`. Note `file` prints an embedded-thumbnail size (often `1x1`) first, so
  the real WxH is the *last* `NxN` on the line. Width > height means a frame
  grab; an empty result means Jellyfin 404'd (no Primary image at all — the
  missing-series-poster case). Either way the script treats it as needing a fix.
- **Get the poster**, source depends on `Type`:
  - Movie: Radarr's `/api/v3/movie` (match on `tmdbId`, take the
    `coverType == "poster"` `remoteUrl`), falling back to Radarr's TMDB lookup
    (`/api/v3/movie/lookup/tmdb?tmdbId=`) if the movie isn't in the library.
  - Series: Sonarr's `/api/v3/series` (match on `tvdbId`, same `coverType`
    filter), falling back to Sonarr's lookup (`/api/v3/series/lookup?term=tvdb:`)
    if the series isn't in the library.
- **Upload** with `POST /Items/{id}/Images/Primary`, body = **base64** of the jpeg,
  header `Content-Type: image/jpeg`. Success is **HTTP 204**. This always targets
  the item's own Primary slot — for a series that sets the series-level image
  specifically, which is the one TV apps read (as opposed to falling back to a
  season image the way the web UI does).
- **Verify** by re-fetching the Primary image and confirming it is now portrait.

## If it reverts later

A normal metadata refresh leaves a user-set image alone. But a Jellyfin refresh
run with **"Replace existing images"** checked can re-grab the embedded frame (or
drop back to no series image) and undo this. If that keeps happening for a
title, the durable fix is a local `poster.jpg` in the item's folder —
`/media/data/media/movies/<Title>/` for a movie, `/media/data/media/tv/<Series>/`
for a series — a local `poster.jpg` outranks whatever the provider scrape
produces, permanently. Offer that only if the revert actually recurs; the
script is the normal path.
