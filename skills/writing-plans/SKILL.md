---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** This should be run in a dedicated worktree (created by brainstorming skill).

**Save plans to:** `docs/plans/YYYY-MM-DD-<feature-name>.md`

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** [One sentence describing what this builds]

**Approach:** [2-3 sentences about the chosen approach and WHY this approach over alternatives]

**Alternatives considered:** [Brief list of rejected approaches with one-line reasons]

**Key assumptions:** [What are we assuming that, if wrong, would invalidate this plan?]

**Tech Stack:** [Key technologies/libraries]

---
```

## Mandatory Task Structure

Every task MUST follow this skeleton. The plan author fills in specifics, but the structure is non-negotiable.

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`

**Test:** `tests/exact/path/to/test.py` — [what behavior this test validates]

If this task genuinely does not need a test (e.g., config-only change, documentation), state why: **No test because:** [reason]

**Step 1: Write the failing test**

[Exact test code]

**Step 2: Run test to verify it fails**

Run: `[exact test command]`
Expected: FAIL with "[expected failure message]"

**Step 3: Write minimal implementation**

[Exact implementation code]

**Step 4: Run test to verify it passes**

Run: `[exact test command]`
Expected: PASS

**Step 5: Lint and typecheck**

Run: `[project-specific lint/typecheck command]`
Expected: No errors

**Step 6: Commit**

[Exact git add and commit commands]
````

**What MUST be in every task:**
- **Test:** Either a test file and what it validates, or an explicit "No test because" with a reason
- **Lint/typecheck step:** Always present. The project's lint and typecheck commands.
- **Commit step:** Always present. Specific files to add and a descriptive commit message.

These are not optional. If a plan author omits them, the plan is incomplete.

## Remember
- Exact file paths always
- Complete code in plan (not "add validation")
- Exact commands with expected output
- Reference relevant skills with @ syntax
- DRY, YAGNI, TDD, frequent commits

## Execution Handoff

After saving the plan, offer execution choice:

**"Plan complete and saved to `docs/plans/<filename>.md`. Two execution options:**

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

**2. Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints

**Which approach?"**

**If Subagent-Driven chosen:**
- **REQUIRED SUB-SKILL:** Use superpowers:subagent-driven-development
- Stay in this session
- Fresh subagent per task + code review

**If Parallel Session chosen:**
- Guide them to open new session in worktree
- **REQUIRED SUB-SKILL:** New session uses superpowers:executing-plans
