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
    unzip pkg-config software-properties-common file \
    ripgrep fzf openssh-client

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

# --- Render CLI (via Homebrew) -------------------------------------------

# brew was just installed but isn't on PATH for this shell yet; source it.
if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

if command -v brew >/dev/null 2>&1 && ! command -v render >/dev/null 2>&1; then
    step "Installing Render CLI"
    brew install render
fi

# --- Resend CLI (via npm) -------------------------------------------------

if command -v npm >/dev/null 2>&1 && ! command -v resend >/dev/null 2>&1; then
    step "Installing Resend CLI"
    sudo npm install -g resend-cli
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

# --- SSH: per-machine key + host config ----------------------------------

# Per-machine key, named after the Linux username (so it's obvious whose key
# this is when added to authorized_keys on a server). Matches the Lenovo
# pattern (~/.ssh/lenovo) but uses $USER per the new-machine convention.

SSH_KEY_NAME="$USER"
SSH_KEY_PATH="$HOME/.ssh/$SSH_KEY_NAME"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [[ ! -f "$SSH_KEY_PATH" ]]; then
    step "Generating SSH keypair ~/.ssh/$SSH_KEY_NAME"
    ssh-keygen -t ed25519 -f "$SSH_KEY_PATH" -N "" \
        -C "$USER@$(hostname) $(date +%Y-%m-%d)"
fi

# Install ~/.ssh/config from the brain template, substituting the key name.
# Only write it if no config exists yet — never clobber a restored config.
if [[ ! -f "$HOME/.ssh/config" && -f "$HOME/Code/brain/claude-config/ssh-config.example" ]]; then
    step "Installing ~/.ssh/config from brain template"
    sed "s|__SSHKEY__|$SSH_KEY_NAME|g" \
        "$HOME/Code/brain/claude-config/ssh-config.example" \
        > "$HOME/.ssh/config"
    chmod 600 "$HOME/.ssh/config"
fi

# --- wire the brain into ~/.claude ---------------------------------------

step "Running brain setup.sh"
zsh "$HOME/Code/brain/setup.sh"

# --- final notes ----------------------------------------------------------

step "Stage 2 complete."

cat <<EOF

Your new SSH public key (~/.ssh/${SSH_KEY_NAME}.pub):

$(cat "${SSH_KEY_PATH}.pub")

Add it to each service before that service will accept connections:

  GitHub (HexagonStorms):
      gh auth login            # interactive web flow
      gh ssh-key add ~/.ssh/${SSH_KEY_NAME}.pub --title "$(hostname)"

  Hetzner VPS (plaza.codes, root@5.78.148.196):
      ssh-copy-id -i ~/.ssh/${SSH_KEY_NAME}.pub root@5.78.148.196
      # or paste the pubkey above into /root/.ssh/authorized_keys

  Elowynn (over Tailscale):
      # install Tailscale first (curl -fsSL https://tailscale.com/install.sh | sh)
      # then: tailscale up
      ssh-copy-id -i ~/.ssh/${SSH_KEY_NAME}.pub jo@elowynn

Manual steps that still need you:

  1. Restore the Automatiq work key (id_ed25519) from your encrypted
     backup if you need to push to work repos:
         chmod 600 ~/.ssh/id_ed25519
         chmod 644 ~/.ssh/id_ed25519.pub

  2. Once GitHub has the new key, switch the brain remote to SSH:
       git -C ~/Code/brain remote set-url origin git@github.com:HexagonStorms/brain.git

  3. Restore ~/.config/gh/ and ~/.claude/.credentials.json from backup
     (or re-auth interactively: \`gh auth login\` and \`claude\`).

  4. Authenticate the new CLIs:
       render login
       resend login   # or export RESEND_API_KEY=...

  5. Re-clone work repos under ~/Code/ as needed:
       gh repo clone HexagonStorms/cascaderescue ~/Code/cascaderescue
       gh repo clone Past-Lives-Makerspace/plfog  ~/Code/plfog
       # automatiq workspace: clone each subrepo into ~/Code/automatiq/
EOF
