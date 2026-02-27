# Orchestration Improvements Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Harden the multi-agent orchestration workflow with structural enforcement, mandatory verification steps, expanded review scope, plan-time critical thinking, and lean context management.

**Approach:** Additive changes to existing skill files, prompt templates, and hooks. No existing functionality is removed. Changes target: writing-plans (plan template + devil's advocate), subagent-driven-development (implementer checklist, spec reviewer scope, file-based handoff, orchestrator restrictions), and hooks (Haiku-powered PreToolUse guard).

**Alternatives considered:** See `docs/plans/2026-02-27-orchestration-improvements-design.md` for full alternatives analysis.

**Key assumptions:** Haiku is fast enough for PreToolUse evaluation; file-based handoff works because subagents have Read tool access; devil's advocate adds value without excessive noise.

**Tech Stack:** Bash (hook script), Anthropic API via curl (Haiku calls), Markdown (skill files)

---

### Task 1: Expand writing-plans Plan Header Template

Add richer high-level section to the plan document header template in the writing-plans skill.

**Files:**
- Modify: `skills/writing-plans/SKILL.md:29-45`

**Test:** This is a markdown template change. Verification is reading the file and confirming the template includes the required sections.

**Step 1: Modify the Plan Document Header section**

Replace the existing header template (lines 29-45) with:

````markdown
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
````

**Step 2: Verify the change**

Read `skills/writing-plans/SKILL.md` and confirm:
- Header template includes Goal, Approach (with "why"), Alternatives considered, Key assumptions, Tech Stack
- The old "Architecture" field is replaced by the more specific "Approach" and "Alternatives considered"

**Step 3: Commit**

```bash
git add skills/writing-plans/SKILL.md
git commit -m "Expand plan header template with approach, alternatives, and assumptions"
```

---

### Task 2: Add Mandatory Task Skeleton to writing-plans

Replace the existing flexible task structure with a mandatory skeleton that enforces TDD, lint, and commit steps in every task.

**Files:**
- Modify: `skills/writing-plans/SKILL.md:47-88`

**Test:** Verification is reading the file and confirming the mandatory skeleton is present with all required sections.

**Step 1: Replace the Task Structure section**

Replace the existing Task Structure section (lines 47-88) with:

````markdown
## Mandatory Task Structure

Every task MUST follow this skeleton. The plan author fills in specifics, but the structure is non-negotiable.

```markdown
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
```

**What MUST be in every task:**
- **Test:** Either a test file and what it validates, or an explicit "No test because" with a reason
- **Lint/typecheck step:** Always present. The project's lint and typecheck commands.
- **Commit step:** Always present. Specific files to add and a descriptive commit message.

These are not optional. If a plan author omits them, the plan is incomplete.
````

**Step 2: Verify the change**

Read `skills/writing-plans/SKILL.md` and confirm:
- Section is now titled "Mandatory Task Structure"
- Template includes Test field with "No test because" escape hatch
- Steps include lint/typecheck (Step 5) and commit (Step 6)
- "What MUST be in every task" section documents the non-negotiable requirements

**Step 3: Commit**

```bash
git add skills/writing-plans/SKILL.md
git commit -m "Make task skeleton mandatory with required test, lint, and commit steps"
```

---

### Task 3: Create Devil's Advocate Prompt Template

Create the prompt template used to dispatch the devil's advocate subagent after plan writing.

**Files:**
- Create: `skills/writing-plans/advocate-prompt.md`

**Test:** Verification is reading the file and confirming it covers all three jobs: challenge approach, traceability, coherence.

**Step 1: Create the advocate prompt template**

```markdown
# Plan Advocate Prompt Template

Use this template to dispatch a devil's advocate subagent after writing a plan but before presenting it to the user.

**Purpose:** Challenge the plan's approach, verify traceability from requirements to tasks, and check coherence across tasks.

```
Task tool (general-purpose):
  description: "Challenge plan for [feature name]"
  prompt: |
    You are the devil's advocate for an implementation plan. Your job is to find
    problems BEFORE implementation begins, when they are cheapest to fix.

    ## The Plan

    [FULL TEXT of the plan document]

    ## The Design/Requirements

    [FULL TEXT of the design document or requirements that led to this plan]

    ## Your Three Jobs

    ### 1. Challenge the Approach

    Read the plan's Goal, Approach, Alternatives, and Assumptions sections.

    Ask yourself:
    - Are the assumptions stated? Could any be wrong?
    - Is there a simpler approach that was overlooked?
    - Are the rejected alternatives actually better for reasons not considered?
    - What risks does this approach carry?
    - What happens if an assumption turns out to be false?

    Report challenges as:
    - **Assumption risk:** [assumption] — what if [alternative reality]?
    - **Simpler alternative:** [description] — why it might be better
    - **Unaddressed risk:** [risk] — what could go wrong

    ### 2. Traceability Check

    Every requirement or architectural decision in the high-level section must
    map to at least one task. Produce a coverage table:

    | Requirement/Decision | Covered by Task | Status |
    |---|---|---|
    | [requirement from goal/approach] | Task N | ✅ Covered |
    | [requirement from goal/approach] | ??? | ❌ NOT COVERED |

    If a requirement has no corresponding task, that is a gap.

    ### 3. Coherence Check

    Read the task list as a whole:
    - Do the tasks add up to the stated goal? Is anything missing between tasks?
    - Are task dependencies correct? Does Task 3 assume something Task 4 creates?
    - Are there shared resources (types, config, interfaces) that multiple tasks
      touch without coordination?
    - Does the task ordering make sense?

    ## Output Format

    ### Auto-Fix (clear gaps the plan author should incorporate)
    - [Gap]: Add Task N+1 to cover [missing requirement]
    - [Gap]: Task N is missing [step] for [requirement]

    ### Open Challenges (surface to user for decision)
    - [Challenge]: [description and why it matters]
    - [Challenge]: [description and why it matters]

    ### Traceability Table
    [The coverage table from job 2]

    ### Coherence Issues
    - [Issue]: [description]

    If you find no issues in a category, say so explicitly. Do not invent
    problems. Only flag genuine concerns.
```
```

**Step 2: Verify the file**

Read `skills/writing-plans/advocate-prompt.md` and confirm:
- Prompt template covers all three jobs (challenge, traceability, coherence)
- Output is split into auto-fix items and open challenges for user decision
- Traceability table format is clear
- Instructions say not to invent problems

**Step 3: Commit**

```bash
git add skills/writing-plans/advocate-prompt.md
git commit -m "Add devil's advocate prompt template for plan challenge step"
```

---

### Task 4: Integrate Devil's Advocate Step into writing-plans Flow

Add the advocate dispatch step to the writing-plans skill, between plan writing and user presentation.

**Files:**
- Modify: `skills/writing-plans/SKILL.md:90-117`

**Test:** Verification is reading the file and confirming the advocate step is present in the flow and the execution handoff is updated.

**Step 1: Add advocate section before Execution Handoff**

Insert a new section between "Remember" (ends ~line 95) and "Execution Handoff" (starts ~line 97):

```markdown
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
```

**Step 2: Verify the change**

Read `skills/writing-plans/SKILL.md` and confirm:
- Advocate section exists between Remember and Execution Handoff
- Process includes auto-fix, open challenges, and three user options
- "Do NOT skip" instruction is present

**Step 3: Commit**

```bash
git add skills/writing-plans/SKILL.md
git commit -m "Integrate devil's advocate challenge step into plan writing flow"
```

---

### Task 5: Add Mandatory Checklist to Implementer Prompt

Add a non-negotiable checklist to the implementer subagent prompt that applies regardless of what the plan says.

**Files:**
- Modify: `skills/subagent-driven-development/implementer-prompt.md:29-37`

**Test:** Verification is reading the file and confirming the mandatory checklist is present and positioned before "Your Job".

**Step 1: Add mandatory checklist section**

Insert before the existing "Your Job" section (line 29), after "Before You Begin":

```markdown
    ## Mandatory Checklist (Non-Negotiable)

    Regardless of what the plan's task steps say, you MUST:

    1. **Follow TDD:** Write a failing test FIRST. Verify it fails. Then implement.
       Verify it passes. If the plan doesn't specify a test, write one yourself
       that validates the task's core behavior.
    2. **Run lint/typecheck:** Before committing, run the project's lint and
       typecheck commands. Fix any errors. If you don't know the project's
       commands, check package.json, Makefile, or similar config files.
    3. **Commit:** After the task passes tests and lint/typecheck, commit with
       a descriptive message. Include specific files, not `git add -A`.

    These apply even if the plan's steps don't mention them. The plan may omit
    them by accident — you don't.
```

**Step 2: Update "Your Job" section**

Replace the existing "Your Job" list (lines 31-36) to reference the checklist:

```markdown
    ## Your Job

    Once you're clear on requirements:
    1. Follow the Mandatory Checklist above (TDD, lint, commit)
    2. Implement exactly what the task specifies
    3. Self-review (see below)
    4. Report back
```

**Step 3: Verify the change**

Read `skills/subagent-driven-development/implementer-prompt.md` and confirm:
- Mandatory Checklist section exists before "Your Job"
- Three items: TDD, lint/typecheck, commit
- "Your Job" references the checklist
- Checklist says it applies even if plan doesn't mention these steps

**Step 4: Commit**

```bash
git add skills/subagent-driven-development/implementer-prompt.md
git commit -m "Add mandatory TDD/lint/commit checklist to implementer prompt"
```

---

### Task 6: Add File-Based Output to Implementer Prompt

Update the implementer's report format to write detailed output to a file and return only a summary.

**Files:**
- Modify: `skills/subagent-driven-development/implementer-prompt.md:70-78`

**Test:** Verification is reading the file and confirming the report format specifies file output + summary return.

**Step 1: Replace the Report Format section**

Replace the existing "Report Format" section (lines 70-78) with:

```markdown
    ## Report Format

    When done, write your detailed report to a file and return a summary.

    **Step 1: Write detailed report to file**

    Write to `.superpowers/reports/task-N-implementation.md`:
    - What you implemented (with file:line references)
    - What you tested and full test output
    - Files changed (with descriptions)
    - Self-review findings and what you fixed
    - Any issues or concerns

    **Step 2: Return summary to orchestrator**

    Your return message should be SHORT (under 10 lines):
    - Status: DONE or BLOCKED
    - Files created/modified (paths only)
    - Commit SHA
    - Test result (X/Y passing)
    - Blockers (if any)
    - Report path: `.superpowers/reports/task-N-implementation.md`

    The orchestrator makes routing decisions from your summary.
    The next reviewer reads your detailed report from the file.
```

**Step 2: Verify the change**

Read `skills/subagent-driven-development/implementer-prompt.md` and confirm:
- Report format has two steps: write to file, return summary
- File path uses `.superpowers/reports/` directory
- Summary is explicitly limited to under 10 lines
- Summary includes: status, files, commit SHA, test result, blockers, report path

**Step 3: Commit**

```bash
git add skills/subagent-driven-development/implementer-prompt.md
git commit -m "Switch implementer report to file-based output with summary return"
```

---

### Task 7: Expand Spec Reviewer with System Integrity Checks

Add system integrity verification to the spec reviewer prompt while keeping existing spec compliance checks.

**Files:**
- Modify: `skills/subagent-driven-development/spec-reviewer-prompt.md`

**Test:** Verification is reading the file and confirming system integrity checks are present alongside existing spec compliance checks.

**Step 1: Replace the entire spec-reviewer-prompt.md content**

Replace with:

````markdown
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
````

**Step 2: Verify the change**

Read `skills/subagent-driven-development/spec-reviewer-prompt.md` and confirm:
- Two-part structure: Part 1 (Spec Compliance) and Part 2 (System Integrity)
- System integrity includes: run tests for modified files, lint/typecheck, blast radius, shared contracts
- Output uses file-based handoff (write to file, return summary)
- Reads implementer's detailed report from file

**Step 3: Commit**

```bash
git add skills/subagent-driven-development/spec-reviewer-prompt.md
git commit -m "Expand spec reviewer with system integrity checks and file-based output"
```

---

### Task 8: Update Code Quality Reviewer for File-Based Output

Update the code quality reviewer prompt to use file-based handoff consistent with the other prompts.

**Files:**
- Modify: `skills/subagent-driven-development/code-quality-reviewer-prompt.md`

**Test:** Verification is reading the file and confirming file-based output instructions are present.

**Step 1: Replace the entire code-quality-reviewer-prompt.md content**

Replace with:

```markdown
# Code Quality Reviewer Prompt Template

Use this template when dispatching a code quality reviewer subagent.

**Purpose:** Verify implementation is well-built (clean, tested, maintainable)

**Only dispatch after spec compliance review passes.**

```
Task tool (superpowers:code-reviewer):
  Use template at requesting-code-review/code-reviewer.md

  WHAT_WAS_IMPLEMENTED: [from implementer's SUMMARY]
  PLAN_OR_REQUIREMENTS: Task N from [plan-file]
  BASE_SHA: [commit before task]
  HEAD_SHA: [current commit]
  DESCRIPTION: [task summary]
  IMPLEMENTATION_REPORT: Read full report at [path to .superpowers/reports/task-N-implementation.md]
  SPEC_REVIEW_REPORT: Read spec review at [path to .superpowers/reports/task-N-spec-review.md]

  Write your detailed review to: .superpowers/reports/task-N-quality-review.md

  Return summary to orchestrator (under 10 lines):
  - Strengths (1-2 sentences)
  - Issues: [count] critical, [count] important, [count] minor
  - Assessment: Ready to merge / Needs fixes
  - Report path: .superpowers/reports/task-N-quality-review.md
```

**Code reviewer returns:** Summary with issue counts and verdict. Full review in report file.
```

**Step 2: Verify the change**

Read `skills/subagent-driven-development/code-quality-reviewer-prompt.md` and confirm:
- References implementer and spec review report files
- Writes its own review to file
- Returns summary under 10 lines
- Includes assessment verdict

**Step 3: Commit**

```bash
git add skills/subagent-driven-development/code-quality-reviewer-prompt.md
git commit -m "Update code quality reviewer for file-based handoff"
```

---

### Task 9: Update Subagent-Driven Development Orchestrator Instructions

Update the main skill file with orchestrator role restrictions and file-based handoff coordination instructions.

**Files:**
- Modify: `skills/subagent-driven-development/SKILL.md`

**Test:** Verification is reading the file and confirming orchestrator restrictions and file handoff instructions are present.

**Step 1: Add orchestrator role section after "The Process" diagram**

Insert after the process diagram (after line 83) and before "Prompt Templates" (line 85):

```markdown
## Orchestrator Role (HARD RULES)

You are the orchestrator. Your job is routing and coordination. You dispatch subagents, read their summaries, and decide what happens next.

**You MUST NOT:**
- Edit or write source code, test files, or configuration files
- Run tests, linters, typecheckers, or build commands
- Run any Bash command that modifies state (only read-only git commands are allowed)
- Fix issues yourself — dispatch a subagent to fix them

**You MAY:**
- Read files to understand context
- Use Glob/Grep to find files
- Run `git log`, `git status`, `git diff` (read-only git)
- Write to `docs/plans/` (plan files only)

**If you feel the urge to "just quickly fix" something, STOP. Dispatch a subagent.**

## File-Based Handoff

Subagents write detailed output to `.superpowers/reports/` and return short summaries.

**As orchestrator, you:**
1. Read the subagent's summary (under 10 lines) to make routing decisions
2. Pass the report file path to the next subagent in the chain
3. NEVER ask a subagent to repeat information that's already in a report file

**Report file naming:**
- `.superpowers/reports/task-N-implementation.md` — implementer's detailed report
- `.superpowers/reports/task-N-spec-review.md` — spec reviewer's detailed report
- `.superpowers/reports/task-N-quality-review.md` — code quality reviewer's report

**Before dispatching the first task**, create the reports directory:
```bash
mkdir -p .superpowers/reports
```
```

**Step 2: Update the Example Workflow to show file-based handoff**

Replace the example workflow section (lines 92-165) to reflect summaries instead of full reports:

```markdown
## Example Workflow

```
You: I'm using Subagent-Driven Development to execute this plan.

[Read plan file once: docs/plans/feature-plan.md]
[Extract all 5 tasks with full text and context]
[Create TodoWrite with all tasks]
[mkdir -p .superpowers/reports]

Task 1: Hook installation script

[Get Task 1 text and context (already extracted)]
[Dispatch implementation subagent with full task text + context]

Implementer returns summary:
  Status: DONE
  Files: src/install-hook.js, tests/install-hook.test.js
  Commit: abc1234
  Tests: 5/5 passing
  Report: .superpowers/reports/task-1-implementation.md

[Dispatch spec reviewer with task requirements + report path]
Spec reviewer returns:
  ✅ Spec compliant and system intact
  Report: .superpowers/reports/task-1-spec-review.md

[Dispatch code quality reviewer with SHAs + report paths]
Code reviewer returns:
  Strengths: Good test coverage, clean implementation
  Issues: 0 critical, 0 important, 0 minor
  Assessment: Ready to merge
  Report: .superpowers/reports/task-1-quality-review.md

[Mark Task 1 complete]

Task 2: Recovery modes

[Dispatch implementation subagent with full task text + context]

Implementer returns summary:
  Status: DONE
  Files: src/recovery.js, tests/recovery.test.js
  Commit: def5678
  Tests: 8/8 passing
  Report: .superpowers/reports/task-2-implementation.md

[Dispatch spec reviewer with task requirements + report path]
Spec reviewer returns:
  ❌ Issues: 1 spec issue, 0 integrity issues
  Report: .superpowers/reports/task-2-spec-review.md

[Dispatch implementer to fix — pass spec review report path]
Implementer returns summary:
  Status: DONE (fixes applied)
  Commit: ghi9012
  Report: .superpowers/reports/task-2-implementation-fix.md

[Re-dispatch spec reviewer]
Spec reviewer returns:
  ✅ Spec compliant and system intact

[Dispatch code quality reviewer]
...

[After all tasks]
[Dispatch final code-reviewer]
Done!
```
```

**Step 3: Verify the change**

Read `skills/subagent-driven-development/SKILL.md` and confirm:
- Orchestrator Role section with MUST NOT and MAY lists
- File-Based Handoff section with naming conventions
- Example workflow shows summaries, not full reports
- Report directory creation step

**Step 4: Commit**

```bash
git add skills/subagent-driven-development/SKILL.md
git commit -m "Add orchestrator restrictions and file-based handoff to subagent-driven-development"
```

---

### Task 10: Create Orchestrator Guard Hook Script

Create the Haiku-powered PreToolUse hook that prevents the orchestrator from doing implementation work.

**Files:**
- Create: `hooks/orchestrator-guard`
- Modify: `hooks/hooks.json`

**Test:** Create a test script that verifies the hook correctly classifies tool calls.
- Test file: `tests/claude-code/test-orchestrator-guard.sh`

**Step 1: Write a test script for the hook**

```bash
#!/usr/bin/env bash
# Test: orchestrator-guard hook
# Verifies the hook correctly classifies planning vs implementation actions
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK_DIR="$(cd "$SCRIPT_DIR/../../hooks" && pwd)"

echo "=== Test: orchestrator-guard hook ==="
echo ""

# Helper: call the hook with simulated input and check the decision
test_hook() {
    local test_name="$1"
    local input_json="$2"
    local expected_decision="$3"

    local output
    output=$(echo "$input_json" | bash "$HOOK_DIR/orchestrator-guard" 2>/dev/null) || true

    local decision
    decision=$(echo "$output" | jq -r '.hookSpecificOutput.permissionDecision // "allow"')

    if [ "$decision" = "$expected_decision" ]; then
        echo "  [PASS] $test_name (got: $decision)"
        return 0
    else
        echo "  [FAIL] $test_name"
        echo "  Expected: $expected_decision"
        echo "  Got: $decision"
        echo "  Output: $output"
        return 1
    fi
}

# Test 1: Writing to a plan file should be allowed
echo "Test 1: Plan file write is allowed..."
test_hook "Write to docs/plans/" \
    '{"tool_name":"Write","tool_input":{"file_path":"docs/plans/2026-01-01-feature.md","content":"# Plan"}}' \
    "allow"

# Test 2: Editing source code should be denied
echo "Test 2: Source code edit is denied..."
test_hook "Edit src/ file" \
    '{"tool_name":"Edit","tool_input":{"file_path":"src/components/Button.tsx","old_string":"old","new_string":"new"}}' \
    "deny"

# Test 3: Running git status should be allowed
echo "Test 3: Read-only git is allowed..."
test_hook "git status" \
    '{"tool_name":"Bash","tool_input":{"command":"git status"}}' \
    "allow"

# Test 4: Running tests should be denied
echo "Test 4: Running tests is denied..."
test_hook "npm test" \
    '{"tool_name":"Bash","tool_input":{"command":"npm test"}}' \
    "deny"

echo ""
echo "=== All orchestrator-guard tests passed ==="
```

**Step 2: Run the test to verify it fails**

Run: `bash tests/claude-code/test-orchestrator-guard.sh`
Expected: FAIL (hook script doesn't exist yet)

**Step 3: Create the hook script**

Create `hooks/orchestrator-guard`:

```bash
#!/usr/bin/env bash
# PreToolUse hook that evaluates whether a tool call is planning or implementation.
# Uses Haiku to classify the action. Blocks implementation actions in orchestrator mode.
set -euo pipefail

# Read tool call context from stdin
INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')
TOOL_INPUT=$(echo "$INPUT" | jq -c '.tool_input')

# Check if ANTHROPIC_API_KEY is set
if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
    # No API key — allow by default (hook is opt-in)
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
    exit 0
fi

# Build the classification prompt
PROMPT="You are classifying a tool call as either PLANNING or IMPLEMENTATION.

PLANNING actions (ALLOW): writing/editing plan documents (docs/plans/), reading code to understand it, running read-only git commands (git log, git status, git diff), searching files with grep/glob, creating directories for reports.

IMPLEMENTATION actions (DENY): editing source code, editing test files, editing config files (not plan docs), running tests, running linters, running build commands, running any command that modifies project state.

Tool: $TOOL_NAME
Input: $TOOL_INPUT

Respond with exactly one word: PLANNING or IMPLEMENTATION"

# Call Haiku for classification
RESPONSE=$(curl -s --max-time 10 \
    https://api.anthropic.com/v1/messages \
    -H "content-type: application/json" \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -d "$(jq -n \
        --arg prompt "$PROMPT" \
        '{
            model: "claude-haiku-4-5-20251001",
            max_tokens: 10,
            messages: [{role: "user", content: $prompt}]
        }'
    )")

CLASSIFICATION=$(echo "$RESPONSE" | jq -r '.content[0].text // "PLANNING"' | tr -d '[:space:]')

if [ "$CLASSIFICATION" = "IMPLEMENTATION" ]; then
    REASON="You are the orchestrator. You MUST NOT do implementation work directly. Dispatch a subagent instead. Tool blocked: $TOOL_NAME"
    jq -n \
        --arg reason "$REASON" \
        '{
            hookSpecificOutput: {
                hookEventName: "PreToolUse",
                permissionDecision: "deny",
                permissionDecisionReason: $reason
            }
        }'
else
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
fi
```

Make executable: `chmod +x hooks/orchestrator-guard`

**Step 4: Run the test to verify it passes**

Run: `bash tests/claude-code/test-orchestrator-guard.sh`
Expected: PASS (all 4 tests)

Note: This test requires `ANTHROPIC_API_KEY` to be set. If not set, the hook allows everything by default and tests will need adjustment.

**Step 5: Update hooks.json**

Add PreToolUse entry to `hooks/hooks.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume|clear|compact",
        "hooks": [
          {
            "type": "command",
            "command": "'${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd' session-start",
            "async": false
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Edit|Write|Bash",
        "hooks": [
          {
            "type": "command",
            "command": "'${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd' orchestrator-guard",
            "async": false
          }
        ]
      }
    ]
  }
}
```

**Step 6: Verify hooks.json is valid JSON**

Run: `cat hooks/hooks.json | jq .`
Expected: Valid JSON output with both SessionStart and PreToolUse entries

**Step 7: Commit**

```bash
git add hooks/orchestrator-guard hooks/hooks.json tests/claude-code/test-orchestrator-guard.sh
git commit -m "Add Haiku-powered PreToolUse hook to enforce orchestrator role"
```
