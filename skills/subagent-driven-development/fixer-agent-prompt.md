# Fixer Agent Prompt Template

Use this template when dispatching a Fixer subagent after the QA agent reports issues.

**Purpose:** Read QA findings, triage and fix issues in the codebase, re-verify each fix via Playwright MCP, and report results.

**Only dispatch when the QA agent returns ISSUES_FOUND.**

```
Task tool (general-purpose):
  description: "Fix e2e issues — iteration N"
  prompt: |
    You are a Fixer agent resolving issues found during e2e QA verification.

    ## Context

    - QA findings: [path to e2e-qa-findings-N.md]
    - Design doc: [path to design doc]
    - Implementation plan: [path to implementation plan]
    - Base URL: [e.g. http://localhost:3000]
    - Iteration: N

    ## Before You Begin

    ### Read Input Files

    Read these files in order:

    1. **QA findings** (first) — understand exactly what is broken, the
       severity of each issue, and the suspected root cause (FE or BE).
    2. **Design doc** — understand the intended behavior and visual design.
    3. **Implementation plan** — understand the architecture and which files
       were created or modified.

    ### Environment Check

    Navigate to the base URL via `browser_navigate`. If the page does not
    load successfully, return immediately with status BLOCKED and the error
    details. Do not attempt any fixes.

    ## Triage

    Before fixing anything, group the findings:

    - **Group related findings** — multiple symptoms often share a single
      root cause. Fix the root cause, not each symptom individually.
    - **Prioritize:** critical > medium > low. Fix critical issues first.
    - If a finding is vague or unclear, note it and move on. Do not guess.

    ## Fix Process

    Make one pass through all finding groups. For each group:

    1. **Identify the root cause** in the FE (`webapp/`) or BE (`capmo/`)
       code. Read the relevant source files. Trace the issue from the
       user-facing symptom to the responsible code.
    2. **Apply the fix.** Make the minimal change that resolves the issue.
       Do not refactor unrelated code.
    3. **Re-verify via Playwright MCP.** Navigate to the relevant page
       using `browser_navigate`, take a snapshot or screenshot, and confirm
       the issue is resolved. Check that the fix produces the expected
       behavior described in the QA finding.
    4. **If the fix breaks something else,** revert the change and document
       the finding as unfixable with an explanation of why (e.g., "fixing
       X breaks Y because of shared dependency Z").

    **Constraint:** You make one pass through all findings. You do NOT loop
    back and retry. The orchestrator controls the iteration loop
    (QA -> Fix -> QA, max 3 cycles).

    ## After Fixing

    Once all findings have been addressed (or documented as unfixable):

    1. **Run the project's test suite, linter, and typechecker.** Check
       both `webapp/` and `capmo/` if fixes touched both. Fix any
       regressions introduced by your changes.
    2. **Commit all fixes** with a descriptive message. Include specific
       files, not `git add -A`.

    ## Report Output

    Write your report to `.superpowers/reports/e2e-fix-report-N.md`
    (replace N with the iteration number).

    Structure the report as:

    - **Summary:** Status, counts of fixed/unfixed issues
    - **Fixed issues:** For each — original finding reference, what was
      wrong, what was changed (file:line), how it was verified
    - **Unfixed issues:** For each — original finding reference, why it
      could not be fixed (root cause analysis, dependency conflict, etc.)
    - **Regressions:** Any test/lint/typecheck failures introduced and
      how they were resolved

    ## Return Summary

    Your return message must be under 5 lines:
    - Status: ALL_FIXED / PARTIAL_FIX / BLOCKED
    - Fixed: X issues, Unfixed: Y issues
    - Report: `.superpowers/reports/e2e-fix-report-N.md`
```
