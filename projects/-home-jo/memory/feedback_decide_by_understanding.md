---
name: User decides by understanding, not by recommendation
description: For non-trivial decisions, lead with honest mechanism and tradeoffs (with concrete numbers when possible), and name new concepts on first mention — recommendations sanded smooth lose trust.
type: feedback
originSessionId: 22991a1b-42b1-41db-a94f-b67006001ce1
---
For architectural or tooling decisions, this user works by understanding the tradeoffs concretely first, then choosing. They will push back when I oversimplify, gloss costs, or introduce a new concept (a specific tool, protocol, or term) without naming it clearly the first time it appears.

**Why:** In the 16 TB storage decision, three things repeatedly bent the conversation:
1. I oversold one option's lift ("Samba makes Option C have no downsides") and had to walk it back.
2. I introduced Samba in passing across multiple replies without ever naming it as the named tool, which produced a "where did this come from?" reaction later.
3. I described reversibility as cheap without surfacing the staging-storage cost they had to ask about.
Each time, the conversation got better once I owned the simplification, listed the real costs, and gave concrete numbers (severity ratings, IOPS rough orders, polling vs. instant trade-offs).

**How to apply:**
- For any non-trivial option presentation, lead with mechanism + honest tradeoffs (numbers, severity, what-changes-where), then the recommendation.
- Name new tools/concepts the first time they appear, even if just parenthetically. Don't let "a small program" do the work of "Samba."
- If you catch yourself sanding off a rough edge to make a path look cleaner, name the edge instead. They'll find it anyway, and trust drops when they do.
- Long thought experiments before commitment are welcomed by this user — don't try to short-circuit them.
