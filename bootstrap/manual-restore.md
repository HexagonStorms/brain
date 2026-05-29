# Manual restore checklist

Things the bootstrap scripts can NOT do for you. Save these to an encrypted
external drive (or 1Password / Bitwarden file attachment) BEFORE wiping the
old machine. None of this belongs in the brain repo.

## Sensitive backups to make before wipe

From the WSL home directory of the old machine, archive:

```bash
# Run on the OLD machine, before wiping.
tar -czf ~/lenovo-secrets-$(date +%Y%m%d).tar.gz \
    ~/.ssh \
    ~/.config/gh \
    ~/.claude/.credentials.json \
    ~/.gitconfig-automatiq
# Move the tarball off the machine (USB / cloud / Tailscale share) and verify
# you can read it back BEFORE proceeding to wipe.
```

What each piece is for:

| Path | What it is | Restore notes |
| --- | --- | --- |
| `~/.ssh/id_ed25519` | Automatiq (work) GitHub key | chmod 600 |
| `~/.ssh/lenovo` | old per-machine key for Lenovo (HexagonStorms / Past Lives / Bluehost) | bootstrap mints a fresh `~/.ssh/$USER` keypair, so this one only matters if you want continuity on hosts you can't re-key |
| `~/.ssh/siloh` | Elowynn access key | chmod 600; or generate fresh and re-authorize on Elowynn |
| `~/.ssh/config` | host aliases | bootstrap installs a fresh `~/.ssh/config` from `claude-config/ssh-config.example`, so this is optional |
| `~/.ssh/known_hosts` | trusted host fingerprints | optional; rebuilds on first connect |
| `~/.config/gh/` | gh CLI auth tokens | or re-run `gh auth login` |
| `~/.claude/.credentials.json` | Claude Code auth | or re-auth interactively |
| `~/.gitconfig-automatiq` | work identity overlay (Automatiq email) | restore verbatim |

The bootstrap's "mint fresh keys" path is the cleaner default for a new
machine — it forces you to re-add the pubkey on each service, which is also
a good audit moment. Only restore the old keys if you have hosts where
re-keying is painful (rare).

## Apps with no winget source

These have to be installed by hand on the new machine. None of them have
reliable winget IDs in the public catalog as of 2026-05-29.

| App | Where to get it |
| --- | --- |
| Ableton Live 12 Suite | https://www.ableton.com/account/ (sign in, download installer; license is on the account) |
| Riot Client | https://www.riotgames.com/en/download (League of Legends bundles in) |
| Fregonator 6.0 | proprietary installer; restore from backup or contact vendor |
| NVIDIA Graphics Driver | https://www.nvidia.com/Download/index.aspx (RTX 3070 Laptop GPU, Windows 11) — installs PhysX and NVIDIA App as well |

## Pre-wipe checklist

Uncommitted work that would be lost on wipe:

- [ ] `~/Code/cascaderescue` — `.claude/settings.local.json` modified. Commit or discard.
- [ ] `~/Code/automatiq/automatiq-iq` — `package-lock.json` modified. Likely a stray `npm install`; discard unless intentional.
- [ ] `~/Code/brain` — `settings.json` field reorder + `"model": "claude-opus-4-7"`. Commit before wipe.
- [ ] `~/Code/automatiq/ai-vault/` — empty directory, not a git repo. Nothing to save.

Other things easy to forget:

- [ ] Windows: export browser bookmarks/passwords (or confirm sync is on).
- [ ] Windows: note any Steam game saves not in Steam Cloud.
- [ ] Windows: export Ableton user library, presets, and project folder paths.
- [ ] WSL: `wsl --export Ubuntu D:\backups\ubuntu-$(date +%Y%m%d).tar` from Windows-side PowerShell. This is the nuclear-option backup of the entire WSL distro — keep it until the new machine is fully working.
