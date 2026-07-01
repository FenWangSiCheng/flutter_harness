# Harness Review Rubric

Use this rubric as a read-only evaluator gate after implementation and before
marking a feature done. The reviewer must inspect repository artifacts only:
the diff, `feature_list.json`, the spec, `acceptance.yaml`, committed evidence,
and harness logs or reports.

The builder should not grade its own work. Run this review from a fresh context
or by a separate evaluator whenever the implementation was produced in a prior
agent pass.

## Verdicts

- `PASS`: The committed evidence proves every current acceptance criterion, the
  feature status is coherent, and the repository remains mechanically
  verifiable.
- `NEEDS_WORK`: Any acceptance criterion is missing, skipped, stale, failing, or
  unsupported by committed evidence.

## Checks

- The spec is linked from exactly one feature in `feature_list.json`.
- The feature is not `done` unless dual-platform Maestro evidence reports PASS.
- `docs/harness/evidence/<spec-id>/report.json` is committed and matches the
  current `acceptance.yaml` criterion ids, claims, and kinds.
- The report metadata records the git sha, Flutter version, Maestro version,
  promotion command, policy path, and current acceptance summary.
- The report references the stable harness event names that an agent should
  inspect when debugging runtime behavior.
- No review decision relies on screenshots, logs, or generated build output that
  is absent from the repository or the generated evidence report.
