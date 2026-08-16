---
name: project_legato_yarg_app
description: The YARG chart-downloader CLI project at ~/Code/legato-yarg-app
metadata:
  node_type: memory
  type: project
---

`~/Code/legato-yarg-app` (private repo `HexagonStorms/legato-yarg-app`, see [[reference_hexagonstorms_github]]). Lives on **legato**.

Dependency-free Python CLI that downloads YARG charts from the Encore API (enchor.us — the database behind the Bridge desktop app). YARG v0.14.0 is installed on Windows via the YARC Launcher; songs go to `C:\Users\plaza\Documents\YARG Songs` (= `/mnt/c/Users/plaza/Documents/YARG Songs`), which must be added in YARG → Settings → Songs.

Plays with an **Alesis Nitro Pro** electronic kit (USB-MIDI, class-compliant, no driver needed) in YARG's **Pro Drums** mode. Bind map: Kick; Snare→Red pad; toms→Yellow/Blue/Green pads; Hi-hat→Yellow cymbal; Ride→Blue cymbal; Crash→Green cymbal. Got it working June 2026 after a long session. Gotcha for next time: this PC has Windows 11 25H2 with in-box **Windows MIDI Services (midisrv)**, which had a WinRT timestamp bug that can make e-kits enumerate but send no notes; disabling midisrv breaks YARG (it uses WinRT) so leave it enabled. User also runs Ableton (needs midisrv). Diagnostic: a WinMM MIDI monitor + checking the module's own headphone/screen output isolates kit-vs-Windows.

Key facts learned (also in the repo README):
- **Pro Drums** works: `instrument=drums` + `drumType=fourLanePro`. **Pro Keys is NOT available via Encore** (scan-chart doesn't index RB pro-keys; only 5-lane `keys`). Bridge can't do it either — pro-keys needs the Rock Band customs ecosystem (CON files).
- Encore API quirks: `/search` instrument filters are unreliable (use `/search/advanced`); `drumsReviewed` defaults true server-side and hides unreviewed drum charts (client sends false). Download = `GET https://files.enchor.us/{md5}.sng`. Rate-limits with HTTP 429 on rapid loops — throttle ~0.7s + exponential backoff for bulk audits.
- **Difficulty coverage:** many custom charts are Expert-only (charter never authored easy/medium/hard reductions); YARG only shows what's in the file and can't generate the rest. `notesData.noteCounts` = `[{instrument,difficulty,count}]` is the signal. Harmonix/official RB charts (the ~2,155 from the bulk pull) always have all 4; only the ~117 customs are at risk. `downloader.rank_key()` sorts charts (most drum diffs → Harmonix → total tiers) and `_bulk` picks the fullest per song. `upgrade_difficulties.py` audits customs and swaps in fuller versions where they exist. Indie/alt bands never in Rock Band (The Strokes, MGMT, Two Door Cinema Club, Hippo Campus, Good Kid, much of SOAD/Nirvana deep cuts) are Expert-only everywhere — no download fixes it.
- **Audio routing gotcha (not the app):** user's Turtle Beach Stealth Pro Gen 2 (2.4GHz dongle, Swarm II) exposes TWO Windows playback endpoints (Game + Chat); YARG must output to the same one the volume dial controls. Earlier confusion: drum-module headphone jack only carries the module's own voices, not PC/YARG audio.
