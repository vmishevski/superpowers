# E2E Verification Rework Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the Fixer agent with per-finding implementer dispatch, making the QA agent produce individual finding files and the orchestrator route fixes through the existing implementer pipeline with systematic-debugging.

**Approach:** Remove the Fixer agent entirely. QA agent writes one file per finding (UI-focused, no code speculation). Orchestrator creates one fix task per finding, dispatches implementers sequentially (all fix tasks get systematic-debugging), skips review cycle for fix tasks, re-dispatches QA to verify. Progress detection replaces fixed iteration counting. Finding files persist across QA rounds using a numbering offset to avoid collisions.

**Alternatives considered:**
- QA agent produces grouped fix tasks (rejected: overloads QA's context which is full of Playwright/browser state)
- Triage agent between QA and orchestrator (rejected: another agent type to maintain, over-engineered)
- Orchestrator reads full QA report and groups findings (rejected: pollutes orchestrator context, orchestrator starts "helping")
- Functional/visual type classification to decide systematic-debugging (rejected: blurry boundary, misclassification risk, always include is safer)

**Key assumptions:**
- Sequential implementer dispatch for fix tasks is acceptable (no parallel fix dispatch)
- A finding already fixed by a previous implementer will be quickly identified as not reproducible (implementer reports ALREADY_RESOLVED)
- Safety cap of 3 total QA dispatches provides 2 fix rounds, which is sufficient given each round dispatches dedicated implementers per finding

**Tech Stack:** Markdown skill files, no code changes

---

## Task 1: Delete fixer-agent-prompt.md

**Acceptance Criteria:**
- `skills/subagent-driven-development/fixer-agent-prompt.md` no longer exists

**Technical Specification:**
- Delete the file `skills/subagent-driven-development/fixer-agent-prompt.md`

Note: References to the Fixer agent in other files (SKILL.md, writing-plans/SKILL.md) are cleaned up in Tasks 3 and 4. Historical plan documents in `docs/plans/` that mention "fixer" are left as-is.

**Tests:** No test — file deletion. Verify with `ls skills/subagent-driven-development/`.

**Lint/typecheck:** N/A (markdown only)

**Commit:**
```bash
git rm skills/subagent-driven-development/fixer-agent-prompt.md
git commit -m "remove fixer agent prompt template"
```

---

## Task 2: Rewrite qa-agent-prompt.md output format

**Depends on:** None

**Acceptance Criteria:**
- QA agent writes one file per finding to `.superpowers/reports/fix-finding-N.md`
- Finding numbering starts at a configurable offset (provided by orchestrator) to avoid collisions across QA rounds
- Each finding file contains: severity, description, steps to reproduce, expected vs observed
- No code-level speculation (no "suspected root cause")
- No iteration numbering in the prompt
- No consolidated report — individual finding files ARE the report
- Return summary lists finding file paths with severity
- PASS and BLOCKED return formats unchanged
- QA Process, Token Optimization, and Before You Begin sections stay as-is

**Technical Specification:**

Modify `skills/subagent-driven-development/qa-agent-prompt.md`:

1. Remove `- Iteration: N` from the Context section. Add `- Finding number offset: [N, default 1]` — the orchestrator provides this to avoid file naming collisions across QA rounds.

2. Replace the Findings Format section with:

```markdown
## Findings Output

Write one file per finding to `.superpowers/reports/fix-finding-N.md`.
Start N at the finding number offset provided in the Context section.

Each finding file must follow this exact format:

    **Severity:** critical / medium / low

    [One-sentence description of what is wrong]

    **Steps to reproduce:**
    1. [Exact sequence of actions]

    **Expected:** [What should happen]
    **Observed:** [What actually happens]

Keep findings factual and UI-focused. Describe what you see in the browser.
Do not speculate about code, root causes, or implementation details.
```

3. Replace the Report Output section with:

```markdown
## Report Output

Write individual finding files as described above. Do not write a consolidated report.
If no issues found, do not write any finding files.
```

4. Replace the Return Summary section with:

```markdown
## Return Summary

Your return message must follow this exact format:

On PASS:
    Status: PASS
    Verified: [brief list of what was checked]

On ISSUES_FOUND:
    Status: ISSUES_FOUND
    Findings: [count]
      1: .superpowers/reports/fix-finding-N.md (severity)
      2: .superpowers/reports/fix-finding-N+1.md (severity)
      ...

On BLOCKED:
    Status: BLOCKED
    Reason: [what went wrong]
```

5. Update the description field in the template from `"E2E QA verification — iteration N"` to `"E2E QA verification"`

**Tests:** Read the modified file and verify:
- No mention of "iteration" anywhere (except "finding number offset" context parameter)
- No mention of "consolidated report" or `e2e-qa-findings`
- No mention of "suspected root cause" or "FE or BE"
- Finding file format matches spec
- Return summary format matches spec
- Finding number offset parameter present in Context section

**Lint/typecheck:** N/A (markdown only)

**Commit:**
```bash
git add skills/subagent-driven-development/qa-agent-prompt.md
git commit -m "rewrite QA agent output to individual finding files"
```

---

## Task 3: Rewrite SKILL.md E2E verification phase

**Depends on:** Task 1, Task 2

**Acceptance Criteria:**
- Flow diagram shows: QA → findings → fix tasks via implementer → re-QA loop
- No references to Fixer agent, fixer-agent-prompt.md, or e2e-fix-report
- No fixed iteration numbering (no "QA-Fix iterations < 3")
- E2E Verification Phase section describes the full orchestrator flow for fix tasks
- Includes guidance on how to construct implementer dispatch for fix tasks (with systematic-debugging always included)
- Includes "cannot reproduce" guidance (implementer reports ALREADY_RESOLVED)
- Includes finding number offset tracking across QA rounds
- Includes progress detection (same findings = stuck → escalate)
- Safety cap: 3 total QA dispatches (= 2 fix rounds)
- Report file naming updated (remove fixer report, replace QA report naming with fix-finding pattern)
- Prompt templates list updated (remove fixer)
- Example workflow updated
- Red Flags section updated

**Technical Specification:**

Modify `skills/subagent-driven-development/SKILL.md`:

**A. Flow diagram (lines 62-96)** — Replace the E2E-related nodes and edges. Remove:
- `"Dispatch Fixer subagent (./fixer-agent-prompt.md)"` node
- `"QA-Fix iterations < 3?"` node
- `"Report unfixed issues to user"` node
- All edges involving the above

Add:
- `"Create fix task per QA finding"` node
- `"Dispatch implementer for each fix task (sequential)"` node
- `"All fix tasks done, re-dispatch QA"` node
- `"Making progress and under safety cap?"` diamond
- `"Escalate to user"` node
- Edges: QA ISSUES_FOUND → Create fix tasks → Dispatch implementer → Re-dispatch QA → QA check → loop or finish
- Edge: not making progress or cap reached → Escalate to user → finishing

**B. Report file naming (lines 127-132)** — Replace:
```
- `.superpowers/reports/e2e-qa-findings-N.md` — QA agent's findings (N = iteration number)
- `.superpowers/reports/e2e-fix-report-N.md` — Fixer agent's repair report (N = iteration number)
```
With:
```
- `.superpowers/reports/fix-finding-N.md` — QA agent's individual finding (N = finding number, persists across rounds)
```

**C. Prompt templates (lines 140-146)** — Remove fixer line:
```
- `./fixer-agent-prompt.md` - Dispatch Fixer subagent to resolve QA findings
```

**D. Example workflow (lines 218-239)** — Replace the entire E2E Verification Phase example:

```
[Plan has E2E Verification task? → Yes]

E2E Verification Phase:

[Dispatch QA subagent with E2E task text, Figma refs, design doc path, plan path, finding offset 1]
QA agent returns summary:
  Status: ISSUES_FOUND
  Findings: 2
    1: .superpowers/reports/fix-finding-1.md (critical)
    2: .superpowers/reports/fix-finding-2.md (medium)

[Create 2 fix tasks in TodoWrite]

[Read fix-finding-1.md, dispatch implementer with systematic-debugging]
Implementer returns:
  Status: DONE
  Commit: abc1234

[Read fix-finding-2.md, dispatch implementer with systematic-debugging]
Implementer returns:
  Status: DONE — ALREADY_RESOLVED (previous fix resolved this too)

[Re-dispatch QA with finding offset 3]
QA agent returns summary:
  Status: PASS
  Verified: Form submission, success toast, redirect

[Proceed to finishing-a-development-branch]
```

**E. E2E Verification Phase section (lines 242-258)** — Complete rewrite:

```markdown
## E2E Verification Phase

After the final code review and before finishing-a-development-branch, check if the plan contains an E2E Verification task.

**Orchestrator responsibilities:**

1. Check if the plan has an E2E Verification task. If not, skip to finishing-a-development-branch.
2. Initialize finding number offset to 1.
3. Dispatch QA subagent using `./qa-agent-prompt.md`. Provide: E2E task text, Figma references, design doc path, implementation plan path, finding number offset.
4. Read QA summary:
   - PASS → proceed to finishing-a-development-branch
   - BLOCKED → report to user (environment likely not running), proceed to finishing-a-development-branch
   - ISSUES_FOUND → continue to step 5
5. Read finding file paths from QA summary. Create one fix task per finding in TodoWrite.
6. For each fix task (sequentially):
   - Read the finding file
   - Dispatch implementer using `./implementer-prompt.md` with the fix task template (see below)
   - All fix tasks get systematic-debugging — no exceptions
   - Do NOT dispatch spec reviewer or code quality reviewer for fix tasks
   - If implementer reports ALREADY_RESOLVED, mark task complete and move on
7. After all fix tasks complete, update the finding number offset (previous offset + number of findings from last QA round).
8. Progress check: compare current QA finding count against previous round.
   - Fewer findings or different issues → making progress, re-dispatch QA (loop to step 3)
   - Same finding count with same descriptions → stuck, escalate to user with finding file paths
9. Safety cap: after 3 total QA dispatches, escalate to user regardless. This provides 2 fix rounds.

### Fix task dispatch template

When dispatching an implementer for a fix task, fill the implementer prompt's Task Description section with:

    ## Task Description

    Fix an issue found during e2e QA verification.

    [CONTENTS OF fix-finding-N.md pasted here]

    ## Context

    This is a fix task from e2e QA. The feature is implemented but QA found
    issues in the browser.

    - Design doc: [path]
    - Implementation plan: [path]

    You MUST use the systematic-debugging skill to investigate before fixing.
    Do NOT patch symptoms. Find the root cause.

    If you cannot reproduce the issue after initial investigation, report
    ALREADY_RESOLVED and move on. Do not force a fix for a non-existent problem.
```

**F. Red Flags section (lines 307-309)** — Replace:
```
- Skip e2e verification when plan includes an E2E Verification task (every phase matters)
- Browse the app yourself as orchestrator (dispatch QA subagent instead)
- Accept "close enough" on e2e findings without dispatching fixer
```
With:
```
- Skip e2e verification when plan includes an E2E Verification task (every phase matters)
- Browse the app yourself as orchestrator (dispatch QA subagent instead)
- Dispatch spec/code-quality reviewers for fix tasks (re-QA is the verification)
- Fix QA findings yourself instead of dispatching implementer subagents
- Delete finding files between QA rounds (they persist for the record)
```

**Tests:** Read the modified file and verify:
- No mention of "fixer", "Fixer", "fixer-agent-prompt" anywhere
- No mention of "e2e-qa-findings-N" or "e2e-fix-report"
- No mention of "QA-Fix iterations"
- E2E Verification Phase mentions systematic-debugging
- E2E Verification Phase mentions ALREADY_RESOLVED
- E2E Verification Phase mentions finding number offset
- E2E Verification Phase mentions progress detection
- Example workflow shows the new flow with offset tracking
- Red Flags includes "Delete finding files" prohibition

**Lint/typecheck:** N/A (markdown only)

**Commit:**
```bash
git add skills/subagent-driven-development/SKILL.md
git commit -m "rework e2e verification: remove fixer, route fixes through implementer"
```

---

## Task 4: Update writing-plans/SKILL.md reference

**Depends on:** None

**Acceptance Criteria:**
- E2E Verification Task section no longer references "Fixer subagents"
- Wording reflects the actual flow

**Technical Specification:**

Modify `skills/writing-plans/SKILL.md` line 64:

Replace:
```
This task is executed by the QA and Fixer subagents in subagent-driven-development, not by a regular implementer.
```
With:
```
This task is executed by the e2e verification phase in subagent-driven-development, not by a regular implementer.
```

**Tests:** Read the file and verify no mention of "Fixer" anywhere.

**Lint/typecheck:** N/A (markdown only)

**Commit:**
```bash
git add skills/writing-plans/SKILL.md
git commit -m "update e2e task reference to remove fixer mention"
```
