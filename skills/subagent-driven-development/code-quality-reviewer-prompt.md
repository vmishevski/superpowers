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

  Write your detailed review to: .superpowers/reports/task-N-quality-review.md

  Return summary to orchestrator (under 10 lines):
  - Issues: [count] critical, [count] important, [count] minor
  - Assessment: Ready to merge / Needs fixes
  - Report path: .superpowers/reports/task-N-quality-review.md
```

**Code reviewer returns:** Summary with issue counts and verdict. Full review in report file.

**Report structure:** Contains details for all identified issues. For each issue we have reasoning and pointers to file and lines. If no issues identified, write OK. 
