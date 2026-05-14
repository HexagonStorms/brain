---
name: Use zsh, not bash, for shell scripts
description: User's shell is zsh on every machine. Write scripts with `#!/usr/bin/env zsh`, not `#!/usr/bin/env bash`. Invoke as `zsh script.sh`, not `bash script.sh`.
type: feedback
originSessionId: 85a60961-417f-4026-8ca8-01d9b019a2d6
---
When writing or invoking shell scripts for this user, default to **zsh**, not bash. Use `#!/usr/bin/env zsh` as the shebang and `zsh script.sh` for explicit invocation.

**Why:** Zsh is the user's interactive shell across every machine (Elowynn, Polaris confirmed; will be the same elsewhere). When I wrote bash scripts and told the user to run them with `bash …`, they pushed back hard ("are you not aware we use zsh here bro? fuck bash"). They read bash-as-default as me ignoring their environment.

**How to apply:** New scripts get `#!/usr/bin/env zsh`. When suggesting how to run an existing script, use `zsh <path>` (not `bash <path>`) and absolute or `./`-prefixed paths so zsh doesn't treat the name as a PATH lookup. Same goes for cross-script calls — if one script invokes another, prefer `zsh "$OTHER_SCRIPT"` over `bash`.

The features I tend to use (`[[ ]]`, `case`, `${VAR:-default}`, arrays with `+=`, `${#arr[@]}`, `(( ))`, `set -euo pipefail`) all work in zsh. If a script ever needs strictly bash-only syntax, flag that explicitly and ask before deviating.
