---
name: feedback_no_ethernet_elowynn
description: "Never suggest ethernet/a wire for elowynn's wifi problems; it's a workshop warehouse, wifi-only, permanently."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 26502668-6667-41ac-a6a4-2ed4a9dc35c3
---

Elowynn sits in a workshop warehouse where running an Ethernet cable to the router is physically impossible. Do NOT propose wiring `enp3s0`, staging a netplan change, or "the durable fix is a wire" when the wifi acts up.

**Why:** Jo has explained this many times and it lands as not listening. The machine is wifi-only by hard constraint, not by choice.

**How to apply:** For the recurring 2.4 GHz band-flip (see [[project_wifi_band_flip]]), the recovery is `wpa_cli reassociate`, escalating to `systemctl restart systemd-networkd` if that doesn't move it to 5 GHz. The only durable improvement to offer is a ping-and-reassociate watchdog (systemd user timer), never Ethernet. The `wifi-recovery` skill has been updated to match.
