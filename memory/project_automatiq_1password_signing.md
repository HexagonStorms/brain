---
name: project_automatiq_1password_signing
description: 1Password SSH commit signing setup for Automatiq work on legato (WSL2) — app installed 2026-08-04, awaiting Automatiq sign-in
metadata:
  type: project
---

Goal: set up the Automatiq 1Password SSH agent on **legato** (the WSL2 laptop — formerly called "Lenovo", hostname formerly `public`; see `machines/legato.md`) so git commits in `~/Code/automatiq/` are signed with an SSH key stored in the Automatiq 1Password account.

**Why:** Automatiq requires signed commits; 1Password is the org's approved key store.

**Status as of 2026-08-04:** step 1 done, blocked on GUI sign-in.

- ✅ **Step 1** — 1Password for Windows installed via `winget install --exact --id AgileBits.1Password` (v8.12.30.21). It lands as an **MSIX/Store package**, not in `C:\Program Files` — the exe alias is `C:\Users\plaza\AppData\Local\Microsoft\WindowsApps\1Password.exe`. Don't go looking in Program Files and conclude it isn't installed.
- ✅ **Bridge prerequisites** — `socat` (WSL) and `npiperelay` (Windows) installed, and `~/.local/bin/op-ssh-agent-relay` written and wired into `~/.zshrc`. Verified to fail safe while the agent is off.
- ⏳ **Step 2** — Jo is signed in, but the **"Use the SSH agent" toggle is still off**: the `1Password-BrowserSupport` pipes exist while `openssh-ssh-agent` does not.
- ⏳ **Steps 5 onward** — blocked on step 2. All scriptable once the pipe is up.

**How to apply:** When the user asks to resume, run `~/.local/bin/op-ssh-agent-relay`. Exit 0 → the agent is live, jump to step 5. Exit 1 with "no agent behind the pipe" → the Developer toggle still isn't on.

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

9. **Add the public key to GitHub (Automatiq org) — twice.** Settings → SSH and GPG keys: once as an **Authentication Key**, once as a **Signing Key**. Same key, both types.

---

## Common gotchas on WSL2

- `SSH_AUTH_SOCK` must point to `~/.1password/agent.sock`. The wrong socket gives "sign_and_send_pubkey: signing failed."
- If the Windows 1Password app is not running, the socket exists but connections hang. It must be open (or set to start at login).
- `~/.1password/` is created by the Windows app — it is not a WSL artifact.
- The MSIX install means no `C:\Program Files\1Password`. Verify with `winget list --exact --id AgileBits.1Password` instead.

Related: [[reference_legato_ssh_keys]].
