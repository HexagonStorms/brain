---
name: project_arr_ipv6_disable
description: Radarr/Sonarr/Prowlarr containers have no IPv6 route but their metadata/indexer proxy hosts resolve AAAA records too, causing intermittent "Resource temporarily unavailable" failures; fixed via DOTNET_SYSTEM_NET_DISABLEIPV6=true.
metadata:
  type: project
---

Radarr, Sonarr, and Prowlarr on elowynn intermittently threw `System.Net.Http.HttpRequestException: Resource temporarily unavailable` when calling their external metadata/indexer proxies (`api.radarr.video`, `skyhook.sonarr.tv`, and indexer proxy hosts like `apibay.org`, `movies-api.accel.li`). Root cause: those containers have no IPv6 route out of the Docker bridge network (`ip -6 addr` shows only loopback), but the proxy hosts are Cloudflare-fronted and resolve AAAA records too — the .NET HTTP client intermittently tries the dead IPv6 path before falling back to the working IPv4 one.

Fixed 2026-08-16 by adding `DOTNET_SYSTEM_NET_DISABLEIPV6=true` to the environment block of each affected service in `~/Code/elowynn-media-server/docker-compose.yml`, then `docker compose up -d <service>` to recreate. Applied to `radarr` and `sonarr` first; `prowlarr` was found to have the identical bug later the same session (it was silently failing 5 of 6 configured indexers) and got the same fix.

**Why this matters:** the fix cuts the failure rate a lot but does not eliminate it (~50% → ~15-20% residual in testing) — some genuine transient network blips remain. A Jellyseerr request that fails at this step lands as `FAILED`/media status `UNKNOWN` and silently never reaches Radarr/Sonarr; the user just sees "it never downloaded." The fix is to re-submit the request, not to chase the residual failures further.

**How to apply:** if a *arr-family container (or a future one) shows the same "Resource temporarily unavailable" pattern against an external host, check `ip -6 addr` in the container (expect only `::1`) and `getent ahosts <host>` (expect an AAAA record) to confirm, then apply the same env var and recreate.

**Known gap as of 2026-08-16:** the Prowlarr fix is applied live but **not yet committed** to `docker-compose.yml` in git — `git status` shows it modified, uncommitted. If the compose file is ever regenerated from git without carrying this forward, the fix is lost. Commit it next time touching that repo.

See also [[project_invader_zim_manual_import]] for a separate, unrelated indexer bug found while chasing this (Prowlarr's Pirate Bay proxy drops valid results when a season filter is applied).
