---
name: upscale
description: Use when Jo wants to AI-upscale a video (almost always a Stash scene URL from azium.plaza.codes) to higher resolution. Triggers on "upscale", "enhance", "make it HD/4K", "Real-ESRGAN", "run it through Polaris", or pasting a Stash scene link and asking for a sharper version. Upscales on the Polaris RTX 5080 and re-imports the result as a separate, cross-linked Stash scene.
---

# Upscale a Stash scene on Polaris

One command. Give it a Stash scene URL (or bare scene id); it upscales the video
on Polaris's RTX 5080 with Real-ESRGAN, files the result back into Stash as a
**separate** scene, and cross-links the two so each points at the other. The
original file is never touched.

Engine lives on Polaris (`C:\upscale\`, see [[project_gpu_upscale]]); the
orchestrator runs on elowynn at `~/Code/elowynn-media-server/upscale/upscale.mjs`.

## Run it

Jobs take **hours** for full-length clips (~3 fps on the GPU; a 16-min 480p
source is ~29k frames ≈ 2.5-3 h). Always run in the **background** and let the
ntfy notification (`elowynn-downloads`) announce completion.

```
cd ~/Code/elowynn-media-server/upscale
node upscale.mjs "https://azium.plaza.codes/scenes/<id>" > /tmp/upscale-<id>.log 2>&1 &
```

Watch progress (the GPU pass prints a running percentage):
```
tail -f /tmp/upscale-<id>.log
```

Options (defaults are usually right):
- `--scale N` force 2 or 4 (overrides the auto pick).
- `--model M` `realesrgan-x4plus` (default, photoreal) | `realesr-animevideov3` (animation).
- `--crf N` x264 quality, default 17 (lower = bigger/better).

## What it does, in order

1. Parses the scene id from the URL (`/scenes/<id>`) and reads the scene's file,
   title, performers, studio, tags, and details from Stash.
2. **Auto-picks scale** from the source's shorter edge: ≤600px → 4x, ≤1200px →
   2x, larger → refuses (already high-res; force with `--scale`). Caps output
   near 4K and handles portrait clips.
3. scp's the source to Polaris, runs `upscale.ps1` on the 5080, scp's the result
   to `/media/data/stash/Upscaled/<name> [AI Upscale Nx].mp4`.
4. Scans that folder into Stash and finds the new scene.
5. Copies performers + studio + original tags onto the new scene, adds the
   **Upscaled** tag, sets a real frame cover, titles it `<orig> [AI Upscale Nx]`.
6. **Cross-links**: the upscale's description gets `Upscaled from: <orig url>`;
   the original's description gains `AI upscale (Nx): <upscale url>` (appended,
   never clobbering existing notes).
7. ntfy on success or failure.

## Before you launch

- Confirm Polaris is reachable: `ssh polaris whoami` (see [[reference_polaris_ssh]]).
  If it hangs, the box is asleep or off the tailnet; tell Jo rather than waiting.
- Estimate the job for Jo first: `ffprobe` the source for resolution + duration,
  multiply frames / 3 fps, and say roughly how long it will take before kicking
  it off. Multi-hour jobs deserve a heads-up, not a surprise.

## Notes

- Re-running on the same scene makes a **new** upscale scene each time (the
  forward-link append is idempotent per new id, but a fresh run mints a fresh
  scene). Delete the stale one if you re-run.
- Non-Stash URLs are not supported yet; the script errors clearly. If Jo needs
  one, grab it into Stash first (stash-grab), then upscale that scene.
- Failure at any stage bails loudly and leaves the original untouched; a partial
  `/Upscaled` file can be re-scanned or deleted safely.
