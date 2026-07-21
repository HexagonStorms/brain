---
name: reference_polaris_ssh
description: "SSH access from elowynn into Polaris (Windows, RTX 5080) over the tailnet."
metadata: 
  node_type: memory
  type: reference
  originSessionId: b020d9d7-230a-4370-8573-628bdc1d03b0
  modified: 2026-07-21T13:17:22.047Z
---

Polaris is Jo's Windows workstation with an **RTX 5080** (16 GB, driver 610.74), reachable from elowynn as `ssh polaris` (config entry: user `plaza`, key `~/.ssh/siloh`, tailnet host `polaris` = 100.116.170.117).

Set up via native Windows **OpenSSH Server** (sshd auto-start, default shell PowerShell, tailnet-only). Elowynn's ed25519 pubkey lives in `C:\ProgramData\ssh\administrators_authorized_keys`.

Gotcha for future rebuilds: that admin key file must be **owned by BUILTIN\Administrators** (not the user who created it) with ACLs locked to Administrators + SYSTEM, or sshd silently rejects the key (`Permission denied (publickey)`). Fix: `icacls <file> /setowner "BUILTIN\Administrators"` then re-grant.

Drive PowerShell via `ssh polaris '<cmd>'`; for multi-step work, scp a `.ps1` and run `powershell -NoProfile -ExecutionPolicy Bypass -File`. Related: [[project_gpu_upscale]].
