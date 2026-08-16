---
name: wifi-recovery
description: >-
  Diagnose and fix slow, laggy, or high-latency wifi on the elowynn machine.
  Use this whenever Jo says the wifi/internet/network is slow, "super slow",
  laggy, buffering, or that things feel unresponsive over the network, even if
  he does not say the word "wifi". The usual root cause is the Intel card
  wedging onto the crowded 2.4 GHz band; the fix is a reassociate that flips it
  back to 5 GHz. Also covers ruling out bandwidth hogs (qBittorrent). Elowynn is
  wifi-only (workshop warehouse); never suggest ethernet.
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
  is already fine; the slowness is something else (go to step 4).

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

## The durable fix (wifi-only — do NOT suggest ethernet)

Ethernet is not an option and never will be: elowynn lives in a workshop
warehouse with no way to run a wire to the router. Do not propose plugging in
`enp3s0`, staging a netplan change, or "the real fix is a wire." Jo has ruled
this out repeatedly; raising it again is the wrong move.

The durable fix within wifi is a **ping-and-reassociate watchdog**: a small
systemd user timer that pings the gateway every minute and, when RTT crosses a
threshold (or the card reports `FREQUENCY=24xx`), runs the step-3 recovery
automatically. That turns this from a manual chore into a self-heal. Offer to
stage it if the band-flip keeps recurring; otherwise this skill is the manual
path.
