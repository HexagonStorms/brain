---
name: feedback_no_ethernet_elowynn
description: "Never suggest ethernet/a wire for elowynn's wifi problems; it's a workshop warehouse, wifi-only, permanently."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 26502668-6667-41ac-a6a4-2ed4a9dc35c3
---

Elowynn sits in a workshop warehouse where running an Ethernet cable to the
router is physically impossible. Do NOT propose wiring `enp3s0`, switching the
network config over to ethernet, or "the durable fix is a wire" when the wifi
acts up.

**Why:** Jo has explained this many times and it lands as not listening. The
machine is wifi-only by hard constraint, not by choice.

**How to apply:** Manual recovery for a bad link is `wpa_cli reassociate`,
escalating to `systemctl restart systemd-networkd`. The durable fix that was
actually applied (2026-08-17) is a **wifi** netplan change, `band: 5GHz`, which
stops the card roaming to weak 2.4 GHz-only mesh nodes: see
[[project_wifi_band_flip]]. Note this prohibition is about **ethernet**, not
about netplan in general; editing netplan for wifi reasons is fine and has been
done with Jo's approval. The `wifi-recovery` skill has been updated to match.
