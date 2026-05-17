# brain

Jo's portable context layer for [Claude Code](https://docs.claude.com/en/docs/claude-code/overview). One git repo, synced across every machine he works on, so the assistant behaves coherently no matter where it's invoked.

## Why

`~/.claude/` is machine-local. That's the right default — credentials, transcripts, plugin caches, and shell snapshots shouldn't follow you between hosts. But a few things *should*:

- How the assistant is told to behave (`CLAUDE.md`)
- Per-host facts it should know (hardware, mounts, networking, what's a laptop vs a lab server)
- Persistent memory about Jo and his projects
- Claude Code settings

This repo holds those, and `setup.sh` wires them into `~/.claude/` on each machine. New machine = clone + run setup. No drift.

## Layout

```
CLAUDE.shared.md      universal instructions — composed into every host's CLAUDE.md
machines/<host>.md    per-machine context, appended after the shared file
memory/               persistent memory (user profile, feedback, project facts)
settings.json         Claude Code settings, symlinked into ~/.claude/
setup.sh              wires this repo into ~/.claude/
discover.sh           dumps current machine state to /tmp for merging into machines/
```

Machine-local files (plugins, sessions, credentials, history) stay in `~/.claude/` and never move into this repo.

## Bootstrap on a new machine

```sh
git clone git@github.com:HexagonStorms/brain.git ~/Code/brain
zsh ~/Code/brain/setup.sh
```

`setup.sh` is idempotent. It:

1. Composes `~/.claude/CLAUDE.md` from `CLAUDE.shared.md` + `machines/<host>.md`.
2. Symlinks `~/.claude/settings.json` → `~/Code/brain/settings.json`.
3. Symlinks `~/.claude/projects/-home-jo/memory/` → `~/Code/brain/memory/`.

If a real file already sits at one of the symlink targets, it's moved aside with a timestamped `.machine-backup-*` suffix rather than overwritten.

## Adding a new machine

Hostname-to-file mapping lives in `setup.sh` (`case "$MACHINE" in …`). To add a host:

1. On the new machine, run `zsh ~/Code/brain/discover.sh`. It writes `/tmp/brain-discover-<host>.md` with hardware, mounts, network, dev tooling, and Claude Code state. No LLM calls — pure fact-gathering.
2. Hand the output path to Claude with: *"merge findings from /tmp/brain-discover-&lt;host&gt;.md into machines/&lt;host&gt;.md, commit, push."*
3. If the brain name differs from the hostname (e.g. hostname `public`, brain name `lenovo`), add a matching `*<hostname>*) MACHINE_FILE=…` case in `setup.sh`.
4. Re-run `setup.sh` and the new host's CLAUDE.md picks up its machine file.

## Goal

One source of truth for how the assistant works with Jo, durable across machines and time. Tend, don't churn.
