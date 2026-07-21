---
name: project_qbit_upload_throttle
description: qBittorrent seeding saturated the WiFi uplink and buffered Jellyfin; fix evolved from a static API cap to an adaptive one that yields the uplink to streams. qBit 5.x renamed the conf rate-limit key.
metadata: 
  node_type: memory
  type: project
  originSessionId: c4be9798-25f5-441a-bd20-4fab1de4f280
---

On elowynn's media stack, qBittorrent seeding (~18-23 Mbit/s up via gluetun/PIA) saturated the WiFi uplink (`wlo1`) and starved remote Jellyfin streams through the Cloudflare tunnel, causing buffering. Diagnosed 2026-06-16 by measuring per-source TX: stopping qBit dropped `wlo1` tx from 32 to 9 Mbit/s.

**Root cause / gotcha:** qBittorrent 5.x (5.2.1 here) renamed the upload-limit conf key to `Session\GlobalUPSpeedLimit` (KiB/s). The old `Session\GlobalUPLimit` is a dead legacy key it ignores, so editing the conf upload limit is a silent no-op. µTP was NOT the cause (`limit_utp_rate` was already true); an early TCP-only theory was wrong.

**The fix (durable, applied):** set the cap through the WebUI API, where it is actually enforced. Set `up_limit` ~500000 bytes/s (~4 Mbit/s), kept `bittorrent_protocol=0` (TCP+µTP). Settled to ~2.9 Mbit/s up, leaving the uplink free for streaming. qBit persists this to the conf as `Session\GlobalUPSpeedLimit=488` on change.

**How to reach the API:** creds are in `~/Code/elowynn-media-server/.env` as `QBIT_USER` / `QBIT_PASS`. qBit shares gluetun's netns so the host isn't seen as localhost (LocalHostAuth bypass never triggers); log in normally instead:
```
U=$(grep '^QBIT_USER=' .env|cut -d= -f2-); P=$(grep '^QBIT_PASS=' .env|cut -d= -f2-); CJ=$(mktemp)
curl -s -c "$CJ" -H 'Referer: http://127.0.0.1:8080' --data-urlencode "username=$U" --data-urlencode "password=$P" http://127.0.0.1:8080/api/v2/auth/login
curl -s -b "$CJ" -H 'Referer: http://127.0.0.1:8080' --data-urlencode 'json={"up_limit":500000}' http://127.0.0.1:8080/api/v2/app/setPreferences
```
(The `Referer` header is NOT actually required from the host: the proven `sync-qbit-port.sh` logs in via cookie with no Referer and works. The 2026-06-16 403 was likely something else. Use the cookie/`QBT_SID_8080` pattern.) To change the cap by hand, use this or the WebUI at `qbit.plaza.codes` (Jo has the password).

**Superseded 2026-06-19 by an adaptive cap.** The static cap starved seeding ("barely seeding"). Now `qbit-adaptive-cap.sh` (a `qbit-adaptive-cap` systemd user timer, every 60s) flips between 4 Mbit/s (busy) and 20 Mbit/s (quiet 10+ min). "Busy" = Jellyfin `/Sessions` has a `NowPlayingItem` OR non-qBit `wlo1` upload > 4 Mbit/s (wlo1 tx rate minus qBit's `up_info_speed`; catches Stash and anything else without per-app polling). Usable uplink measured ~27 Mbit/s. Jellyfin key in `.env` as `JELLYFIN_API_KEY`. Full detail in `~/Code/elowynn-media-server/CLAUDE.md` ("Upload Bandwidth Management"). See [[reference_hetzner_vps]] for wider stack context.
