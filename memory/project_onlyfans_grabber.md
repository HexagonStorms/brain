---
name: project_onlyfans_grabber
description: "How to grab an OnlyFans creator into Stash via stash-grab — cred refresh, filters, DRM reality."
metadata: 
  node_type: memory
  type: project
  originSessionId: 76c61d91-e7a3-41bd-a667-744111bb0a07
---

stash-grab has an OnlyFans extractor (`stashgrab/extractors/onlyfans.py`). It signs the private OnlyFans API and pulls non-DRM media into Stash. Creator maps to studio + performer; photos from a creator all fold into ONE growable gallery named `<creator>`.

**Run a grab** (inside the container, code is baked into the image so rebuild after edits):
`docker exec stash-grab python /app/stash-grab "<url>" --tag foo --tag "two words"`
- Whole creator: `https://onlyfans.com/<user>` — all media.
- Video/photo only: add a `/videos` or `/photos` tab to the URL.
- Min video length (per run): prepend `-e OF_MIN_VIDEO_SECONDS=120` to the `docker exec`.
- Single post: `https://onlyfans.com/<postid>/<user>`.

**Credentials** live in media-server `.env` (gitignored): `OF_AUTH_ID`, `OF_SESS`, `OF_XBC`, `OF_UA`. When grabs start returning HTTP 400 "Wrong user":
- `OF_SESS` rotates on every logout/login — recopy the `sess` cookie.
- `OF_UA` must be the EXACT user-agent of the browser that made the session; a guessed UA is rejected. The session that built the current creds was Android Firefox.
- `OF_XBC` is the `bcTokenSha` value from localStorage (NOT cookies); stable across logins.
- Signing rules come from `DATAHOARDERS/dynamic-rules/main/onlyfans.json` (override via `OF_RULES_URL` if it goes stale).

**DRM:** OnlyFans Widevine-encrypts much of its video; those need a CDM we don't have, so phase one skips them (logged as "skip onlyfans media X (DRM)"). Prevalence varies wildly by creator — boobyb0y was 0% DRM, bunnybunzzzz was 227/365. Photos are rarely DRM'd. If a migrated account starts DRM-ing new posts, the skips will show in the log.

Reruns re-download rather than dedup (ofgrab:// unit ids don't match stored onlyfans.com URLs), but filenames are deterministic so scans update in place instead of duplicating. Related: [[project_stash_tv]].
