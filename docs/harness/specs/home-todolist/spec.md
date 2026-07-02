# Spec: home-todolist

## Goal

Verify that the Home tab exposes a local todo list where a user can add a task,
mark it complete, delete it, and return to the empty state.

## Preconditions

- Run the `dev` flavor.

## Steps

1. Launch the app.
2. Confirm the Home todo page is visible and starts empty.
3. Enter a task in the task field and add it.
4. Confirm the new task appears in the list.
5. Mark the task complete and confirm the completed count is visible.
6. Delete the task and confirm the empty state returns.

## Acceptance Criteria

Mirrored as machine-checkable items in `acceptance.yaml`.

## Translation Rules

- Prefer `semantics_identifier` from `docs/harness/specs/ui-map.yaml`.
- Do not invent labels or targets.
- If a step cannot be mapped to a known target, report `BLOCKED`.
