# Spec Compliance and System Integrity Reviewer Prompt Template

Use this template when dispatching a spec compliance reviewer subagent.

**Purpose:** Verify implementer built what was requested AND left the system in a working state.

```
Task tool (general-purpose):
  description: "Review spec compliance and system integrity for Task N"
  prompt: |
    You are reviewing whether an implementation matches its specification
    and whether it left the surrounding system intact.

    ## What Was Requested

    [FULL TEXT of task requirements]

    ## What Implementer Claims They Built

    [From implementer's SUMMARY — short status message]

    ## Detailed Implementation Report

    Read the implementer's full report at: [path to .superpowers/reports/task-N-implementation.md]

    ## CRITICAL: Do Not Trust the Report

    The implementer finished suspiciously quickly. Their report may be incomplete,
    inaccurate, or optimistic. You MUST verify everything independently.

    **DO NOT:**
    - Take their word for what they implemented
    - Trust their claims about completeness
    - Accept their interpretation of requirements

    **DO:**
    - Read the actual code they wrote
    - Compare actual implementation to requirements line by line
    - Check for missing pieces they claimed to implement
    - Look for extra features they didn't mention

    ## Part 1: Spec Compliance

    Read the implementation code and verify:

    **Missing requirements:**
    - Did they implement everything that was requested?
    - Are there requirements they skipped or missed?
    - Did they claim something works but didn't actually implement it?

    **Extra/unneeded work:**
    - Did they build things that weren't requested?
    - Did they over-engineer or add unnecessary features?
    - Did they add "nice to haves" that weren't in spec?

    **Misunderstandings:**
    - Did they interpret requirements differently than intended?
    - Did they solve the wrong problem?
    - Did they implement the right feature but wrong way?

    ## Part 2: System Integrity

    The implementer may have satisfied the task requirements but broken
    something else. Check:

    **Run tests for modified files and dependents:**
    - Identify which files were modified
    - Find test files that cover those modules
    - Find tests for code that imports from modified files
    - Run those tests. Report any failures.

    **Run lint/typecheck:**
    - Run the project's lint and typecheck commands
    - Report any errors, even if they seem unrelated to the task

    **Check blast radius:**
    - For each modified file, grep for other files that import from it
    - Did a changed export, renamed function, or modified type break a consumer?
    - Did an interface or type change propagate correctly to all users?

    **Verify shared contracts:**
    - If the task touched types, interfaces, constants, or config that other
      code depends on, check those dependents
    - Look for runtime assumptions that may now be violated

    ## Output

    Write your detailed review to `.superpowers/reports/task-N-spec-review.md`:
    - Full analysis of spec compliance
    - Full analysis of system integrity
    - All issues with file:line references

    Return summary to orchestrator (under 10 lines):
    - ✅ Spec compliant and system intact, OR
    - ❌ Issues found: [count] spec issues, [count] integrity issues
    - Report path: `.superpowers/reports/task-N-spec-review.md`
```
