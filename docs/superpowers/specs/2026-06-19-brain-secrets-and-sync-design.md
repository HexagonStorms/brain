# Brain Secrets and Cross-Machine Sync — Design

> Date: 2026-06-19
> Status: Approved, pre-implementation
> Scope: personal-scope secrets + multi-machine sync for the brain repo

## Problem

Jo works across three personal machines (polaris, elowynn, legato) and wants to
start Claude work on one and continue on another with the same context, memory,
config, skills, and the personal API tokens that work depends on. Today the brain
repo already syncs `CLAUDE.md`, `memory/`, `settings.json`, `commands/`, and
`agents/` by git. The gap is **secrets** (API tokens, project `.env` values) and
**skills**, plus a clear story for *when* a machine is in or out of sync.

## Goals

1. Personal tokens (Anthropic key, any personal PATs, project `.env` values)
   available on all three machines, committed safely to the GitHub-hosted brain
   repo.
2. Skills travel with the brain, the same way commands and agents already do.
3. A clear, low-effort sync model: explicit manual sync, with the terminal
   stating plainly when a machine is stale.
4. Identity stays separated: elowynn is always `hexagonstorms` only; work
   (`joshplaza` / automatiq) never enters the brain.

## Non-goals (YAGNI)

- **No automatic hooks** (no login-pull, no Stop-push). Manual first; revisit once
  real habits are known.
- **No transcript sync.** Raw chat logs stay machine-local. Cross-machine
  conversation *resume* is explicitly out of scope.
- **No work secrets.** automatiq uses Doppler and is untouched. No `.sops.yaml`
  in automatiq, no work tokens in the brain.
- **No secrets service.** No Infisical, no Doppler for personal scope. Git-native
  encryption only.
- **No SSH private-key sync.** Keys are per-machine; new machines generate their
  own.

## Architecture

Secrets are encrypted with `sops` + `age` and committed to the brain repo as
ciphertext. Each machine holds one `age` private key locally; it decrypts the
shared secrets file. Sync is `git pull` (the brain's existing mechanism); a
staleness line on shell startup reports how long since the last sync.

### Components

**1. age keys (per machine, never synced)**
- Each machine generates one `age` keypair at `~/.config/sops/age/keys.txt`.
- The private key never leaves the machine and is never committed.
- The public key is recorded in the brain (see registry) and listed as a
  recipient in `.sops.yaml`.

**2. `.sops.yaml` (recipient policy, in the brain)**
- A single `creation_rules` block listing the three machines' `age` *public*
  keys as recipients for `secrets/*`.
- Anything in `secrets/` is encrypted to all three; any of the three can decrypt.

**3. `secrets/` (encrypted blobs, in the brain)**
- `secrets/shared.env.sops` — tokens common to all machines.
- Optional `secrets/<machine>.env.sops` later if a machine needs private extras.
  Not built up front.
- `sops` encrypts *values only*; keys stay readable, so the file is diffable in
  `git log` without exposing plaintext.

**4. `ssh/` registry (PUBLIC keys only, in the brain)**
- One file per machine recording that machine's **public** keys, keyed by
  identity. Personal (`hexagonstorms`) pubkeys only; work (`joshplaza`) pubkeys
  are deliberately omitted to keep the brain work-free.
- Purpose: inventory + a future hook for pushing pubkeys to the right GitHub
  account. Not an access mechanism (machine-to-machine SSH runs on Tailscale).

**5. Secrets injection (at runtime, not at rest)**
- Plaintext is never written to disk. Tokens are injected into the environment at
  point of use via `sops`, e.g. `sops exec-env secrets/shared.env.sops '<cmd>'`
  or a small wrapper / `direnv` integration.
- Editing a secret: `sops edit secrets/shared.env.sops`, save, `brain-push`.

**6. Skills sharing**
- `claude-config/skills/` in the brain, symlinked to `~/.claude/skills/` by
  `setup.sh`, identical to how `commands/` and `agents/` are handled.

**7. Sync model (manual + staleness nudge)**
- `brain-sync`: `git -C ~/Code/brain pull` then `zsh ~/Code/brain/setup.sh`.
- `brain-push`: commit + push memory/config/secrets changes.
- On shell startup, a guard prints one line only when stale, e.g.
  `brain: last synced 4 days ago, run brain-sync`. When fresh it is quiet or
  prints a brief `brain: synced today`.
- Staleness is computed **offline** from a timestamp marker written by
  `brain-sync` (time since last pull). No `git fetch` on startup; no network
  dependency, no hang risk. "N commits behind" is explicitly deferred.

## Brain layout (target)

```
brain/
  .sops.yaml                 # recipient list for secrets/*
  secrets/
    shared.env.sops          # personal tokens, encrypted to all 3 machines
  ssh/
    polaris.yaml             # public keys, hexagonstorms identity
    elowynn.yaml
    legato.yaml
  machines/
    elowynn.md  polaris.md  legato.md   # legato added; lenovo retired
  memory/                    # unchanged
  claude-config/
    commands/  agents/  skills/          # skills/ added
    settings.local.example.json
  CLAUDE.shared.md  about-jo.md
  settings.json  setup.sh  discover.sh
```

Not in the brain, ever: `age` private keys, SSH private keys, automatiq secrets.

## setup.sh changes

1. **skills symlink** — link `claude-config/skills/` to `~/.claude/skills/`,
   mirroring the existing commands/agents links. No-op if the dir is absent.
2. **age key check** — if `~/.config/sops/age/keys.txt` is missing, print a clear
   bootstrap instruction and do not silently generate one.
3. **machine case for legato** — add a `*legato*` case mapping to
   `machines/legato.md`.
4. **staleness marker** — `brain-sync` writes the marker; the shell guard reads
   it. (The guard itself is wired in zsh startup, not setup.sh, but setup.sh may
   install the marker path.)

## Bootstrapping a new machine (e.g. legato)

1. `git clone` the brain repo to `~/Code/brain`.
2. Generate an `age` keypair: `age-keygen -o ~/.config/sops/age/keys.txt`.
3. Add the new machine's `age` public key to `.sops.yaml` recipients and to
   `ssh/<machine>.yaml`, then `sops updatekeys secrets/*.sops` to re-encrypt so
   the new machine can decrypt. Commit and push from an existing machine.
4. Generate the machine's SSH keypair; add its pubkey to the relevant GitHub
   account; record the pubkey in `ssh/<machine>.yaml`.
5. `zsh ~/Code/brain/setup.sh`.

Steps 2 and 4 are the only manual secret-bootstrap moments. Everything after is
`brain-sync` / `brain-push`.

## Security model

- The encrypted blob in GitHub is inert without an `age` private key. The crown
  jewels live on the machines, not in the repo.
- Blast radius is per-machine and revocable: lose a machine, drop its pubkey from
  `.sops.yaml`, `sops updatekeys` to re-encrypt, rotate the tokens.
- The real backstop is **full-disk encryption** on each machine: an `age` key on
  an unencrypted disk is the soft spot. The setup should check FDE status and
  flag any machine that lacks it before the secrets story is leaned on.

## Out of scope / future

- Automatic sync hooks (login-pull, Stop-push memory).
- `git fetch`-based "N commits behind" staleness.
- Cross-machine conversation resume (transcript handling).
- Other agents (antigravity, etc.) sharing skills/config.
- One-click work-identity (automatiq) toggle on/off.

## Open items

- Confirm `direnv` vs a thin wrapper for runtime injection during implementation.
- Confirm which personal tokens travel (inventory step in the plan).
- Decide where the staleness guard hooks into zsh startup (`.zshrc` vs an
  oh-my-zsh snippet).
