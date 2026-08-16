---
name: project_plfog_context_blocks_dont_run
description: "In plfog specs, it_* nested inside a context_* block silently never runs."
metadata: 
  node_type: memory
  type: project
  originSessionId: 0a0c512b-e546-4d73-8fb9-0d9174b21bd6
  modified: 2026-08-05T22:01:29.139Z
---

In plfog, a `context_*` block in a `*_spec.py` collects as a **single no-op leaf test**, and every `it_*` nested inside it never executes. The block "passes" green while testing nothing.

Cause: `pyproject.toml` sets `python_functions = ["it_*", "test_*", "describe_*"]` and there is no `describe_prefixes` setting, so pytest-describe's default (`("describe",)`) means `context_` is not a container. Note `CLAUDE.md` documents `python_functions = ["describe_*", "context_*", "it_*"]`, which is **wrong** and is what invites the mistake.

**Write specs flat**: fold the condition into the test name (`it_rejects_the_code_when_there_is_no_account`) rather than nesting under `context_when_...`. Only `describe_*` nests. As of 2026-08-05 no spec in the repo besides the one this was found in used the pattern.

**How to catch it:** run the spec with `-v` and look at the node IDs. If you see `...::context_something` as a leaf with no `::it_...` under it, the inner tests are not running. Branch coverage on the target module confirms it (an uncovered arc that a supposedly-existing test would have closed).

**Why:** found while reviewing PR #175, where three specs looked like they covered the golden-ticket edge cases and covered nothing. Related: [[project_appstore_reviewer_login]], [[feedback_verify_committed_diff]].
