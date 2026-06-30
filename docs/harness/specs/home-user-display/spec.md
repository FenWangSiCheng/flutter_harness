# Spec: home-user-display

## Goal

Verify that the Home page loads and displays user1 (John Doe) information
— avatar, name, and email — above the step counter, reusing the existing
`GetUserUseCase`.

## Preconditions

- Run the `dev` flavor.
- The Home tab is the default landing tab.
- Mock data includes user1 (`id: "1"`, name: "John Doe", email: "john.doe@example.com").

## Steps

1. Launch the app.
2. Open the Home tab.
3. Confirm the user info card appears with avatar, "Name: John Doe", and
   "Email: john.doe@example.com".
4. Confirm the step counter is still visible below the user card and shows
   "Steps: 0".
5. Confirm the step counter controls (+1, -1, Reset) still work as before.

## Acceptance Criteria

Mirrored as machine-checkable items in `acceptance.yaml`.

## Translation Rules

- Prefer `semantics_identifier` from `docs/harness/specs/ui-map.yaml`.
- Do not invent labels or targets.
- If a step cannot be mapped to a known target, report `BLOCKED`.
