---
name: feedback-consult-before-budget-changes
description: Jo wants to always be consulted before any change to Actual Budget or connected bank account data — no autonomous writes.
metadata:
  type: feedback
---

Always propose budget/category/transaction changes in chat and get Jo's explicit go-ahead before writing anything to `budget.plaza.codes` (Actual Budget) or touching connected bank account data (SimpleFIN-linked accounts). This is a standing rule, not scoped to one task.

**Why:** Jo said it directly: "I want to always consult with you when referring to my budget in Actual Budget / connected bank accounts." Real financial data, live tool — he wants review-in-the-loop every time, not just for the initial budget-generation setup.

**How to apply:** Read/analysis (pulling transactions, computing averages, drafting proposed categories or amounts) is fine to do freely. Any write via the `@actual-app/api` — creating/editing categories, setting budgeted amounts, linking/unlinking bank connections — always gets proposed first and waits for explicit confirmation, even for small future tweaks, not just big changes. See [[project_actual_budget]] for the current setup this applies to.
