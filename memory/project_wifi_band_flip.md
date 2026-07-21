---
name: project_wifi_band_flip
description: elowynn wifi goes slow when the Intel card wedges onto 2.4 GHz; reassociate flips it back to 5 GHz.
metadata: 
  node_type: memory
  type: project
  originSessionId: 0c3661c8-033e-4789-88b0-7d5c39aa56e2
---

Elowynn is on wifi (`wlo1`, Intel `iwlwifi`), not ethernet. Recurring failure:
the card reconnects onto the AP's crowded **2.4 GHz** radio (ch6, ~86 Mbps,
weak RSSI ~-73), and latency to the gateway spikes to ~1 s even at near-zero
traffic. Fix is `sudo wpa_cli -i wlo1 reassociate`, which flips it to **5 GHz**
(ch36, 80 MHz, ~866 Mbps, RSSI ~-54); gateway RTT drops from ~1000 ms to ~2 ms.

**Why:** distinct from the qBittorrent uplink-saturation issue — this is a radio
band problem, not a bandwidth hog. Low throughput + high latency = radio, not
saturation.

**How to apply:** the full runbook is the `wifi-recovery` skill. Diagnose by
pinging the gateway (`10.0.0.1`) to isolate the wifi hop; `iw`/`iwconfig`/`nmcli`
are not installed, use `wpa_cli`. `sudo` is passwordless on elowynn. Durable fix
is wiring up `enp3s0` (ethernet, currently DOWN). Related: [[project_qbit_upload_throttle]].
