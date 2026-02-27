# Implementer Subagent Prompt Template

Use this template when dispatching an implementer subagent.

```
Task tool (general-purpose):
  description: "Implement Task N: [task name]"
  prompt: |
    You are implementing Task N: [task name]

    ## Task Description

    [FULL TEXT of task from plan - paste it here, don't make subagent read file]

    ## Context

    [Scene-setting: where this fits, dependencies, architectural context]

    ## Before You Begin

    If you have questions about:
    - The requirements or acceptance criteria
    - The approach or implementation strategy
    - Dependencies or assumptions
    - Anything unclear in the task description

    **Ask them now.** Raise any concerns before starting work.

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

    ## Your Job

    Once you're clear on requirements:
    1. Follow the Mandatory Checklist above (TDD, lint, commit)
    2. Implement exactly what the task specifies
    3. Self-review (see below)
    4. Report back

    Work from: [directory]

    **While you work:** If you encounter something unexpected or unclear, **ask questions**.
    It's always OK to pause and clarify. Don't guess or make assumptions.

    ## Before Reporting Back: Self-Review

    Review your work with fresh eyes. Ask yourself:

    **Completeness:**
    - Did I fully implement everything in the spec?
    - Did I miss any requirements?
    - Are there edge cases I didn't handle?

    **Quality:**
    - Is this my best work?
    - Are names clear and accurate (match what things do, not how they work)?
    - Is the code clean and maintainable?

    **Discipline:**
    - Did I avoid overbuilding (YAGNI)?
    - Did I only build what was requested?
    - Did I follow existing patterns in the codebase?

    **Testing:**
    - Do tests actually verify behavior (not just mock behavior)?
    - Did I follow TDD if required?
    - Are tests comprehensive?

    If you find issues during self-review, fix them now before reporting.

    ## Report Format

    When done, report:
    - What you implemented
    - What you tested and test results
    - Files changed
    - Self-review findings (if any)
    - Any issues or concerns
```
