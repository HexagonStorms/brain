---
name: project_automatiq_1password_signing
description: 1Password SSH commit signing for Automatiq work on legato (WSL2) — WORKING as of 2026-08-04; npiperelay+socat bridge required
metadata:
  type: project
---

Goal: set up the Automatiq 1Password SSH agent on **legato** (the WSL2 laptop — formerly called "Lenovo", hostname formerly `public`; see `machines/legato.md`) so git commits in `~/Code/automatiq/` are signed with an SSH key stored in the Automatiq 1Password account.

**Why:** Automatiq requires signed commits; 1Password is the org's approved key store.

**Status as of 2026-08-04: ✅ WORKING.** A test commit in `~/Code/automatiq/automatiq-iq` produced
`Good "git" signature for josh.plaza@automatiq.com with ED25519 key SHA256:XukZHWAOP1DYe0NQAvt1oIQHX0lk5DJbR8PAGsMqNH8`.

Final shape on legato:

- 1Password for Windows v8.12.30.21, installed via winget as an **MSIX/Store package** — there is no `C:\Program Files\1Password`; the exe alias is `C:\Users\plaza\AppData\Local\Microsoft\WindowsApps\1Password.exe`. Verify with `winget list --exact --id AgileBits.1Password`, not by looking in Program Files.
- Agent bridged into WSL by `~/.local/bin/op-ssh-agent-relay` (npiperelay + socat), called from `~/.zshrc`.
- Signing config in `~/.gitconfig-automatiq`, reached by `[includeIf "gitdir:~/Code/automatiq/"]` — scoped so personal repos never sign.
- `~/.config/git/allowed_signers` maps `josh.plaza@automatiq.com` to the key.

**Nothing needed adding to GitHub.** The 1Password key was *already* registered on joshplaza as the signing key titled "Polaris - 1Password Signing" — it's the same vault-stored key Polaris uses, and 1Password syncs it. Check before assuming: `gh api /user/ssh_signing_keys`.

**Auth and signing use different keys on purpose:**
- auth → `~/.ssh/id_ed25519` (`...IBTsKHUc...`), via the `github-automatiq` Host alias, registered as "Lenovo ThinkPad X1 Extreme 4i"
- signing → 1Password key (`...IBI7NUIM...`), never touches `~/.ssh/config`

Keeping them separate means pushing still works when 1Password is closed. Don't "simplify" by pointing `github-automatiq` at `IdentityAgent`.

**Operational caveat:** `commit.gpgsign = true` fails closed. If the Windows 1Password app isn't running, commits *in Automatiq repos only* will fail. Start 1Password, or `git -c commit.gpgsign=false commit` to bypass once.

**How to apply:** run `~/.local/bin/op-ssh-agent-relay`. Exit 0 → agent live, signing should just work. Exit 1 "no agent behind the pipe" → 1Password isn't running or the Developer → "Use the SSH agent" toggle is off.

---

## Setup steps (WSL2-specific)

1. **Windows side — 1Password installed and signed in to the Automatiq account.** ✅ installed / ⏳ sign-in pending.

2. **Enable the SSH agent in 1Password.**
   Settings → Developer → **"Use the SSH agent"**. This creates the Windows named pipe `\\.\pipe\openssh-ssh-agent`. Signing in alone does *not* do this — it's a separate toggle.

3. **⚠️ CORRECTION — WSL does not get `~/.1password/agent.sock` automatically.**
   An earlier version of this runbook claimed 1Password 8.10+ exposes the socket into WSL by itself. **It does not.** 1Password only creates a *Windows named pipe*, and WSL cannot open a named pipe directly. The socket must be bridged:

   - Windows: `winget install --exact --id albertony.npiperelay`
     lands at `C:\Users\plaza\AppData\Local\Microsoft\WinGet\Packages\albertony.npiperelay_Microsoft.Winget.Source_8wekyb3d8bbwe\npiperelay.exe`
   - WSL: `sudo apt-get install socat`
   - Bridge script: **`~/.local/bin/op-ssh-agent-relay`** (already written on legato). It runs
     `socat UNIX-LISTEN:$SOCK,fork EXEC:npiperelay.exe -ei -s //./pipe/openssh-ssh-agent`
     and is invoked from `~/.zshrc`.

   Diagnostic for "is the toggle actually on":
   ```zsh
   powershell.exe -NoProfile -Command "[System.IO.Directory]::GetFiles('\\\\.\\pipe\\')" | grep openssh
   ```
   `1Password-BrowserSupport` pipes present but no `openssh-ssh-agent` pipe = app is running and signed in, but the SSH agent toggle is **off**.

4. **Wire `SSH_AUTH_SOCK`.** Already done on legato — `~/.zshrc` calls the relay and only exports on success:
   ```zsh
   if [[ -x "$HOME/.local/bin/op-ssh-agent-relay" ]]; then
       "$HOME/.local/bin/op-ssh-agent-relay" 2>/dev/null
       [[ -S "$HOME/.1password/agent.sock" ]] && \
           export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"
   fi
   ```
   **Exit-code gotcha:** when socat is listening but the pipe behind it is dead, the connection is accepted then dropped and `ssh-add -l` exits **1** — the same code as the healthy "agent has no identities" case. Don't discriminate on exit status; match the message (`communication with agent failed` / `error fetching identities`). The relay script does this and tears down the dead socket so ssh keeps working off key files.

5. **Add or generate the key in 1Password.** New Item → SSH Key → Generate (Ed25519), tag as the Automatiq signing key. One key serves both GitHub auth and commit signing.

5a. **Point github auth at the agent** in `~/.ssh/config`. Note legato already has a `github-automatiq` alias using `~/.ssh/id_ed25519`; switching it to the agent means replacing `IdentityFile` with:
   ```
   Host github-automatiq
       HostName github.com
       User git
       IdentityAgent ~/.1password/agent.sock
       IdentitiesOnly yes
   ```
   Test: `ssh -T git@github-automatiq`.

6. **Configure git signing, Automatiq-scoped.** The `[includeIf "gitdir:~/Code/automatiq/"]` → `~/.gitconfig-automatiq` include is wired (fixed 2026-08-04). Add to `~/.gitconfig-automatiq`:
   ```ini
   [gpg]
       format = ssh
   [gpg "ssh"]
       allowedSignersFile = ~/.config/git/allowed_signers
   [commit]
       gpgsign = true
   [user]
       signingKey = key::ssh-ed25519 AAAA...public-key...
   ```
   **Do not set `gpgsign = true` before `signingKey` exists** — it breaks every commit in those repos.

7. **Create the allowed signers file.**
   ```zsh
   mkdir -p ~/.config/git
   echo "josh.plaza@automatiq.com ssh-ed25519 AAAA...public-key..." >> ~/.config/git/allowed_signers
   ```

8. **Test a signed commit.**
   ```zsh
   cd ~/Code/automatiq/automatiq-iq
   git commit --allow-empty -m "test signing"
   git log --show-signature -1   # expect "Good signature"
   ```
   **⚠️ `--allow-empty` does NOT mean "ignore the index."** It only permits an empty *result*; anything already staged gets swept into the test commit. This happened on legato — three staged files were absorbed. Undo with `git reset --soft HEAD~1`, which restores the exact staged state (verify with `git write-tree` against the test commit's tree). Check `git status` **before** test-committing in a repo with live work, or test in a scratch repo instead.

9. **Add the public key to GitHub (Automatiq org) — twice.** Settings → SSH and GPG keys: once as an **Authentication Key**, once as a **Signing Key**. Same key, both types.

---

## Common gotchas on WSL2

- `SSH_AUTH_SOCK` must point to `~/.1password/agent.sock`. The wrong socket gives "sign_and_send_pubkey: signing failed."
- If the Windows 1Password app is not running, the socket exists but connections hang. It must be open (or set to start at login).
- `~/.1password/` is created by the Windows app — it is not a WSL artifact.
- The MSIX install means no `C:\Program Files\1Password`. Verify with `winget list --exact --id AgileBits.1Password` instead.

Related: [[reference_legato_ssh_keys]].
