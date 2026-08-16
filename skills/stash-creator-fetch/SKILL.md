---
name: stash-creator-fetch
description: >-
  Pull a creator's full media into Stash and package it: download all photos
  and videos from an OnlyFans (or other stash-grab supported) URL, fold the
  photos into one gallery, and stitch the videos into a compilation. Use this
  whenever Jo says to "grab", "fetch", "download", "rip", or "pull" a creator /
  OnlyFans / model into the server, or asks to make a gallery + compilation from
  a creator URL. Covers the grab, credential refresh when it 400s, pruning
  oversized photos from big galleries, folding in stray clips, and building the
  Shorts/Longs compilation.
---

# Fetch a creator into Stash (gallery + compilation)

Three moves: **grab** the creator's media, let the photos **auto-fold** into one
gallery, then **compile** the videos into one or two stitched scenes. All tooling
already exists on elowynn; this skill is the runbook that ties it together.

Key facts:
- Grabber container: `stash-grab` (code baked into the image; rebuild only after
  editing `~/Code/elowynn-media-server/stash-grab/`).
- Stash data volume: host `/media/data/stash` maps to container `/data`.
- Compile tooling: `~/Code/elowynn-media-server/compilations/` (Node ESM,
  `lib/stash.mjs` is the GraphQL client; creds read from `../.env`).
- Photos from one creator all fold into ONE growable gallery `<creator> (photos)`;
  videos become scenes with the creator as performer + studio.

## 1. Grab the creator

Run it in the **background** (a full creator can take many minutes) and note that
Python **buffers stdout to the pipe** — the log looks empty for a while even
though it is working. Confirm liveness with `docker top`, not the log.

```
docker exec stash-grab python /app/stash-grab --stage-tag pending-compile \
  "https://onlyfans.com/<user>" > /tmp/<creator>-grab.log 2>&1 &
```

Always pass `--stage-tag pending-compile` for a creator you intend to compile.
It tags each grabbed **video scene** (not the photo gallery) with `pending-compile`
as it lands, and Stash's default Scenes filter hides that tag, so the flood of
raw clips never shows up while the grab and compile run. The compile pass
inherits none of it (the finished compilation stays visible) and, when it
finishes, strips the tag from any survivors it did not fold in (no-audio clips,
missing-file scenes), so nothing stays hidden by accident. Omit the flag for a
one-off grab you are NOT going to compile, or it would stay hidden forever.

URL variants:
- Whole creator: `https://onlyfans.com/<user>` (all media).
- Photos or videos only: append `/photos` or `/videos` to the URL.
- Single post: `https://onlyfans.com/<postid>/<user>`.
- Per-run min video length: prepend `-e OF_MIN_VIDEO_SECONDS=120` to `docker exec`.

Watch progress:
```
docker top stash-grab | grep 'stash-grab http'   # alive? (ps inside exec is unreliable)
tail -f /tmp/<creator>-grab.log                  # flushes in bursts
```

Sanity-check counts as it runs (performer id from the first scan lines, or look
it up by name):
```
cd ~/Code/elowynn-media-server/compilations
node --input-type=module -e '
import { gql } from "./lib/stash.mjs";
const p = await gql(`query($n:String!){ findPerformers(performer_filter:{name:{value:$n,modifier:EQUALS}}){ performers{ id name scene_count gallery_count image_count } } }`, { n: "<creator>" });
console.log(JSON.stringify(p.findPerformers.performers));'
```

### If the grab 400s ("Wrong user")

Credentials live in `~/Code/elowynn-media-server/.env` (gitignored):
`OF_AUTH_ID`, `OF_SESS`, `OF_XBC`, `OF_UA`.
- `OF_SESS` rotates on every logout/login — recopy the `sess` cookie.
- `OF_UA` must be the EXACT user-agent of the browser that made the session (a
  guessed UA is rejected; the working session was Android Firefox).
- `OF_XBC` is `bcTokenSha` from localStorage (not cookies); stable across logins.
- Signing rules come from the DATAHOARDERS dynamic-rules repo; override with
  `OF_RULES_URL` if they go stale.

### DRM reality

OnlyFans Widevine-encrypts much of its video; we have no CDM, so those are
skipped in phase one (logged `skip onlyfans media X (DRM)`). Prevalence swings
wildly by creator (0% to most of the catalog). Photos are rarely DRM'd. This is
expected, not a failure.

## 2. Photos: the gallery builds itself

Nothing to do. Every photo folds into one growable gallery named
`<creator> (photos)`, landing at `/data/Unsorted/onlyfans/<creator> (photos)`.
Reruns update files in place (deterministic filenames) rather than duplicating.

To set a nicer gallery cover afterward, pick a member image and use the
gallery-cover mutation with base64 bytes read from disk (NEVER a public
`azium.plaza.codes` URL — those are auth-walled and store the login page as a
broken cover).

### Prune oversized photos (big galleries only)

Policy: a large gallery does not need giant masters. If the creator's photo
folder holds **250 or more** photos, drop every photo whose longest edge is
**> 3840 px** (above 4K), keeping only the 4K-and-under set. Galleries with
**fewer than 250** photos are left fully intact — small sets keep everything.

`prune-oversized.py` (in this skill dir) enforces that. It reads dimensions
straight from the file headers, so it needs nothing beyond bare `python3`. It is
slow on the HDD for thousands of files — run it in the background.

```
cd ~/.claude/skills/stash-creator-fetch
python3 prune-oversized.py "<creator>" --dry-run   # report: count, % and GB it would cut
python3 prune-oversized.py "<creator>"             # do it (only acts if >= 250 photos)
```

Run this AFTER the grab has folded the photos in. Because Stash already indexed
those files, a real prune leaves dangling image records — finish with Stash's
**Clean** library task so the DB drops the rows for the deleted files.

## 3. Fold in stray clips (optional)

To include a video that is not part of the grab (e.g. a Rule34Video rip already
in the vault) in the creator's compilation, just attribute the creator's
performer to that scene — the compile pass gathers every scene where the
performer is `INCLUDES`. Preserve any existing performers:

```
node --input-type=module -e '
import { gql } from "./lib/stash.mjs";
const PID = "<performerId>";
for (const id of ["<sceneId>", ...]) {
  const d = await gql(`query($id:ID!){ findScene(id:$id){ performers{ id } } }`, { id });
  const ids = [...new Set([...d.findScene.performers.map(p=>p.id), PID])];
  await gql(`mutation($i:SceneUpdateInput!){ sceneUpdate(input:$i){ id } }`, { i:{ id, performer_ids: ids } });
}'
```

Find a scene id by title with a full-text query: `findScenes(filter:{q:"<text>"})`.

## 4. Compile the videos

Wait until the grab has finished (no more `stash-grab http` in `docker top`).
Then stitch, once, for this creator:

```
cd ~/Code/elowynn-media-server/compilations
node stash-compile.mjs "<creator>"            # forward build
node stash-compile.mjs "<creator>" --dry-run  # plan only, no writes
```

What it does: splits the creator's clips into **Shorts** (<=5 min) and **Longs**
(>5 min), stitches each bucket oldest-first into one file with a scene marker at
every cut, tags it `Compilation`, then archives the source clips to
`/media/data/.compiled/` and removes their scenes. So a creator ends with one
Shorts and/or one Longs scene depending on what clips exist. If everything is in
one bucket, you get a single compilation video.

If a `<creator> - Shorts/Longs` compilation already exists and there are new
clips, forward build refuses and tells you to rebuild with `--migrate`, which
folds new clips into the existing volume.

Audioless clips are auto-tagged `no-audio` and skipped.

## 5. Covers on the compilation scenes

Give each compilation scene a real frame cover (not a black or placeholder one):

```
node set-cover.mjs <sceneId>       # one scene
node set-cover.mjs                 # all Compilation-tagged scenes
node set-cover.mjs --at 0.25       # seek fraction of duration (default 0.12)
```

It extracts a representative non-black frame with ffmpeg and sends it as a
base64 data-URL via `sceneUpdate.cover_image` — the durable pattern for any
Stash cover (performer image, gallery cover, scene cover): read bytes from disk,
base64-encode, send. Never hand Stash a public URL to fetch.
