#!/usr/bin/env bash
# brain setup — composes ~/.claude/CLAUDE.md from CLAUDE.shared.md + machines/<host>.md
#
# Run after every git pull, or once at install time. Idempotent.
# Override the auto-detected machine with: MACHINE=<name> ./setup.sh

set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

# Auto-detect machine from hostname unless MACHINE is set.
MACHINE="${MACHINE:-$(hostname | tr '[:upper:]' '[:lower:]')}"

# Map hostnames to machine files. Add new machines here.
case "$MACHINE" in
    *elowynn*) MACHINE_FILE="machines/elowynn.md" ;;
    *polaris*) MACHINE_FILE="machines/polaris.md" ;;
    *lenovo*)  MACHINE_FILE="machines/lenovo.md"  ;;
    *hetzner*) MACHINE_FILE="machines/hetzner.md" ;;
    *)
        echo "brain: unknown machine '$MACHINE' — deploying shared-only CLAUDE.md." >&2
        echo "brain: set MACHINE=<name> or add a case in setup.sh to fix this." >&2
        MACHINE_FILE=""
        ;;
esac

if [[ -n "$MACHINE_FILE" && -f "$MACHINE_FILE" ]]; then
    { cat CLAUDE.shared.md; printf '\n---\n\n'; cat "$MACHINE_FILE"; } > CLAUDE.md
    echo "brain: composed CLAUDE.md from CLAUDE.shared.md + $MACHINE_FILE"
else
    cp CLAUDE.shared.md CLAUDE.md
    echo "brain: deployed CLAUDE.shared.md as CLAUDE.md (no machine file matched)"
fi
