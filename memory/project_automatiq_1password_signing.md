---
name: project_automatiq_1password_signing
description: 1Password SSH commit signing setup for Automatiq work on legato (Lenovo/WSL2) — not started as of 2026-08-04
metadata:
  type: project
---

Goal: set up Automatiq 1Password SSH agent on legato (the Lenovo WSL2 machine, hostname `public`, Tailscale `legato`) so git commits in `~/Code/automatiq/` are signed with an SSH key stored in the Automatiq 1Password account.

**Status as of 2026-08-04:** not started.

**Why:** Automatiq requires signed commits; 1Password is the org's approved key store.

**How to apply:** When the user asks to resume or check status, start from step 1 and verify each step is done before moving on.

---

## Setup steps (WSL2-specific)

1. **Windows side — 1Password installed and signed in to the Automatiq account.**
   Confirm: open 1Password on Windows, verify the Automatiq vault is accessible.

2. **Enable the SSH agent in 1Password.**
   Settings → Developer → "Use the SSH agent" checkbox on. This creates a named pipe on Windows
   and a Unix socket at `\\.\pipe\openssh-ssh-agent` (Windows) and exposes it to WSL2 at
   `~/.1password/agent.sock` inside WSL automatically (1Password 8.10+).

3. **Verify the WSL2 socket exists.**
   ```zsh
   ls -la ~/.1password/agent.sock
   ```
   If it doesn't exist, 1Password's WSL2 integration may need the "Integrate with 1Password SSH agent"
   toggle enabled in Settings → Developer.

4. **Wire SSH_AUTH_SOCK in `~/.zshrc`.**
   ```zsh
   export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"
   ```
   Then `source ~/.zshrc` and confirm with `ssh-add -l` (should list keys from 1Password, or
   return "no identities" if no keys added yet — either is fine as long as it doesn't error).

5. **Add or generate the key in 1Password.**
   In 1Password on Windows: New Item → SSH Key → Generate (Ed25519 preferred), tag it as the
   Automatiq signing key. Copy the public key. This same key will be used for both GitHub auth
   (pushing/pulling) and commit signing — one key, two purposes.

5a. **Wire `~/.ssh/config` so GitHub auth goes through 1Password.**
   ```
   Host github.com
       IdentityAgent ~/.1password/agent.sock
       IdentitiesOnly yes
   ```
   Test with `ssh -T git@github.com` — should reply with your GitHub username.

6. **Configure git for SSH signing (Automatiq-scoped).**
   The gitconfig include for `~/Code/automatiq/` is already wired on legato. Add signing config
   to the Automatiq-scoped gitconfig (likely at `~/Code/automatiq/.gitconfig` or wherever the
   `[includeIf]` points):
   ```ini
   [gpg]
       format = ssh
   [gpg "ssh"]
       allowedSignersFile = ~/.config/git/allowed_signers
   [commit]
       gpgsign = true
   [user]
       signingKey = key::ssh-ed25519 AAAA...your-public-key...
   ```

7. **Create the allowed signers file.**
   ```zsh
   mkdir -p ~/.config/git
   echo "josh.plaza@automatiq.com ssh-ed25519 AAAA...your-public-key..." >> ~/.config/git/allowed_signers
   ```

8. **Test a signed commit.**
   ```zsh
   cd ~/Code/automatiq/<any-repo>
   git commit --allow-empty -m "test signing"
   git log --show-signature -1
   ```
   Should show "Good signature."

9. **Add the public key to GitHub (Automatiq org) — twice.**
   GitHub → Settings → SSH and GPG keys:
   - New SSH key → Key type: **Authentication Key** (for push/pull auth). Paste the Ed25519 public key.
   - New SSH key → Key type: **Signing Key** (for verified commits). Paste the same public key.
   Both entries point to the same key; GitHub needs each registered under its own type.

---

## Common gotchas on WSL2

- `SSH_AUTH_SOCK` must point to `~/.1password/agent.sock`, not the default WSL SSH agent or
  `/tmp/ssh-*/agent.*`. The wrong socket gives "sign_and_send_pubkey: signing failed."
- If the Windows 1Password app is not running, the socket exists but connections hang. 1Password
  must be open (or set to start at login) for signing to work.
- The `~/.1password/` dir is created by 1Password's Windows app — it is not a WSL artifact.
  If it doesn't appear, make sure 1Password for Windows (not the browser extension) is running.
