# Agent Map

This repository is a Flutter harness project. Treat the repo as the system of
record: prefer checked-in docs, scripts, tests, generated artifacts, and local
logs over outside memory.

## Start Here

- Project map: `docs/harness/README.md`
- Architecture rules: `docs/harness/ARCHITECTURE.md`
- Validation commands: `docs/harness/VALIDATION.md`
- Quality ledger: `docs/harness/QUALITY.md`
- Operating notes: `docs/harness/OPERABILITY.md`
- Active task pattern: `docs/harness/TASKS.md`

## Working Loop

1. Read the relevant harness docs before editing.
2. Make narrow changes that follow the existing feature-first structure.
3. Run the smallest meaningful check while iterating.
4. Run `fvm dart run tool/harness.dart check` before handing off broad changes.
5. Update harness docs when a new rule, workflow, or repeated failure appears.

## Flutter Commands

- Bootstrap: `fvm dart run tool/harness.dart bootstrap`
- Doctor: `fvm dart run tool/harness.dart doctor`
- Structure guard: `fvm dart run tool/harness.dart structure`
- Full check: `fvm dart run tool/harness.dart check`
- App run: `fvm flutter run --flavor dev --dart-define-from-file=dart_defines/dev.json`

## Rules That Matter

- Keep domain code independent from data and presentation.
- Keep data code independent from presentation.
- Keep generated files synchronized after changing annotations.
- Use `AppConfig` for environment behavior; avoid ad hoc flavor checks.
- Add or update tests with user-visible behavior, data mapping, routing, and
  harness rules.
- If a failure points to missing context, improve the harness instead of only
  patching the symptom.
