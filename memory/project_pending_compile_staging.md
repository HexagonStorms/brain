---
name: project_pending_compile_staging
description: "Freshly-grabbed creator video scenes are hidden until compiled, via a pending-compile tag + Stash default filter."
metadata: 
  node_type: memory
  type: project
  originSessionId: b020d9d7-230a-4370-8573-628bdc1d03b0
  modified: 2026-07-22T17:34:08.937Z
---

When grabbing a creator to compile, the flood of raw video scenes is hidden from
Stash browsing until the compilation replaces them. Mechanism (built 2026-07-22):

- **Tag:** `pending-compile` (Stash tag). Grabbed VIDEO scenes wear it; photo
  galleries never do (photos are the kept endpoint).
- **Grabber:** `stash-grab` CLI flag `--stage-tag pending-compile` (added to
  `~/Code/stash-grab` grab.py + the `stash-grab` CLI; applied to scene-kind only).
  The [[stash-creator-fetch skill]] grab command now passes it. Omit it for a
  one-off grab you will NOT compile, or the scene stays hidden forever.
- **Hiding:** Stash's Scenes-page default filter excludes the tag. Stored in
  `configuration.ui.defaultFilters.scenes` (set via `configureUISetting`), mirrors
  a saved filter "Hide pending-compile" (SCENES, object_filter tags EXCLUDES).
- **Compiler:** `compilations/lib/tracklist.mjs` exports `STAGE_TAG` and
  `unionTagIds` strips it so the finished compilation stays visible; end of each
  `processCreator` calls `revealStagedScenes(pid, STAGE_TAG)` (bulkSceneUpdate
  REMOVE) to un-hide survivors it never folded in (no-audio / missing-file scenes).

**Why:** grab adds hundreds of scenes that get destroyed at compile; Jo did not
want to see them churn through the library. Only the compilation should surface.

**How to apply:** do not delete the `pending-compile` tag or the default filter;
they are load-bearing. Redgifs/IG compile flows could adopt `--stage-tag` later
(the flag is generic) but do not yet. Rebuild the stash-grab image after editing
its source (`docker compose build stash-grab && docker compose up -d stash-grab`).
