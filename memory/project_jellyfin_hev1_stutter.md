---
name: project_jellyfin_hev1_stutter
description: Jellyfin client stutter on a single title — suspect an MP4 with the hev1 codec tag; remux to MKV.
metadata: 
  node_type: memory
  type: project
  originSessionId: f6c98fba-8f18-4f6a-8c05-1b9f19dbe292
---

When one specific movie stutters in a Jellyfin client (e.g. Wholphin) while the rest of the library plays fine, check the container/codec tag, not the codec itself. The elowynn movie library is ~all 10-bit HEVC (`yuv420p10le`) in **MKV** containers (mp4 tag `[0][0][0][0]`), and those direct-play fine.

The culprit case (Miss Congeniality 2000, 2026-06-20): the lone **MP4** file, tagged **`hev1`** (HEVC parameter sets stored in-band rather than in the MP4 `hvcC` box). `hev1` makes many hardware decoders stutter, and it only bites MP4. Not 10-bit, not corruption (clean software decode), not VFR (CFR 23.976), not server transcode (it was direct-played at ~2 Mbit/s, so the stutter is purely client-side decode).

**Fix (lossless, ~20s):** remux to MKV on the host so ownership stays `jo`:
`ffmpeg -nostdin -i in.mp4 -map 0 -c copy out.mkv` (keep the same filename stem so sidecar `.srt` files still attach). Then delete the old mp4 (it's hardlinked to the torrent seed copy — deleting the media-side link leaves seeding intact), `RefreshMovie` in Radarr (disk rescan, no search), and `POST /Library/Refresh` in Jellyfin.

Alternative minimal fix if keeping mp4: `-c copy -tag:v hvc1` rewrites just the tag.
