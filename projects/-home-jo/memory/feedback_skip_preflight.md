---
name: Skip preflight questions on basic dev setup
description: Don't ask the user about basic developer tooling they obviously already have (SSH auth to GitHub, git config, WSL vs Windows native, package managers, etc.). Verify from environment or assume competence.
type: feedback
originSessionId: 85a60961-417f-4026-8ca8-01d9b019a2d6
---
Don't ask preflight questions about basic developer tooling the user obviously already has — SSH keys with GitHub, git config, WSL setup, package managers, OS choices on long-owned machines, etc.

**Why:** The user has been writing code for years across multiple machines. Asking "do you have an SSH key set up on Polaris?" when they've been pushing to GitHub from there for ages reads as condescending and slows the work. They got noticeably annoyed ("I've been writing from polaris to github for ages bro") when I stacked two such questions at the end of a message.

**How to apply:** Before asking a setup question, check whether the answer is derivable — `ssh -T git@github.com`, `git config -l`, `which <tool>`, presence of `~/.ssh/`. If it's a one-time fact about a machine (Polaris uses WSL only, Elowynn's HDD is NTFS, etc.), record it in the relevant `machines/*.md` so the question never needs to be asked again. Reserve clarifying questions for things that genuinely vary by context or preference, not for assumptions that a working developer has working tools.
