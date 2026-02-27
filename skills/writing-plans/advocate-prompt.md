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
