#!/usr/bin/env zsh
# brain discover — dump current machine state into a markdown file.
#
# Pure-gather: no LLM calls, no commits, no edits. Just facts.
# Run on any machine, then hand the output file to Claude with
# "merge this into ~/Code/brain/machines/<hostname>.md".
#
# Usage:
#   zsh ~/Code/brain/discover.sh           # writes /tmp/brain-discover-<host>.md
#   zsh ~/Code/brain/discover.sh -         # writes to stdout

set -u

HOSTNAME_LC="$(hostname | tr '[:upper:]' '[:lower:]')"
OUT="${1:-/tmp/brain-discover-${HOSTNAME_LC}.md}"
[[ "$OUT" == "-" ]] && OUT=/dev/stdout

have() { command -v "$1" >/dev/null 2>&1; }

tool_version() {
    local tool="$1"
    if have "$tool"; then
        local v
        v=$("$tool" --version 2>&1 | head -1)
        echo "- \`$tool\`: ${v:-installed (no --version output)}"
    else
        echo "- \`$tool\`: not installed"
    fi
}

{
echo "# Discovery: $HOSTNAME_LC"
echo
echo "Generated $(date -Iseconds) by \`brain/discover.sh\`."
echo "This is raw machine state. Paste the path of this file into Claude with:"
echo "\"merge findings from $OUT into machines/${HOSTNAME_LC}.md, commit, and push.\""
echo

echo "## Identity"
echo
echo "- hostname: \`$(hostname)\`"
echo "- user: \`$USER\`"
echo "- shell: \`$SHELL\`"
echo "- uname: \`$(uname -srm)\`"
if [[ -f /etc/os-release ]]; then
    echo "- /etc/os-release:"
    echo '```'
    cat /etc/os-release
    echo '```'
fi
if grep -qi "microsoft\|wsl" /proc/version 2>/dev/null; then
    echo "- WSL: yes"
    [[ -n "${WSL_DISTRO_NAME:-}" ]] && echo "    - distro: \`$WSL_DISTRO_NAME\`"
    [[ -n "${WSL_INTEROP:-}" ]] && echo "    - WSL_INTEROP: \`$WSL_INTEROP\`"
fi

echo
echo "## Hardware"
echo
echo "### CPU"
echo '```'
if have lscpu; then
    lscpu | grep -E "^(Model name|Architecture|CPU\(s\)|Thread\(s\) per core|Core\(s\) per socket):" || lscpu | head -10
fi
echo '```'
echo
echo "### Memory"
echo '```'
have free && free -h
echo '```'
echo
echo "### GPU"
echo '```'
if have nvidia-smi; then
    nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv 2>/dev/null || echo "nvidia-smi present but query failed"
elif have lspci; then
    lspci 2>/dev/null | grep -iE "vga|3d|display" || echo "no VGA/3D devices via lspci"
else
    echo "no GPU probe available (no nvidia-smi or lspci)"
fi
echo '```'

echo
echo "## Storage"
echo
echo "### Block devices (\`lsblk\`)"
echo '```'
have lsblk && lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT
echo '```'
echo
echo "### Mount usage (\`df -h\`, real filesystems only)"
echo '```'
have df && df -h -x tmpfs -x devtmpfs -x squashfs -x overlay 2>/dev/null
echo '```'
echo
echo "### Windows-side mounts under /mnt"
if [[ -d /mnt ]]; then
    echo '```'
    ls -la /mnt/ 2>/dev/null
    echo '```'
else
    echo "_(no /mnt directory — likely not WSL)_"
fi

echo
echo "## Network"
echo
echo "### Interfaces"
echo '```'
have ip && ip -br addr
echo '```'
echo
echo "### Tailscale"
if have tailscale; then
    echo "**\`tailscale status\`:**"
    echo '```'
    tailscale status 2>&1
    echo '```'
    echo
    echo "**\`tailscale netcheck\` (NAT/relay diagnostics):**"
    echo '```'
    tailscale netcheck 2>&1 | head -25
    echo '```'
else
    echo "_(tailscale not installed)_"
fi

echo
echo "## Dev tooling"
echo
for tool in git zsh bash docker node npm pnpm bun python3 gh tailscale claude ssh curl jq rg fzf make; do
    tool_version "$tool"
done

echo
echo "### git config (global)"
echo '```'
have git && git config --global -l 2>/dev/null
echo '```'

echo
echo "## Folders in ~/Code/"
echo
if [[ -d "$HOME/Code" ]]; then
    echo '```'
    ls -1 "$HOME/Code" 2>/dev/null
    echo '```'
    echo
    echo "### Sizes"
    echo '```'
    du -sh "$HOME/Code"/* 2>/dev/null | sort -h | tail -20
    echo '```'
else
    echo "_(no ~/Code/ directory)_"
fi

echo
echo "## Claude Code state"
echo
tool_version claude
if [[ -d "$HOME/.claude" ]]; then
    echo
    echo "### ~/.claude/ contents"
    echo '```'
    ls -la "$HOME/.claude" 2>/dev/null
    echo '```'
    echo
    if [[ -L "$HOME/.claude/settings.json" ]]; then
        echo "- \`settings.json\`: symlink → \`$(readlink "$HOME/.claude/settings.json")\`"
    fi
    if [[ -L "$HOME/.claude/projects/-home-jo/memory" ]]; then
        echo "- memory: symlink → \`$(readlink "$HOME/.claude/projects/-home-jo/memory")\`"
    fi
    if [[ -f "$HOME/.claude/CLAUDE.md" ]]; then
        local_md_lines=$(wc -l < "$HOME/.claude/CLAUDE.md")
        echo "- \`CLAUDE.md\`: ${local_md_lines} lines (composed)"
    fi
fi

echo
echo "---"
echo "_End of discovery for $HOSTNAME_LC._"
} > "$OUT"

if [[ "$OUT" != /dev/stdout ]]; then
    echo "discover: wrote $OUT ($(wc -l < "$OUT") lines)"
    echo "discover: hand to Claude with — \"merge findings from $OUT into machines/${HOSTNAME_LC}.md, commit, push\""
fi
