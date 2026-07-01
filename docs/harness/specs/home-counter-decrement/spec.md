# Spec: home-counter-decrement

## Goal

Verify that a user can decrement the step counter on the Home page with a -1
button, and that the counter never goes below zero.

## Preconditions

- Run the `dev` flavor.
- The Home tab is the default landing tab.
- The counter initially shows `Steps: 0`.

## Steps

1. Launch the app.
2. Open the Home tab.
3. Confirm the step counter shows `Steps: 0`.
4. Tap the `-1` button; the counter stays at `Steps: 0` (no negative values).
5. Tap the `+1` button twice; the counter shows `Steps: 2`.
6. Tap the `-1` button; the counter shows `Steps: 1`.
7. Tap the `-1` button again; the counter shows `Steps: 0`.
8. Tap the `-1` button once more; the counter stays at `Steps: 0`.

## Acceptance Criteria

Mirrored as machine-checkable items in `acceptance.yaml`.

## Translation Rules

- Prefer `semantics_identifier` from `docs/harness/specs/ui-map.yaml`.
- Do not invent labels or targets.
- If a step cannot be mapped to a known target, report `BLOCKED`.
