#!/usr/bin/env zsh
# brain setup — wire ~/Code/brain into ~/.claude on this machine.
#
# Idempotent. Safe to run any time. Composes ~/.claude/CLAUDE.md from
# CLAUDE.shared.md + machines/<host>.md, and symlinks settings.json and
# memory/ into the spots Claude Code expects.
#
# Usage:
#   zsh ~/Code/brain/setup.sh
#
# Or on a new machine:
#   git clone git@github.com:HexagonStorms/brain.git ~/Code/brain
#   zsh ~/Code/brain/setup.sh

set -euo pipefail

BRAIN_DIR="${0:A:h}"
CLAUDE_DIR="$HOME/.claude"

if [[ ! -f "$BRAIN_DIR/CLAUDE.shared.md" || ! -d "$BRAIN_DIR/machines" ]]; then
    echo "setup: $BRAIN_DIR doesn't look like the brain repo" >&2
    exit 1
fi

mkdir -p "$CLAUDE_DIR"

# Personal dirs Claude is typically launched from. The brain's memory/ is
# symlinked into each one's ~/.claude/projects/<encoded>/memory/, so Claude
# finds it as project memory when working there. Work parents are excluded;
# subdirs of a work parent inherit the exclusion automatically (no symlink,
# no memory load). Re-run setup.sh after cloning a new personal repo under
# ~/Code/ to register it.
WORK_PARENTS=("$HOME/Code/automatiq")

# --- compose CLAUDE.md ---

MACHINE="${MACHINE:-$(hostname | tr '[:upper:]' '[:lower:]')}"
case "$MACHINE" in
    *elowynn*) MACHINE_FILE="$BRAIN_DIR/machines/elowynn.md" ;;
    *polaris*) MACHINE_FILE="$BRAIN_DIR/machines/polaris.md" ;;
    *lenovo*)  MACHINE_FILE="$BRAIN_DIR/machines/lenovo.md"  ;;
    *public*)  MACHINE_FILE="$BRAIN_DIR/machines/lenovo.md"  ;;
    *hetzner*) MACHINE_FILE="$BRAIN_DIR/machines/hetzner.md" ;;
    *)         MACHINE_FILE="" ;;
esac

ABOUT_FILE="$BRAIN_DIR/about-jo.md"

compose() {
    cat "$BRAIN_DIR/CLAUDE.shared.md"
    if [[ -f "$ABOUT_FILE" ]]; then
        printf '\n---\n\n'
        cat "$ABOUT_FILE"
    fi
    if [[ -n "$MACHINE_FILE" && -f "$MACHINE_FILE" ]]; then
        printf '\n---\n\n'
        cat "$MACHINE_FILE"
    fi
}

compose > "$CLAUDE_DIR/CLAUDE.md"

if [[ -n "$MACHINE_FILE" && -f "$MACHINE_FILE" ]]; then
    echo "setup: composed $CLAUDE_DIR/CLAUDE.md from CLAUDE.shared.md + about-jo.md + machines/${MACHINE_FILE##*/}"
else
    echo "setup: composed $CLAUDE_DIR/CLAUDE.md from CLAUDE.shared.md + about-jo.md (no machine file matched '$MACHINE')."
    echo "setup: add a case for this host in setup.sh, or set MACHINE=<name> and rerun."
fi

# --- symlink shared files into ~/.claude ---
# If a real file/dir blocks the symlink path, move it aside with a timestamped suffix.

link() {
    local src="$1" dst="$2"
    if [[ -L "$dst" ]]; then
        ln -sfn "$src" "$dst"
    elif [[ -e "$dst" ]]; then
        local backup="${dst}.machine-backup-$(date +%Y%m%d-%H%M%S)"
        echo "setup: $dst exists — moving to $backup"
        mv "$dst" "$backup"
        ln -s "$src" "$dst"
    else
        ln -s "$src" "$dst"
    fi
    echo "setup: linked ${dst/#$HOME/~} -> ${src/#$HOME/~}"
}

link "$BRAIN_DIR/settings.json" "$CLAUDE_DIR/settings.json"

# Custom slash commands and subagents travel with the brain.
if [[ -d "$BRAIN_DIR/claude-config/commands" ]]; then
    link "$BRAIN_DIR/claude-config/commands" "$CLAUDE_DIR/commands"
fi
if [[ -d "$BRAIN_DIR/claude-config/agents" ]]; then
    link "$BRAIN_DIR/claude-config/agents" "$CLAUDE_DIR/agents"
fi

# Local LLM coding config (aider + ollama), symlinked into $HOME — not ~/.claude.
# Defaults are Polaris-tuned (RTX 5080 / qwen2.5-coder); inert on machines without
# aider+ollama installed. Override per-project with a repo-root .aider.conf.yml.
# See local-llm/README.md for the full setup and run notes.
if [[ -d "$BRAIN_DIR/local-llm" ]]; then
    link "$BRAIN_DIR/local-llm/aider.conf.yml" "$HOME/.aider.conf.yml"
    link "$BRAIN_DIR/local-llm/aider.model.settings.yml" "$HOME/.aider.model.settings.yml"
fi

# Seed settings.local.json from the example on first run only. Machine-local
# overrides accumulate after that and stay out of the repo.
if [[ -f "$BRAIN_DIR/claude-config/settings.local.example.json" && ! -e "$CLAUDE_DIR/settings.local.json" ]]; then
    cp "$BRAIN_DIR/claude-config/settings.local.example.json" "$CLAUDE_DIR/settings.local.json"
    echo "setup: seeded $CLAUDE_DIR/settings.local.json from example"
fi

# Build the list of personal cwds to register memory under.
# Encoding: Claude Code stores per-cwd state at ~/.claude/projects/<encoded>/
# where <encoded> is the cwd with '/' replaced by '-'.
encode_cwd() { print -r -- "${1//\//-}"; }

is_work() {
    local dir="$1"
    local w
    for w in "${WORK_PARENTS[@]}"; do
        [[ "$dir" == "$w" || "$dir" == "$w"/* ]] && return 0
    done
    return 1
}

PERSONAL_DIRS=("$HOME" "$HOME/Code")
if [[ -d "$HOME/Code" ]]; then
    for d in "$HOME/Code"/*(N/); do
        d="${d%/}"
        is_work "$d" || PERSONAL_DIRS+=("$d")
    done
fi

for dir in "${PERSONAL_DIRS[@]}"; do
    encoded="$(encode_cwd "$dir")"
    mkdir -p "$CLAUDE_DIR/projects/$encoded"
    link "$BRAIN_DIR/memory" "$CLAUDE_DIR/projects/$encoded/memory"
done

echo "setup: done."
