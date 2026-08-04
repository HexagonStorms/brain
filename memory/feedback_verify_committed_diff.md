---
name: feedback_verify_committed_diff
description: "After a hand-applied fix, verify the committed diff on origin, not just that local tests pass"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 15568663-b6fe-42cf-a9d2-0f489d37749c
  modified: 2026-07-28T04:14:52.276Z
---

When applying code fixes by hand in a git worktree, ALWAYS verify the change landed in the
commit and on origin, not just that the working tree is green.

**Why:** In a plfog session I edited `hub/discord_commands.py` (working tree), then ran a
`git merge` + `git add plfog/version.py` + `git commit` — staging ONLY version.py. The code
edits stayed uncommitted. Local `pytest` passed (it runs the working tree, which HAD the
edits), so I pushed and moved on believing it shipped. Then I removed the worktree, discarding
the uncommitted edits. Only the version bump reached the branch; an independent re-review
caught that the actual fixes were absent.

**How to apply:**
- Prefer `git add -A` (or explicitly stage every changed file) before committing a fix; don't
  `git add <one file>` when you changed several.
- After pushing, verify the fix is really on origin, e.g.
  `git show "${ref}:path" | grep -c '<marker>'` and confirm the OLD code is gone. (zsh treats
  `$ref:h` as a modifier, so brace it: `"${ref}:path"`.)
- A green working-tree test run is NOT proof the commit contains the change.
- Independent verification (a re-review agent that reads the pushed head) is worth it after a
  hand-applied fix. See [[reference_plfog_pr_ops]].
