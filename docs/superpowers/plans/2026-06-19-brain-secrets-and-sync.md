# Brain Secrets and Cross-Machine Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give the brain repo encrypted personal secrets and a clear manual sync model across polaris, elowynn, and legato.

**Architecture:** Personal tokens are encrypted with `sops`+`age` and committed to the brain repo as ciphertext; each machine holds one local `age` key that decrypts them. Skills join commands/agents as symlinked cargo. Sync stays manual (`brain-sync` / `brain-push`) with an offline staleness line on shell startup.

**Tech Stack:** zsh, git, `sops`, `age`, oh-my-zsh. No service, no daemon.

## Global Constraints

- Shell scripts use `#!/usr/bin/env zsh` and are invoked as `zsh script.sh`.
- No em dashes or standard dashes in copy-ready artifacts: commit messages, shell snippets, anything pasted verbatim. Use periods, semicolons, parentheses.
- `age` private keys live at `~/.config/sops/age/keys.txt`, are machine-local, and are NEVER committed.
- SSH private keys are never synced. Only public keys are recorded, and only for the `hexagonstorms` identity.
- automatiq is never touched: no `.sops.yaml` there, no work tokens in the brain.
- Plaintext secrets are never written to disk; they are injected into the environment at runtime.
- The brain repo root is `~/Code/brain`. Work happens on a branch, not on the default branch directly.

---

### Task 1: Install sops and age on this machine

**Files:**
- None committed. Tooling install only.

**Interfaces:**
- Produces: `sops` and `age`/`age-keygen` on PATH for every later task.

- [ ] **Step 1: Check whether the tools are already present**

Run: `command -v sops age age-keygen`
Expected: one or more print nothing (missing) on a fresh machine.

- [ ] **Step 2: Install both**

```zsh
sudo apt-get update && sudo apt-get install -y age
ARCH="$(dpkg --print-architecture)"
SOPS_VER="3.9.4"
curl -fsSL -o /tmp/sops "https://github.com/getsops/sops/releases/download/v${SOPS_VER}/sops-v${SOPS_VER}.linux.${ARCH}"
sudo install -m 0755 /tmp/sops /usr/local/bin/sops
```

- [ ] **Step 3: Verify versions**

Run: `sops --version && age --version`
Expected: `sops 3.9.4` (or newer) and an `age` version string, both non-empty.

- [ ] **Step 4: No commit**

Tooling is machine state, not repo state. Nothing to commit. Record the install commands in `machines/<host>.md` dev-tooling table in a later task.

---

### Task 2: Generate this machine's age key and capture its public key

**Files:**
- Create: `~/.config/sops/age/keys.txt` (machine-local, NOT in repo)

**Interfaces:**
- Produces: this machine's `age` public key string (`age1...`), consumed by Tasks 3 and 5.

- [ ] **Step 1: Confirm no key exists yet**

Run: `test -f ~/.config/sops/age/keys.txt && echo EXISTS || echo MISSING`
Expected: `MISSING` on a fresh machine. If `EXISTS`, skip to Step 3.

- [ ] **Step 2: Generate the keypair**

```zsh
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
```

- [ ] **Step 3: Print the public key**

Run: `age-keygen -y ~/.config/sops/age/keys.txt`
Expected: a single `age1...` line. Copy it; Tasks 3 and 5 need it.

- [ ] **Step 4: No commit**

The private key is never committed. The public key is recorded in Tasks 3 and 5.

---

### Task 3: Create the .sops.yaml recipient policy

**Files:**
- Create: `~/Code/brain/.sops.yaml`

**Interfaces:**
- Consumes: this machine's `age` public key from Task 2.
- Produces: a `creation_rules` policy that Task 4 relies on to encrypt `secrets/*.env`.

- [ ] **Step 1: Write the recipient policy**

Replace `age1ELOWYNN...` with the actual public key from Task 2. Other machines' keys are added as each one bootstraps (Task 11).

```yaml
# Encrypts secrets/*.env to every listed machine. Public keys only.
creation_rules:
  - path_regex: secrets/.*\.env$
    age: >-
      age1ELOWYNN...
```

- [ ] **Step 2: Verify sops parses it**

Run: `cd ~/Code/brain && sops --version >/dev/null && echo ok`
Expected: `ok` (sops reads `.sops.yaml` from cwd on the next encrypt; nothing to validate standalone yet).

- [ ] **Step 3: Commit**

```zsh
cd ~/Code/brain
git add .sops.yaml
git commit -m "Add sops recipient policy for personal secrets"
```

---

### Task 4: Create and round-trip the shared secrets file

**Files:**
- Create: `~/Code/brain/secrets/shared.env` (encrypted at rest)

**Interfaces:**
- Consumes: `.sops.yaml` from Task 3, the local `age` key from Task 2.
- Produces: `secrets/shared.env` decryptable via `sops decrypt`, consumed by Task 9.

- [ ] **Step 1: Verify decryption fails before the file exists**

Run: `cd ~/Code/brain && sops decrypt secrets/shared.env 2>&1 || echo FAILED_AS_EXPECTED`
Expected: `FAILED_AS_EXPECTED` (no such file).

- [ ] **Step 2: Create the file with one real token, encrypted in place**

`sops` picks dotenv format from the `.env` extension and encrypts values only.

```zsh
cd ~/Code/brain
mkdir -p secrets
printf 'ANTHROPIC_API_KEY=replace-me\n' > secrets/shared.env
sops encrypt --in-place secrets/shared.env
```

- [ ] **Step 3: Verify the file is ciphertext, keys still readable**

Run: `grep -c 'ENC\[' ~/Code/brain/secrets/shared.env`
Expected: `1` or more (the value is encrypted; the `ANTHROPIC_API_KEY` name stays visible).

- [ ] **Step 4: Verify the round-trip decrypts**

Run: `cd ~/Code/brain && sops decrypt secrets/shared.env`
Expected: `ANTHROPIC_API_KEY=replace-me` in plaintext.

- [ ] **Step 5: Commit**

```zsh
cd ~/Code/brain
git add secrets/shared.env
git commit -m "Add encrypted shared secrets file"
```

---

### Task 5: Create the public-key SSH registry

**Files:**
- Create: `~/Code/brain/ssh/<host>.yaml` for this machine (e.g. `ssh/elowynn.yaml`)

**Interfaces:**
- Consumes: this machine's SSH public key and `age` public key.
- Produces: an inventory file; no code depends on it yet (future GitHub-push automation).

- [ ] **Step 1: Gather the public keys**

Run: `cat ~/.ssh/id_ed25519.pub 2>/dev/null; age-keygen -y ~/.config/sops/age/keys.txt`
Expected: the SSH pubkey line (if present) and the `age1...` line.

- [ ] **Step 2: Write the registry file**

Personal identity only. Omit any `joshplaza` key by design.

```yaml
# Public keys for this machine. hexagonstorms identity only.
host: elowynn
hexagonstorms:
  ssh: ssh-ed25519 AAAA... jo@elowynn
  age: age1ELOWYNN...
```

- [ ] **Step 3: Verify it is valid YAML**

Run: `cd ~/Code/brain && sops --version >/dev/null && python3 -c "import yaml,sys; yaml.safe_load(open('ssh/elowynn.yaml'))" && echo VALID`
Expected: `VALID`.

- [ ] **Step 4: Commit**

```zsh
cd ~/Code/brain
git add ssh/elowynn.yaml
git commit -m "Add public key registry for elowynn"
```

---

### Task 6: Add legato machine file and setup.sh case; retire lenovo

**Files:**
- Create: `~/Code/brain/machines/legato.md`
- Modify: `~/Code/brain/setup.sh` (machine case block)
- Delete: `~/Code/brain/machines/lenovo.md`

**Interfaces:**
- Consumes: nothing.
- Produces: a `*legato*` host mapping so `setup.sh` composes the right `CLAUDE.md` on legato.

- [ ] **Step 1: Write the legato machine file**

```markdown
# legato

Personal workstation. Successor to lenovo. Carries both identities:
hexagonstorms (personal) and joshplaza (automatiq work, via Doppler).

- OS: TBD at bootstrap
- Identities: hexagonstorms + joshplaza
- Secrets: brain sops for personal; Doppler for automatiq
```

- [ ] **Step 2: Verify setup.sh does not yet match legato**

Run: `MACHINE=legato zsh -c 'source ~/Code/brain/setup.sh' 2>&1 | grep -i "no machine file matched" && echo UNMATCHED`
Expected: `UNMATCHED` (the case is missing). If this errors due to `set -e`, instead grep the file: `grep -c legato ~/Code/brain/setup.sh` expecting `0`.

- [ ] **Step 3: Add the legato case**

In `setup.sh`, in the `case "$MACHINE"` block, add alongside the existing cases:

```zsh
    *legato*)  MACHINE_FILE="$BRAIN_DIR/machines/legato.md" ;;
```

Remove the `*lenovo*` and `*public*` lines that point at the retired `lenovo.md`.

- [ ] **Step 4: Delete the retired file**

```zsh
git -C ~/Code/brain rm machines/lenovo.md
```

- [ ] **Step 5: Verify the legato case resolves**

Run: `grep -c 'machines/legato.md' ~/Code/brain/setup.sh`
Expected: `1`.

- [ ] **Step 6: Commit**

```zsh
cd ~/Code/brain
git add setup.sh machines/legato.md
git commit -m "Add legato machine file and setup case; retire lenovo"
```

---

### Task 7: Add skills sharing and age-key check to setup.sh

**Files:**
- Modify: `~/Code/brain/setup.sh` (skills link + age check)
- Create: `~/Code/brain/claude-config/skills/.gitkeep`

**Interfaces:**
- Consumes: the `link()` helper already defined in setup.sh.
- Produces: `~/.claude/skills` symlink; a bootstrap warning when the `age` key is absent.

- [ ] **Step 1: Create the skills directory placeholder**

```zsh
mkdir -p ~/Code/brain/claude-config/skills
touch ~/Code/brain/claude-config/skills/.gitkeep
```

- [ ] **Step 2: Add the skills symlink next to the commands/agents links**

In `setup.sh`, after the `agents` link block, add:

```zsh
if [[ -d "$BRAIN_DIR/claude-config/skills" ]]; then
    link "$BRAIN_DIR/claude-config/skills" "$CLAUDE_DIR/skills"
fi
```

- [ ] **Step 3: Add the age-key check near the end of setup.sh**

```zsh
if [[ ! -f "$HOME/.config/sops/age/keys.txt" ]]; then
    echo "setup: no age key at ~/.config/sops/age/keys.txt."
    echo "setup: run 'age-keygen -o ~/.config/sops/age/keys.txt' then add its public key to .sops.yaml on another machine and 'sops updatekeys secrets/*.env'."
fi
```

- [ ] **Step 4: Run setup.sh and verify the skills link is created**

Run: `zsh ~/Code/brain/setup.sh >/dev/null && readlink ~/.claude/skills`
Expected: `/home/jo/Code/brain/claude-config/skills`.

- [ ] **Step 5: Commit**

```zsh
cd ~/Code/brain
git add setup.sh claude-config/skills/.gitkeep
git commit -m "Share skills via brain and warn when age key is missing"
```

---

### Task 8: Add brain-sync, brain-push, and the staleness guard

**Files:**
- Create: `~/Code/brain/claude-config/brain.zsh`
- Modify: `~/Code/brain/setup.sh` (ensure `.zshrc` sources brain.zsh)

**Interfaces:**
- Consumes: the brain repo path.
- Produces: `brain-sync`, `brain-push` functions, a staleness marker at `~/.cache/brain/last-sync`, and a startup line.

- [ ] **Step 1: Write brain.zsh**

```zsh
#!/usr/bin/env zsh
# brain sync helpers. Sourced from ~/.zshrc.

BRAIN_DIR="$HOME/Code/brain"
BRAIN_MARKER="$HOME/.cache/brain/last-sync"

brain-sync() {
    git -C "$BRAIN_DIR" pull --ff-only || return 1
    zsh "$BRAIN_DIR/setup.sh"
    mkdir -p "${BRAIN_MARKER:h}"
    date +%s > "$BRAIN_MARKER"
    echo "brain: synced just now."
}

brain-push() {
    git -C "$BRAIN_DIR" add -A
    git -C "$BRAIN_DIR" commit -m "${1:-brain update}" || return 0
    git -C "$BRAIN_DIR" push
}

_brain_staleness() {
    [[ -f "$BRAIN_MARKER" ]] || { echo "brain: never synced on this machine, run brain-sync."; return; }
    local last now days
    last="$(cat "$BRAIN_MARKER")"
    now="$(date +%s)"
    days=$(( (now - last) / 86400 ))
    (( days >= 2 )) && echo "brain: last synced ${days} days ago, run brain-sync."
}
_brain_staleness
```

- [ ] **Step 2: Add a source-line installer to setup.sh**

In `setup.sh`, after the local-llm block, add an idempotent guard:

```zsh
SOURCE_LINE='[[ -f "$HOME/Code/brain/claude-config/brain.zsh" ]] && source "$HOME/Code/brain/claude-config/brain.zsh"'
if ! grep -qF 'claude-config/brain.zsh' "$HOME/.zshrc" 2>/dev/null; then
    print -r -- "$SOURCE_LINE" >> "$HOME/.zshrc"
    echo "setup: added brain.zsh source line to ~/.zshrc"
fi
```

- [ ] **Step 3: Verify the staleness guard prints when there is no marker**

Run: `rm -f ~/.cache/brain/last-sync && zsh -c 'source ~/Code/brain/claude-config/brain.zsh'`
Expected: `brain: never synced on this machine, run brain-sync.`

- [ ] **Step 4: Verify brain-sync writes the marker and silences the nudge**

Run: `zsh -ic 'brain-sync >/dev/null; source ~/Code/brain/claude-config/brain.zsh'`
Expected: no staleness line (synced moments ago, under 2 days).

- [ ] **Step 5: Commit**

```zsh
cd ~/Code/brain
git add claude-config/brain.zsh setup.sh
git commit -m "Add manual brain-sync and brain-push with staleness nudge"
```

---

### Task 9: Add a runtime secrets-injection wrapper

**Files:**
- Modify: `~/Code/brain/claude-config/brain.zsh` (add `brain-run`)

**Interfaces:**
- Consumes: `secrets/shared.env` (Task 4), the local `age` key (Task 2).
- Produces: `brain-run <cmd>` that injects decrypted tokens into the environment for one command, never to disk.

- [ ] **Step 1: Verify no injection helper exists yet**

Run: `grep -c 'brain-run' ~/Code/brain/claude-config/brain.zsh`
Expected: `0`.

- [ ] **Step 2: Add the wrapper to brain.zsh**

```zsh
brain-run() {
    sops exec-env "$BRAIN_DIR/secrets/shared.env" "${(j: :)@}"
}
```

- [ ] **Step 3: Verify it injects the token into the child environment**

Run: `zsh -c 'source ~/Code/brain/claude-config/brain.zsh; brain-run "printenv ANTHROPIC_API_KEY"'`
Expected: the decrypted value (`replace-me` until you set a real token), proving injection works without writing plaintext to disk.

- [ ] **Step 4: Commit**

```zsh
cd ~/Code/brain
git add claude-config/brain.zsh
git commit -m "Add brain-run to inject secrets at runtime"
```

---

### Task 10: Add a full-disk-encryption check to setup.sh

**Files:**
- Modify: `~/Code/brain/setup.sh` (FDE warning)

**Interfaces:**
- Consumes: nothing.
- Produces: a startup warning when the root disk is not LUKS-encrypted, since the `age` key rests on it.

- [ ] **Step 1: Verify there is no FDE check yet**

Run: `grep -c -i luks ~/Code/brain/setup.sh`
Expected: `0`.

- [ ] **Step 2: Add the check near the age-key check**

```zsh
if ! lsblk -o TYPE 2>/dev/null | grep -q crypt; then
    echo "setup: WARNING no LUKS-encrypted volume detected. The age key rests on this disk; enable full-disk encryption before trusting secrets here."
fi
```

- [ ] **Step 3: Run setup.sh and confirm it completes**

Run: `zsh ~/Code/brain/setup.sh >/dev/null 2>&1 && echo OK`
Expected: `OK` (the warning prints to the visible run; this check confirms no fatal error).

- [ ] **Step 4: Commit**

```zsh
cd ~/Code/brain
git add setup.sh
git commit -m "Warn when root disk is not encrypted"
```

---

### Task 11: Document the model and the new-machine bootstrap

**Files:**
- Modify: `~/Code/brain/README.md`

**Interfaces:**
- Consumes: all prior tasks.
- Produces: operator documentation for sync commands and onboarding legato.

- [ ] **Step 1: Verify the README does not yet mention sops**

Run: `grep -c -i sops ~/Code/brain/README.md`
Expected: `0`.

- [ ] **Step 2: Add a Secrets and Sync section to README.md**

```markdown
## Secrets and sync

Personal tokens are encrypted with sops+age and committed to this repo. Each
machine holds one age key at ~/.config/sops/age/keys.txt (never committed).

Daily use:
- brain-sync   pull latest and re-run setup.sh
- brain-push   commit and push your changes
- brain-run    run a command with secrets injected, e.g. brain-run claude

The shell prints a reminder when you have not synced in two or more days.

Onboard a new machine:
1. git clone the brain repo to ~/Code/brain
2. age-keygen -o ~/.config/sops/age/keys.txt
3. on an existing machine, add the new public key to .sops.yaml and run
   sops updatekeys secrets/*.env, then brain-push
4. generate an SSH key, add its pubkey to GitHub and to ssh/<host>.yaml
5. zsh ~/Code/brain/setup.sh
```

- [ ] **Step 3: Verify the section landed**

Run: `grep -c -i 'brain-run' ~/Code/brain/README.md`
Expected: `1` or more.

- [ ] **Step 4: Commit**

```zsh
cd ~/Code/brain
git add README.md
git commit -m "Document secrets and sync model"
```

---

## Self-Review

**Spec coverage:**
- sops+age secrets: Tasks 2, 3, 4. Covered.
- `.sops.yaml` recipient model: Task 3. Covered.
- ssh pubkey registry (personal only): Task 5. Covered.
- Runtime injection (no plaintext at rest): Task 9. Covered.
- Skills sharing: Task 7. Covered.
- Manual sync + staleness nudge (offline): Task 8. Covered.
- legato machine file + setup case, retire lenovo: Task 6. Covered.
- FDE backstop check: Task 10. Covered.
- Bootstrap + operator docs: Task 11. Covered.
- Non-goals (no hooks, no transcript sync, no work secrets): honored; nothing in the plan adds them.

**Naming consistency:** marker path `~/.cache/brain/last-sync` and `BRAIN_MARKER` match across Task 8. `brain-sync` / `brain-push` / `brain-run` consistent across Tasks 8, 9, 11. Secrets file is `secrets/shared.env` everywhere (note: named `.env`, not `.env.sops`, so sops detects dotenv format; this refines the spec's `shared.env.sops` label).

**Placeholders:** the `legato.md` OS field is genuinely unknown until bootstrap and marked TBD intentionally; `replace-me` token value is a deliberate placeholder the operator overwrites with `sops edit`. No code-step placeholders.
