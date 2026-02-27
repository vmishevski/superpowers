# Orchestration Improvements Design

## Problem

Retrospective observations from multi-agent workflow usage revealed six categories of failure:

1. The orchestrator (main session) escapes into implementation mode instead of dispatching subagents
2. Generated tasks lack mandatory verification steps (tests, lint, commits)
3. Spec reviewers only check task acceptance criteria, missing system-wide breakage
4. No critical thinking step challenges the plan before execution begins
5. Context bloat causes the orchestrator to drift from skill compliance over time
6. Worktree isolation per plan is not automated (deferred — existing skill is sufficient for now)

## Goal

Harden the orchestration workflow so that: the orchestrator cannot do implementation work directly, every task includes verification steps structurally, reviewers catch system-wide breakage, plans are challenged before execution, and context growth is managed through file-based handoff.

## Approach

Six changes across skills, prompt templates, and hooks. Changes are additive — no existing functionality is removed or rewritten.

### Alternatives Considered

- **Agent-type restriction for orchestrator** (use Plan subagent type): Too restrictive — orchestrator legitimately needs Read/Glob/Grep. Rejected.
- **Pattern-matching hook** (block edits to src/ paths): Too brittle — orchestrator finds ways around patterns accidentally. Rejected in favor of Haiku evaluation.
- **Full test suite in spec reviewer**: Too slow. Scoped to modified files and their dependents instead.
- **Separate integration reviewer stage**: Adds latency and another review loop. Folded into spec reviewer instead.
- **Devil's advocate as separate skill**: Requires someone to remember to invoke it. Embedded in writing-plans instead.
- **Per-task worktrees**: Overhead not justified for sequential tasks. Deferred — per-plan worktrees via existing skill are sufficient.
- **Periodic skill re-reads for context bloat**: Fragile — re-reading doesn't undo habits the model has developed mid-conversation. Rejected.

### Key Assumptions

- Haiku is fast and cheap enough that a PreToolUse hook calling it on every Edit/Write/Bash won't cause unacceptable latency
- File-based handoff between subagents works because subagents can read files via the Read tool
- The devil's advocate step adds meaningful value and doesn't just slow down plan writing with noise
- Implementer subagents will follow their mandatory checklist even when the plan's task steps don't mention it

## Design

### 1. Orchestrator Enforcement via Haiku Hook

A PreToolUse hook fires on Edit, Write, and Bash tool calls. The hook:

1. Reads `tool_name` and `tool_input` from stdin (JSON)
2. Sends them to Haiku with a prompt: "Is this a planning/brainstorming action (writing plans, reading code, exploring) or an implementation action (editing source code, running tests, building)?"
3. If implementation → returns `deny` with reason: "You are the orchestrator. Dispatch a subagent instead."
4. If planning → returns `allow`

This is structural enforcement that works regardless of context length. The orchestrator retains Read/Glob/Grep for inspection but cannot modify code or run implementation commands.

**Files:**
- Create: `hooks/orchestrator-guard` (hook script)
- Modify: `hooks/hooks.json` (add PreToolUse entry)

### 2. Mandatory Task Skeleton and Richer Plan High-Level Section

The `writing-plans` skill template gets two changes:

**Richer high-level section.** Every plan must include:
- Goal (one sentence)
- Approach and why this approach
- Alternatives considered and why rejected
- Key assumptions

**Mandatory task skeleton.** Every task must follow this structure:

```
### Task N: [Name]
**Files:** [create/modify with exact paths]
**Test:** [what test file, what it validates]
**Steps:**
1. Write failing test
2. Verify red
3. Implement
4. Verify green
5. Lint/typecheck
6. Commit
**Verification:** [exact command, expected output]
```

If a task genuinely doesn't need a test (e.g., config-only change), it must explicitly state why.

**Files:**
- Modify: `skills/writing-plans/SKILL.md`

### 3. Implementer-Side Safety Net

The implementer subagent prompt gets a mandatory checklist that applies regardless of what the plan says:

- Follow TDD (write failing test first, verify red, implement, verify green)
- Run lint/typecheck before committing
- Commit after each task with a descriptive message

This catches gaps in the plan at execution time. The implementer's self-review is not a replacement — both the checklist and the self-review are required.

**Files:**
- Modify: `skills/subagent-driven-development/implementer-prompt.md` (or equivalent)

### 4. Expanded Spec Reviewer

The spec reviewer prompt keeps its existing scope and adds system integrity checks:

1. **Run tests for modified files and their dependents** — not the full suite, but anything affected by the changes
2. **Run lint/typecheck** — catch broken imports, type mismatches across files
3. **Check blast radius** — for each modified file, find what imports from it. Check whether changed exports, renamed functions, or modified types broke consumers
4. **Verify shared contracts** — if the task touched types, interfaces, constants, or config that other code depends on, verify those dependents still work

The reviewer asks two questions:
- "Did they build what was asked?" (existing scope)
- "Did they leave the system in a working state?" (new scope)

**Files:**
- Modify: `skills/subagent-driven-development/spec-reviewer-prompt.md`

### 5. Devil's Advocate Inside Plan Writing

After the plan is written but before presenting to the user, the `writing-plans` skill dispatches a devil's advocate subagent. Three jobs:

1. **Challenge the approach** — question assumptions, propose simpler alternatives, identify risks. Works from the high-level section (goal, approach, alternatives, assumptions).
2. **Traceability check** — every requirement/decision in the high-level section must map to at least one task. Produces a coverage table showing what's covered and what's missing.
3. **Coherence check** — task dependencies make sense, nothing falls between cracks, tasks add up to the stated goal.

After the advocate returns:
- **Clear gaps** (requirement with no task) → auto-incorporated into the plan
- **Open challenges** (questionable assumptions, alternative approaches) → surfaced to the user with options: accept plan as-is / update plan / go back to brainstorming

**Files:**
- Create: `skills/writing-plans/advocate-prompt.md` (prompt template)
- Modify: `skills/writing-plans/SKILL.md` (add advocate step to flow)

### 6. File-Based Handoff Between Subagents

Subagents write detailed output (review feedback, implementation reports, test results) to files. They return only a short summary to the orchestrator:

- Task status (pass/fail)
- Files created/modified (paths only)
- Commit SHA (if committed)
- Issue count and severity (if reviewer)
- Path to detailed output file
- Blockers (if any)

The next subagent in the chain receives the file path and reads the full detail itself. The orchestrator routes based on summaries and passes file paths — it never holds detailed content.

**Files:**
- Modify: `skills/subagent-driven-development/SKILL.md` (orchestrator dispatch instructions)
- Modify: implementer and reviewer prompt templates (output format instructions)
