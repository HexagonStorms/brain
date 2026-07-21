---
name: project_gpu_upscale
description: "Free open-source AI video upscaling on Polaris's RTX 5080 (Real-ESRGAN), driven from elowynn."
metadata: 
  node_type: memory
  type: project
  originSessionId: b020d9d7-230a-4370-8573-628bdc1d03b0
  modified: 2026-07-21T14:19:50.839Z
---

AI video upscaling runs on **Polaris** (RTX 5080), not elowynn (elowynn has only an Intel UHD 770 iGPU, unusable for this). Driven over SSH from elowynn: see [[reference_polaris_ssh]].

Stack at `C:\upscale\` on Polaris:
- `bin\realesrgan-ncnn-vulkan.exe` + models (x4plus photo, x4plus-anime, animevideov3), Vulkan GPU path, no CUDA toolkit needed.
- ffmpeg 8.1.2 (winget Gyan.FFmpeg).
- `scripts\upscale.ps1` — video pipeline: extract frames, batch-upscale on GPU, reassemble with original audio. Params: `-In -Out -Model -Scale -Crf`.
- `scripts\install.ps1` — rebuilds the stack.

**Why:** started free before spending $300 on Topaz Video AI (which has a watermarked trial as a later comparison). Verified working: 480p→1920p true 4x.

**Wrapped into the `/upscale` skill** ([[skill-upscale]]): orchestrator at `~/Code/elowynn-media-server/upscale/upscale.mjs` takes a Stash scene URL, ships to Polaris, upscales, re-imports as a **separate** cross-linked scene (Upscaled tag + copied performers/studio/tags + frame cover; both descriptions link to each other), ntfy on done. Auto-picks scale from source short edge (≤600→4x, ≤1200→2x, else refuse). Verified end-to-end 2026-07-21.

**How to apply:** throughput ~3 fps at 480p→1920p (a 16-min clip ≈ 2.5-3 hr + ~150-200 GB temp PNGs, so overnight/batch — always run the orchestrator backgrounded). Faster options if needed: CUDA/PyTorch build, or force `--scale 2`.
