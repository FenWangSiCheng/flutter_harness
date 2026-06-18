# Task Artifacts

Use durable task artifacts when the work needs more than one focused edit or may
span multiple agent runs.

## Lightweight Plan

For small changes, keep the plan in the conversation and update the final answer
with checks run.

## Execution Plan

For larger work, create a markdown file under:

```text
docs/harness/tasks/active/<yyyy-mm-dd>-<slug>.md
```

Use this shape:

```md
# Task Title

## Goal

What user-visible or repository-visible outcome is required.

## Acceptance Criteria

- Concrete condition that can be checked.
- Command or test that proves the condition.

## Progress

- [ ] Step with status.

## Decisions

- Date-stamped decision and reason.

## Validation

- Command run and result.
```

Move completed plans to `docs/harness/tasks/completed/` if they remain useful.
