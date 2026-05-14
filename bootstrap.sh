#!/usr/bin/env zsh
# brain bootstrap — onboard a new machine.
#
# Run from a fresh clone of the brain repo. Handles an existing ~/.claude/
# by moving it aside, preserves machine-local config (plugins, local settings,
# CLI history), swaps the clone into place, and composes CLAUDE.md.
#
# Usage on a new machine:
#   git clone git@github.com:HexagonStorms/brain.git ~/brain-clone
#   bash ~/brain-clone/bootstrap.sh
#
# Safe to re-run: each invocation creates a new timestamped backup.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="${HOME}/.claude"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="${TARGET}.backup-${TIMESTAMP}"

# Sanity check: are we actually inside a brain clone?
if [[ ! -f "$REPO_DIR/CLAUDE.shared.md" || ! -d "$REPO_DIR/machines" ]]; then
    echo "bootstrap: this doesn't look like a brain clone — no CLAUDE.shared.md or machines/" >&2
    echo "bootstrap: REPO_DIR=$REPO_DIR" >&2
    exit 1
fi

# Already installed? Don't double-bootstrap.
if [[ "$REPO_DIR" == "$TARGET" ]]; then
    echo "bootstrap: already installed at $TARGET — run ./setup.sh to refresh, not bootstrap.sh" >&2
    exit 1
fi

echo "bootstrap: installing brain into $TARGET"

# Move any existing ~/.claude/ aside.
HAD_BACKUP=""
if [[ -e "$TARGET" ]]; then
    echo "bootstrap: existing $TARGET found — moving to $BACKUP"
    mv "$TARGET" "$BACKUP"
    HAD_BACKUP="yes"
fi

# Swap the clone into place.
mv "$REPO_DIR" "$TARGET"
cd "$TARGET"

# Restore machine-local files the repo doesn't carry.
PRESERVED=()
if [[ -n "$HAD_BACKUP" ]]; then
    if [[ -d "$BACKUP/plugins" ]]; then
        cp -R "$BACKUP/plugins" "$TARGET/plugins"
        PRESERVED+=("plugins/")
    fi
    if [[ -f "$BACKUP/settings.local.json" ]]; then
        cp "$BACKUP/settings.local.json" "$TARGET/settings.local.json"
        PRESERVED+=("settings.local.json")
    fi
    if [[ -f "$BACKUP/history.jsonl" ]]; then
        cp "$BACKUP/history.jsonl" "$TARGET/history.jsonl"
        PRESERVED+=("history.jsonl")
    fi
fi

# Compose CLAUDE.md for this machine.
zsh "$TARGET/setup.sh"

echo ""
echo "bootstrap: complete."
if (( ${#PRESERVED[@]} > 0 )); then
    echo "bootstrap: preserved from previous install — ${PRESERVED[*]}"
fi
if [[ -n "$HAD_BACKUP" ]]; then
    echo "bootstrap: previous ~/.claude/ saved at:"
    echo "           $BACKUP"
    echo "           Safe to delete once the brain is verified working."
fi
