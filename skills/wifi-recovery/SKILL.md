---
name: wifi-recovery
description: >-
  Diagnose and fix slow, laggy, or high-latency wifi on the elowynn machine.
  Use this whenever Jo says the wifi/internet/network is slow, "super slow",
  laggy, buffering, or that things feel unresponsive over the network, even if
  he does not say the word "wifi". Also use it when *.plaza.codes returns a
  Cloudflare 503 or SSH into elowynn hangs for minutes, which are downstream
  symptoms of the same link fault. Root cause is the Intel card ending up on a
  weak 2.4 GHz radio: either wedged on the local AP's 2.4 band, or roamed onto a
  distant 2.4 GHz-only mesh node. Fix is a reassociate; the durable fix
  (netplan band: 5GHz) is already applied. Also covers ruling out bandwidth hogs
  (qBittorrent). Elowynn is wifi-only (workshop warehouse); never suggest ethernet.
---

# Wifi recovery on elowynn

Elowynn is on wifi (`wlo1`, Intel `iwlwifi`) instead of a wire. The failure
mode we see: the card reconnects onto the AP's **2.4 GHz** radio (channel 6,
20 MHz, ~86 Mbps link, weak signal). Symptom is brutal latency even at near-zero
traffic. A reassociate kicks it back to **5 GHz** (channel 36, 80 MHz, ~866 Mbps),
which is the actual fix. This skill diagnoses it, recovers it, and verifies.

Machine facts worth knowing up front:
- Interface `wlo1`, gateway `10.0.0.1`, managed by **systemd-networkd + wpa_supplicant**.
- `iw`, `iwconfig`, and `nmcli` are **not installed**. The tool here is `wpa_cli`.
- `sudo` is passwordless, so you can run recovery yourself.
- `enp3s0` (onboard ethernet) exists but is `DOWN` — that's the real fix (see end).

## 1. Diagnose — isolate the wifi hop

Ping the **gateway**, not the internet. That separates "the wifi link is bad"
from "the internet is bad." If the LAN hop is already a full second, the problem
is between this box and the router, i.e. the radio.

```
GW=$(ip route | awk '/default/{print $3; exit}')
ping -c 5 -i 0.3 -W 2 "$GW" | tail -2
ping -c 5 -i 0.3 -W 2 1.1.1.1 | tail -2
```

Read it like this:
- **Gateway RTT ~1 s, 0% loss** → the wifi link is the bottleneck. Continue.
- Gateway fine (~1–3 ms) but internet bad → it's upstream/ISP, not this skill.

## 2. Confirm it's the radio, not a bandwidth hog

Check the actual band and signal. This is the tell — if it says `FREQUENCY=24xx`
you're stuck on 2.4 GHz.

```
sudo wpa_cli -i wlo1 signal_poll
```

- `FREQUENCY=2437` + `LINKSPEED` under ~150 → wedged on 2.4 GHz. This is the case
  the reassociate fixes. `RSSI` around -73 confirms the weak-band story.
- `FREQUENCY=51xx` with good `RSSI` (-40s/-50s) and high `LINKSPEED` → the radio
  is fine **right now**.

**A healthy poll does NOT exonerate the radio.** `signal_poll` is instantaneous,
so if the link already flapped and recovered, everything looks perfect while the
user is describing a real outage. Whenever the complaint is in the past tense
("it was 503ing", "I couldn't SSH in for 20 minutes"), skip ahead and read the
logs for a carrier drop before concluding it was something else:

```
sudo dmesg -T | grep -iE "wlo1|iwlwifi" | tail -30
sudo journalctl -u systemd-networkd --since "2 hours ago" | grep -iE "carrier|lease"
```

"Lost carrier" / "DHCP lease lost" / "Connection to AP lost" means the link
dropped, and that is your answer no matter how good the current numbers look.

Rule out a bandwidth hog only if the band looks healthy. qBittorrent runs behind
gluetun; its web API is on `127.0.0.1:8080` (creds in
`~/Code/elowynn-media-server/.env` as `QBIT_USER`/`QBIT_PASS`). Note it is
normally upload-throttled, so it's usually **not** the culprit — check before
blaming it:

```
C=$(mktemp)
cd ~/Code/elowynn-media-server
curl -s -c "$C" --data "username=$(grep -m1 QBIT_USER .env|cut -d= -f2)&password=$(grep -m1 QBIT_PASS .env|cut -d= -f2)" http://127.0.0.1:8080/api/v2/auth/login >/dev/null
curl -s -b "$C" http://127.0.0.1:8080/api/v2/transfer/info | jq '{up_Mbps:(.up_info_speed*8/1e6), dn_Mbps:(.dl_info_speed*8/1e6)}'
```

A few Mbps here can't cause second-long latency. If it's pushing tens of Mbps up
and saturating the link, that's a different problem (throttle it) — but that has
not been the observed cause.

## 3. Recover — reassociate (gentlest first)

Reassociation reconnects the card and lets it pick the better band. This is the
primary fix and it's quick (a few seconds); existing SSH/Tailscale sessions
survive the blip.

```
sudo wpa_cli -i wlo1 reassociate
```

If that doesn't move it off 2.4 GHz within ~5 seconds, do the fuller bounce
(drops the network briefly, then recovers):

```
sudo systemctl restart systemd-networkd
```

## 4. Verify — prove it took

Always re-measure. Don't declare victory from the `OK` alone.

```
sudo wpa_cli -i wlo1 signal_poll | grep -E "RSSI|LINKSPEED|FREQUENCY"
GW=$(ip route | awk '/default/{print $3; exit}')
ping -c 5 -i 0.3 -W 2 "$GW" | tail -2
```

Success looks like: `FREQUENCY=51xx`, RSSI in the -40s/-50s, gateway RTT back to
single-digit ms. Report the before/after numbers so Jo can see the delta.

## The durable fix (APPLIED 2026-08-17 — wifi-only, do NOT suggest ethernet)

Ethernet is not an option and never will be: elowynn lives in a workshop
warehouse with no way to run a wire to the router. Do not propose plugging in
`enp3s0` or "the real fix is a wire." Jo has ruled this out repeatedly.

**The fix is already in place.** `/etc/netplan/00-installer-config.yaml` now
carries `band: 5GHz` under the access-point:

```
      access-points:
        "Past Lives Members":
           password: <redacted>
           band: 5GHz
```

Netplan renders that as a `freq_list=` of every 5 GHz channel in
`/run/netplan/wpa-wlo1.conf`. Verify it is still present before doing anything
else; if it has been lost, restoring it is the fix.

### Why that works (root cause, found 2026-08-17)

"Past Lives Members" is a multi-AP mesh with two vendor groups:

| BSSID | Band | Signal | Role |
|---|---|---|---|
| `6c:5a:b0:9e:b0:30` | 2.4 GHz | -36 | local AP, 2.4 radio |
| `6c:5a:b0:9e:b0:31` | 5 GHz | -54 | local AP, **the good one** |
| `14:eb:b6:*` (four of them) | 2.4 GHz only | -73 to -82 | distant nodes |

With no band constraint the card roamed onto the distant 2.4 GHz-only nodes,
missed beacons, and lost carrier. There is no 802.11r (`[WPA2-PSK-CCMP][ESS]`,
no `[FT]`), so each roam is a full re-auth: carrier drops, **DHCPv4 and DHCPv6
leases drop**, and every established connection breaks at once. That is why the
user-visible symptom is often not "slow wifi" but a **Cloudflare 503** (cloudflared
loses its QUIC edge connections and cannot dial new ones) and **SSH hanging**.

Confirm this specific failure with:

```
sudo dmesg -T | grep -iE "wlo1|iwlwifi" | tail -30
sudo journalctl -u systemd-networkd --since "1 hour ago" | tail -20
sudo journalctl -u cloudflared --since "1 hour ago" | grep -iE "quic|Registered"
```

Look for "missed beacons", "Connection to AP lost", "Lost carrier", "DHCP lease
lost". Note cloudflared runs as a **bare process**, not a systemd unit, so find
it with `pgrep -af cloudflared` and read its log via `journalctl _PID=<pid>`.

### If it still flaps

Escalate from the soft band constraint to a hard BSSID pin
(`bssid: 6c:5a:b0:9e:b0:31` alongside `band: 5GHz`). Beyond that, a
ping-and-reassociate watchdog (systemd timer) is the reactive backstop.

### Editing netplan safely

Always arm a timed auto-revert first, so a bad config cannot strand a machine
you can only reach over the network:

```
sudo cp -a /etc/netplan/00-installer-config.yaml /root/netplan-00-installer-config.yaml.bak
sudo systemd-run --on-active=240 --unit=netplan-revert /bin/sh -c 'cp -a /root/netplan-00-installer-config.yaml.bak /etc/netplan/00-installer-config.yaml && netplan apply'
```

Apply, verify association and latency, then cancel with
`sudo systemctl stop netplan-revert.timer`.
