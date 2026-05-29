Systematically debug the current error, test failure, or unexpected behavior.

## Process

1. **Read the actual error first** — do not propose fixes before seeing the full error message, stack trace, or failing test output. Run the relevant command to capture it if not already visible.

2. **Identify the failure point** — locate the exact file, line, and condition that triggered the error. Do not guess.

3. **Trace the cause** — follow the execution path backward from the failure. Check:
   - Is the input what you expected?
   - Does the called method/function actually exist with the expected signature?
   - Are there type mismatches, null values, or missing config?
   - For Laravel: check service provider bindings, middleware, and queue/job context
   - For Node/TypeScript: check async/await correctness, type narrowing, and module resolution

4. **Form a hypothesis** — state what you believe the root cause is and why, before touching any code.

5. **Propose the minimal fix** — change only what is necessary to address the root cause. Do not refactor surrounding code.

6. **Verify** — re-run the failing test or reproduce the error to confirm it is resolved.

## Rules

- Never skip step 1. Always read the error before proposing anything.
- Do not retry the same fix twice. If it didn't work, re-examine the hypothesis.
- If the error is in vendor code or a framework, look for the caller in application code — that is almost always where the fix lives.
