Use the fact-checker agent to verify the most recent claims in this conversation.

Examine the last assistant response and for every factual claim about code:
- Function/method names — do they exist? Find the definition with file:line.
- Class names — are they actually defined and importable?
- File paths — do they exist at exactly the stated path?
- API endpoints or parameters — confirmed in source, or assumed?
- Type signatures and return values — do they match the actual implementation?
- Any "this is how X works" statement — verify it against the actual code.

For each claim: find the source and quote it. If you cannot find a source, state that explicitly — "not found in available context" is a valid and important finding.

Report only HIGH or MEDIUM confidence issues with exact evidence.
If everything checks out, say: "Verified: no issues found in the most recent response."
Do not report style concerns, architecture opinions, or low-confidence guesses.
