---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Overview

Write comprehensive implementation plans based on the design document. 
Your goal is to divide the implementation into multiple tasks. 
Each task achieves a meaningful addition towards the goal. The task is self sufficient and can be evaluated on it's own. 
Write clear and concise acceptance criterias for each task.
Write technical specification on how to achive the acceptance.  
Do not write exact code in the task. Write 
Document everything the implementer will need to know:
   - which files are relevant
   - what is the outcome of the task
   - how can the task be tested and what tests casees should be covered
   - docs the implementer will need to check
For each task to be complete, the implementer will need to run tests, linter, prettier and those should be passing.
Frequent commits. Commits at the end of the task, as final step. 
Task contains dependencies to other tasks, if there are any. 

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Save plans to:** `docs/plans/YYYY-MM-DD-<feature-name>.md`

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

**Goal:** [One paragraph describing what this builds]

**Approach:** [2-3 sentences about the chosen approach and WHY this approach over alternatives]

**Alternatives considered:** [Brief list of rejected approaches with one-line reasons]

**Key assumptions:** [What are we assuming that, if wrong, would invalidate this plan?]

**Tech Stack:** [Key technologies/libraries]

---
```

## Task Structure

**What MUST be in every task:**
- **Acceptance Criterias** Clear acceptance criteria of what is the outcome of the task.
- **Technical Specification** How to achieve the goal.
- **Tests:** Test cases that should be covered with tests
- **Lint/typecheck step:** Always present. The project's lint and typecheck commands. These must pass before committing. 
- **Commit step:** Always present. Specific files to add and a descriptive commit message.

These are not optional. If a plan author omits them, the plan is incomplete.

## E2E Verification Task

For plans with UI impact, include an E2E Verification task as the final task. This task is executed by the QA and Fixer subagents in subagent-driven-development, not by a regular implementer.

```
## Task N: E2E Verification

**Depends on:** All previous tasks

**Verification Flows:** [Reference the e2e verification flows from the design doc]

**Figma References:** [File key, node IDs for relevant designs, or "None" if no Figma designs]

**URLs to Verify:** [List of localhost URLs where the feature can be accessed]

**Environment:** Local dev (FE on localhost:3000, BE on localhost:8000)

**What "working" looks like:** [Description of expected visual and functional state]
```

This task does not follow the normal implementer → spec review → code quality review cycle. It is handled by the e2e verification phase in subagent-driven-development.

## Remember
- Exact file paths always
- Complete code in plan (not "add validation")
- Exact commands with expected output
- Reference relevant skills with @ syntax
- DRY, YAGNI, TDD, frequent commits

## Plan Challenge (Devil's Advocate)

After writing the plan but BEFORE presenting it to the user, dispatch a devil's advocate subagent using the template at `./advocate-prompt.md`.

**Process:**
1. Dispatch advocate subagent with full plan text and design/requirements text
2. Review advocate's output:
   - **Auto-fix items** (missing tasks, traceability gaps): Incorporate into the plan immediately
   - **Open challenges** (questionable assumptions, alternative approaches): Present to user
3. If auto-fixes were made, update the plan document
4. Present the plan AND open challenges to the user with options:
   - **Accept plan** — proceed to execution
   - **Update plan** — revise based on challenges, re-run advocate if changes are significant
   - **Back to brainstorming** — a challenge revealed a fundamental issue with the approach

**The plan is not complete until it has survived the advocate.**

Do NOT skip this step. Do NOT present the plan to the user before running the advocate.

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
