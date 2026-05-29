#!/usr/bin/env bash
# Stage 2: WSL Ubuntu bootstrap.
# Run inside fresh Ubuntu after first-run setup:
#
#   bash <(curl -fsSL https://raw.githubusercontent.com/HexagonStorms/brain/main/bootstrap/wsl.sh)
#
# Bash (not zsh) on purpose — zsh isn't installed yet on a fresh Ubuntu and
# `curl | bash` only has bash to lean on. Once this finishes, zsh is the
# default shell and everything else uses zsh per Jo's preference.
#
# Idempotent. Re-running upgrades packages and re-runs setup.sh.

set -euo pipefail

step() { printf '\n==> %s\n' "$1"; }

# --- system packages ------------------------------------------------------

step "Updating apt and installing base packages"
sudo apt-get update -y
sudo apt-get install -y \
    zsh git curl wget jq make build-essential ca-certificates gnupg \
    unzip pkg-config software-properties-common file

# --- gh CLI ---------------------------------------------------------------

if ! command -v gh >/dev/null 2>&1; then
    step "Installing GitHub CLI"
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    sudo apt-get update -y
    sudo apt-get install -y gh
fi

# --- Node (via NodeSource) ------------------------------------------------

if ! command -v node >/dev/null 2>&1; then
    step "Installing Node.js LTS"
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# --- Homebrew (Linuxbrew) -------------------------------------------------

if ! command -v brew >/dev/null 2>&1 && [[ ! -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    step "Installing Homebrew (Linuxbrew)"
    NONINTERACTIVE=1 /bin/bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# --- Claude Code CLI ------------------------------------------------------

if ! command -v claude >/dev/null 2>&1; then
    step "Installing Claude Code"
    curl -fsSL https://claude.ai/install.sh | bash
fi

# --- ~/Code and brain -----------------------------------------------------

mkdir -p "$HOME/Code"
if [[ ! -d "$HOME/Code/brain/.git" ]]; then
    step "Cloning brain repo"
    # HTTPS for the first clone; switch to SSH after keys are restored.
    git clone https://github.com/HexagonStorms/brain.git "$HOME/Code/brain"
fi

# --- shells ---------------------------------------------------------------

if [[ "$(getent passwd "$USER" | cut -d: -f7)" != "$(command -v zsh)" ]]; then
    step "Setting zsh as default shell"
    sudo chsh -s "$(command -v zsh)" "$USER"
fi

# Minimal .zshrc — keep it tiny; brain memory + CLAUDE.md carry the rest.
if [[ ! -f "$HOME/.zshrc" ]]; then
    cat > "$HOME/.zshrc" <<'ZSHRC'
# Linuxbrew
if [[ -d /home/linuxbrew/.linuxbrew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
# Claude Code
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
ZSHRC
fi

# --- git identity ---------------------------------------------------------

if [[ ! -f "$HOME/.gitconfig" ]]; then
    step "Writing minimal ~/.gitconfig (restore from backup if you have it)"
    cat > "$HOME/.gitconfig" <<'GITCONFIG'
[user]
	name = Josh Plaza
	email = plazajosue2@gmail.com

[init]
	defaultBranch = main

[pull]
	rebase = false

# Anything cloned under ~/Code/automatiq/ uses the work identity.
[includeIf "gitdir:~/Code/automatiq/"]
	path = ~/.gitconfig-automatiq
GITCONFIG
fi

# --- wire the brain into ~/.claude ---------------------------------------

step "Running brain setup.sh"
zsh "$HOME/Code/brain/setup.sh"

# --- final notes ----------------------------------------------------------

cat <<'EOF'

==> Stage 2 complete.

Manual steps that still need you:

  1. Restore SSH keys from your encrypted backup to ~/.ssh/, then:
       chmod 700 ~/.ssh
       chmod 600 ~/.ssh/id_ed25519 ~/.ssh/lenovo ~/.ssh/siloh ~/.ssh/config
       chmod 644 ~/.ssh/id_ed25519.pub ~/.ssh/lenovo.pub

  2. Switch the brain remote to SSH once keys are in place:
       git -C ~/Code/brain remote set-url origin git@github.com:HexagonStorms/brain.git

  3. Authenticate gh:
       gh auth login

  4. Restore ~/.config/gh/ and ~/.claude/.credentials.json from backup
     (or re-auth Claude Code interactively with `claude`).

  5. Re-clone work repos under ~/Code/ as needed:
       gh repo clone HexagonStorms/cascaderescue ~/Code/cascaderescue
       gh repo clone Past-Lives-Makerspace/plfog  ~/Code/plfog
       # automatiq workspace: clone each subrepo into ~/Code/automatiq/
EOF
