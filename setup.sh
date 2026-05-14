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

mkdir -p "$CLAUDE_DIR" "$CLAUDE_DIR/projects/-home-jo"

# --- compose CLAUDE.md ---

MACHINE="${MACHINE:-$(hostname | tr '[:upper:]' '[:lower:]')}"
case "$MACHINE" in
    *elowynn*) MACHINE_FILE="$BRAIN_DIR/machines/elowynn.md" ;;
    *polaris*) MACHINE_FILE="$BRAIN_DIR/machines/polaris.md" ;;
    *lenovo*)  MACHINE_FILE="$BRAIN_DIR/machines/lenovo.md"  ;;
    *hetzner*) MACHINE_FILE="$BRAIN_DIR/machines/hetzner.md" ;;
    *)         MACHINE_FILE="" ;;
esac

if [[ -n "$MACHINE_FILE" && -f "$MACHINE_FILE" ]]; then
    { cat "$BRAIN_DIR/CLAUDE.shared.md"; printf '\n---\n\n'; cat "$MACHINE_FILE"; } > "$CLAUDE_DIR/CLAUDE.md"
    echo "setup: composed $CLAUDE_DIR/CLAUDE.md from CLAUDE.shared.md + machines/${MACHINE_FILE##*/}"
else
    cp "$BRAIN_DIR/CLAUDE.shared.md" "$CLAUDE_DIR/CLAUDE.md"
    echo "setup: unknown machine '$MACHINE' — deployed shared-only CLAUDE.md."
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
link "$BRAIN_DIR/memory"        "$CLAUDE_DIR/projects/-home-jo/memory"

echo "setup: done."
