# Bootstrap a fresh Windows + WSL machine

Two-stage install. Stage 1 runs on Windows (sets up Wi-Fi, WSL, and winget apps).
Stage 2 runs inside WSL Ubuntu (sets up the dev environment and wires the brain).

## Order of operations

1. **Restore sensitive backups first** (SSH keys, gh tokens, Claude credentials).
   These do not live in this repo — see `manual-restore.md`.

2. **Stage 1 — Windows side.** Open PowerShell as Administrator and run:

   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   irm https://raw.githubusercontent.com/HexagonStorms/brain/main/bootstrap/windows.ps1 | iex
   ```

   Or clone first and run locally:

   ```powershell
   git clone https://github.com/HexagonStorms/brain.git $env:USERPROFILE\Code\brain
   & $env:USERPROFILE\Code\brain\bootstrap\windows.ps1
   ```

   Reboot when prompted (WSL kernel install needs it).

3. **Stage 2 — WSL side.** Launch Ubuntu, complete the first-run user setup, then:

   ```bash
   bash <(curl -fsSL https://raw.githubusercontent.com/HexagonStorms/brain/main/bootstrap/wsl.sh)
   ```

4. **Restore SSH keys** from the encrypted backup into `~/.ssh/` and `chmod 600`.

5. **Run `zsh ~/Code/brain/setup.sh`** to wire the brain into `~/.claude/`.

6. **Install manually** the apps not available via winget (see `manual-restore.md`).

## What stage 1 does

- Joins the home Wi-Fi (SSID "friendly neighborhood spiderman").
- Enables WSL2 and installs Ubuntu.
- Installs the standard Windows app set via `winget`.

## What stage 2 does

- Installs zsh, git, gh, build tools, Node, Docker CLI hooks for Docker Desktop.
- Creates `~/Code/` and clones the brain.
- Installs Claude Code CLI.
- Installs Homebrew (Linuxbrew).
- Configures git identity.
