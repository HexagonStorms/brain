---
name: project_onlyfans_drm
description: "OnlyFans Widevine DRM decryption pipeline in stash-grab — how it works, the license-endpoint gotchas, and the CDM plan."
metadata: 
  node_type: memory
  type: project
  originSessionId: e0345bc7-d7bf-4a0b-b94d-9f2497c9dc55
  modified: 2026-07-20T17:10:45.904Z
---

stash-grab can now decrypt OnlyFans Widevine DRM video (built 2026-07-20), not just skip it. Code lives in `~/Code/stash-grab/stashgrab/extractors/onlyfans_drm.py` + additions to `onlyfans.py`. Flow per video: fetch DASH MPD with the IP-locked CloudFront cookies → parse Widevine PSSH + best A/V reps → CDM makes a license challenge → we POST it to OnlyFans (signed) → CDM returns keys → download encrypted single-file MP4s → mp4decrypt (ffmpeg fallback) → mux.

Hard-won facts (verified against live bunnybunzzzz data — a heavily-DRM'd creator, good test target):
- **License endpoint:** `POST /api2/v2/users/media/{mediaId}/drm/post/{postId}?type=widevine`, signed with the same dynamic-rules `_headers()`. It is POST-only; a GET returns 404 "Route not found" (misleading).
- **Content-Type MUST be `application/octet-stream`.** Without it OnlyFans' PHP/CodeIgniter backend parses the raw challenge as form data and rejects it with `"Disallowed key characters in global data."`. With it, a garbage challenge returns JSON `{"error":...,"Getting license error"}`; a real challenge returns raw license bytes (so `body[:1]==b"{"` means error).
- The whole transport chain is proven; the only untested piece is the CDM itself.

**The CDM (the gate):** need a Widevine L3 `device.wvd`. The free remote CDM (cdrm-project.com / cdm-project.com, both → 104.244.75.11) was **down/unreachable** on 2026-07-20 (443 times out from host and container). Plan: extract our OWN L3 CDM on **Polaris** (Windows desktop; elowynn is headless) via Android Studio emulator (API 29, non-Play image) + KeyDive, per `~/Code/stash-grab/docs/widevine-cdm-extraction.md`. Then `scp` device.wvd to `~/Code/elowynn-media-server/stash-grab/device.wvd` (= container `/config`, already gitignored), set `WV_WVD_PATH=/config/device.wvd`, rebuild the image (adds pywidevine, defusedxml, mp4decrypt).

Config: `[widevine]` section / `WV_*` env (wvd_path, or remote_host/secret/device for a pywidevine serve remote — the remote only sees Widevine blobs, never OF auth). pywidevine `RemoteCdm` and local `Cdm` share one interface, so swapping remote↔local is one line.

Status as of 2026-07-20: code-complete, unit-tested (MPD parser), NOT yet live-tested — waiting on the Polaris `.wvd`. Changes uncommitted in the stash-grab repo. Related: [[project_onlyfans_grabber]], [[project_stash_tv]].
