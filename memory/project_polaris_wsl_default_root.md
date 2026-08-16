---
name: polaris-wsl-default-root
description: "Polaris WSL Ubuntu keeps getting a root-owned /tmp/claude-1001 at cold boot, blocking Claude Code; the no-default-user cause was fixed 07-27 but it recurred 07-31 from a still-unidentified root session, correlated with Docker Desktop's WSL integration proxy reconnecting."
metadata: 
  node_type: memory
  type: project
  originSessionId: 61b79e6b-691b-4012-ad56-5aa43fd1ce98
  modified: 2026-08-01T17:48:38.655Z
---

Polaris's Ubuntu WSL distro (`/home/josh`, see [[project_polaris_headroom_rc_regression]]) originally had no `[user]` section in `/etc/wsl.conf`, so a bare `wsl -d Ubuntu` (no `-u` flag) landed on root.

**Incident 1 (2026-07-27):** `claude` refused to start with "Temp directory /tmp/claude-1001 is owned by uid 0, expected 1001." `auth.log` showed two PAM login sessions one second apart at WSL boot (12:09:40 josh, 12:09:41 root) — the root session ran `claude` in `~/Code/plfog`, creating `/tmp/claude-1001` owned by root. **Fix applied:** `sudo chown -R josh:josh /tmp/claude-1001` to unblock, then added to `/etc/wsl.conf`:
```
[user]
default=josh
```

**Incident 2 (2026-07-31), same symptom despite the fix:** the WSL instance had cold-booted at 12:36:54 (confirmed via `uptime -s`) — well after the wsl.conf edit — and `/etc/wsl.conf` still had `[user] default=josh` intact. Yet at 12:54:26 a root PAM session opened again (`login[858]`, followed by an explicit **"ROOT LOGIN on /dev/pts/3"** log line — this is a real login-prompt root auth, not a plain default-user fallback), and 2 seconds later `claude` created `/tmp/claude-1001/-home-josh-Code-plfog/<uuid>` — same project path as incident 1. So the `[user] default=josh` fix is real and holding (it stops the *no-default* failure mode) but does **not** stop something from explicitly authenticating as root at every cold boot.

Correlated but **not proven** as the trigger: `ps` showed `docker-desktop-user-distro proxy --distro-name Ubuntu` running as root (PID varies), and `/mnt/wsl/docker-desktop/{cli-tools,shared-sockets}` plus a pile of `mnt-wsl-docker-desktop-bind-mounts-Ubuntu-*.mount` units were all freshly created at 12:54 — the same few seconds as the root login. Docker Desktop auto-starts at Windows login (`AutoStart: true` in `%APPDATA%\Docker\settings-store.json`, also in the `HKCU Run` key) and its WSL2 integration is known to connect into an integrated distro as root to wire up socket/CLI forwarding, which plausibly explains a root session appearing at every cold boot. **What this does NOT explain:** why that root context then runs `claude` in `~/home/josh/Code/plfog` — checked and ruled out: no `/root/.claude` (root's own config dir doesn't exist, so it isn't a self-contained root run), no `claude` reference in `/root/.bashrc`, `/root/.profile`, or any `/etc/profile.d/*.sh`, no cron/systemd-timer/Scheduled Task referencing `wsl` or `claude`, no tmux-resurrect/continuum setup (no `~/.tmux/resurrect`, no tmux server running). The dir naming (`-home-josh-Code-plfog`, matching josh's `$HOME`) shows the offending process had `HOME=/home/josh` while its real credentials were still root (euid 0) — so whatever ran `claude` did so with root privileges but josh's home environment. Root cause of *that specific launch* is still open.

**Fix applied (2026-08-01):** `sudo chown -R josh:josh /tmp/claude-1001` again — same non-destructive unblock, no wsl.conf or Docker changes made this round (didn't want to disable Docker Desktop's Ubuntu integration without checking whether Josh relies on `docker` CLI working inside that distro).

**How to apply:** Don't assume `[user] default=josh` in wsl.conf is sufficient proof against recurrence — it only fixes the *no-default* path, not an explicit root login. When this resurfaces: (1) `stat /tmp/claude-1001` for birth time, (2) `wsl -d Ubuntu -u josh -- uptime -s` to get boot time, (3) grep `auth.log` around boot time for `login[...]` and "ROOT LOGIN" lines (not just CRON entries, which are normal hourly noise), (4) `sudo find /tmp/claude-1001 -printf '%u %p\n'` to recover which project path the root run targeted — if it's `~/Code/plfog` again, that's the same recurring pattern. Worth checking next time: whether Docker Desktop's WSL integration for "Ubuntu" can be scoped off (Docker Desktop Settings > Resources > WSL Integration) without breaking Josh's actual Docker use, as a way to falsify/confirm the correlation. A durable self-heal (a wsl.conf `[boot] command=` entry that chowns stray root-owned `/tmp/claude-*` a few seconds after boot) would sidestep needing the exact culprit but hasn't been proposed/applied yet — pending Jo's sign-off since it touches boot-level WSL config.
