---
name: project_invader_zim_manual_import
description: Invader ZIM S01 torrent added directly to qBittorrent on 2026-08-16, bypassing Sonarr's grab flow; needs a Sonarr Manual Import once it finishes downloading, or it'll never land in the library.
metadata:
  type: project
---

Invader ZIM Season 1 ("Invader ZIM S01 2 -threesixtyp", infohash `eefd85d12032eb94a3487da6350720726e35f095`, 37 seeders, ~1.4GB) was added directly to qBittorrent on 2026-08-16 (`/data/torrents`, category `tv`) instead of through Sonarr's normal grab flow.

**Why:** Sonarr (series id 99, "Invader ZIM") can't find it through the normal search — Prowlarr's Pirate Bay proxy has plenty of valid Season 1 releases (confirmed directly via raw Torznab query), but returns zero results the moment a `season=` filter is added to the query, even though the same query without the season filter returns 45 matches including clearly S01-tagged episodes. This is a parsing/filtering bug in Prowlarr's Pirate Bay indexer definition, unrelated to the [[project_arr_ipv6_disable]] connectivity fix from the same session — worked around by pulling the release directly from Prowlarr's raw search API and adding it to qBittorrent by hand.

**How to apply — outstanding action:** Sonarr has no record of this download, so it will **not** auto-import when it finishes. Check progress via qBittorrent (`/data/torrents/Invader ZIM S01 2*`) or `docker exec sonarr` logs. Once complete, do a Sonarr **Manual Import** (Series → Invader ZIM → Manual Import, or the `/api/v3/manualimport` scan+import API flow) pointed at the downloaded folder to associate the files with episodes.

Delete this memory once the import is done.
