---
name: project-stash-tv
description: Stash TV plugin chosen for TikTok-style scene swiping; bespoke reel plugin parked unless O-counter/quick-tag gaps grind
metadata: 
  node_type: memory
  type: project
  originSessionId: d0768ecb-f60f-423c-92d4-d1804522f150
---

Jo wanted a TikTok/reel-style swipe viewer for Stash (vertical/horizontal video, swipe for next scene by tag, quick O-counter and tag-edit buttons). On 2026-06-03 we installed **Stash TV** (secondfolder/stash-tv, fork of abandoned Valkyr-JS StashReels) instead of building bespoke; Jo was very happy with it.

Setup facts:
- Stash v0.31.1 at `127.0.0.1:9999`; GraphQL needs ApiKey header, key readable via `docker exec stash grep '^api_key:' /root/.stash/config.yml`.
- Plugin source registered: "secondfolder's plugins (stable)", `https://secondfolder.github.io/stash-plugins/stable/index.yml`, local_path `secondfolder-stable`. Package-manager plugins land in `plugins/<local_path>/<id>`; installs without a registered source land untracked at the plugins root.
- Queue is driven by saved filters (one per tag works).

Parked decision: Stash TV lacks O-counter, quick tag-add, and edit buttons in the player. If those gaps grind in use, build a bespoke plugin modeled on [[graphic-novel-reader]] (`~/Code/stash-graphic-novel-reader`, plain JS, no build step, read-only bind mount) or fork stash-tv (TS monorepo, yarn build).
