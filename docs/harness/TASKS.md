# Task Artifacts

Use durable task artifacts when the work needs more than one focused edit or may
span multiple agent runs.

Use `feature_list.json` as the high-level source of truth for feature scope,
status, dependencies, and completion evidence. Use `progress.md` for current
session continuity. Use `session-handoff.md` when another session may need to
resume the work.

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

## Session Lifecycle

Before ending work on a non-trivial task:

1. Update the active feature status and evidence in `feature_list.json`.
2. Update `progress.md` with current state, files changed, blockers, decisions,
   and verification evidence.
3. Update `session-handoff.md` with the recommended next step when work remains.
4. Leave the repo restartable from `./init.sh`, or document the failing command
   and exact next action.

## Acceptance Evidence

When marking a feature as "done":

1. Run the final dual-platform acceptance: `fvm dart run tool/harness.dart spec accept {spec-id} --maestro --platform all`
2. Promote the acceptance reports with `fvm dart run tool/harness.dart evidence promote {spec-id}`
3. Verify committed evidence with `fvm dart run tool/harness.dart evidence promote {spec-id} --check`
4. Run `fvm dart run tool/harness.dart review {spec-id}` for the read-only evaluator gate
5. Commit the reports to git
6. Update the evidence path in `feature_list.json` to point to the committed location

The evidence directory structure:
```
docs/harness/evidence/
├── README.md
    └── {spec-id}/
    ├── report.json          # Dual-platform summary report
    ├── report-ios.json      # iOS acceptance report
    └── report-android.json  # Android acceptance report
```

Promoted reports include `harness_metadata` with git sha, Flutter version,
Maestro version, policy path, and an acceptance summary. Do not hand-edit these
fields; regenerate them through the evidence command.
