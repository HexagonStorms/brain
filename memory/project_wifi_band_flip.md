---
name: project_wifi_band_flip
description: elowynn wifi drops because the card roams to weak 2.4 GHz-only mesh nodes; fixed durably by pinning netplan to band 5GHz.
metadata: 
  node_type: memory
  type: project
  originSessionId: 0c3661c8-033e-4789-88b0-7d5c39aa56e2
---

Elowynn is on wifi (`wlo1`, Intel `iwlwifi`), not ethernet. The "Past Lives
Members" SSID is a multi-AP mesh with two vendor groups:

- `6c:5a:b0:9e:b0:30/31` — the **local** AP, strong (-36 on 2.4, -54 on 5 GHz), the only one with a 5 GHz radio.
- `14:eb:b6:*` — four **distant** nodes, all **2.4 GHz only**, all weak (-73 to -82).

**Root cause (found 2026-08-17):** with no band constraint, the card roams onto
the distant 2.4 GHz nodes, misses beacons, loses carrier, and re-associates.
There is no 802.11r (`[WPA2-PSK-CCMP][ESS]`, no `[FT]`), so every roam is a full
re-auth: carrier drops, DHCPv4 **and** DHCPv6 leases drop, and every established
connection breaks. Symptoms are a Cloudflare **503** on tunnel hosts (cloudflared
loses its QUIC edge connections and cannot dial new ones) plus SSH hanging for
many minutes. Confirm with `sudo dmesg -T | grep -iE 'wlo1|iwlwifi'` (look for
"missed beacons", "Connection to AP lost") and
`journalctl -u systemd-networkd` (look for "Lost carrier" / "DHCP lease lost").

**Durable fix, applied 2026-08-17:** `band: 5GHz` under the access-point in
`/etc/netplan/00-installer-config.yaml`. Netplan renders it as a `freq_list=` of
every 5 GHz channel in `/run/netplan/wpa-wlo1.conf`, which excludes all six weak
2.4 GHz-only nodes without hardcoding a MAC. Backup at
`/root/netplan-00-installer-config.yaml.bak`.

**Why not ethernet:** ruled out permanently, see [[feedback_no_ethernet_elowynn]].
Power save was already off (`power_save N`), so that is not a factor.

**How to apply:** manual recovery is still `sudo wpa_cli -i wlo1 reassociate`
(runbook: `wifi-recovery` skill). When touching netplan on this box, arm a
timed auto-revert first so a bad config cannot strand it:
`sudo systemd-run --on-active=240 --unit=netplan-revert /bin/sh -c 'cp -a /root/netplan-00-installer-config.yaml.bak /etc/netplan/00-installer-config.yaml && netplan apply'`,
then cancel it once verified. Note `iw`/`iwconfig`/`nmcli` are not installed;
use `wpa_cli`. `sudo` is passwordless. A 503 on `*.plaza.codes` is a symptom of
this, not of a dead service. Related: [[project_qbit_upload_throttle]].
