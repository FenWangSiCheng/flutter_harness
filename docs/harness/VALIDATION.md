# Validation

Use `tool/harness.dart` as the stable entry point for local checks.

## Fast Checks

```bash
fvm dart run tool/harness.dart doctor
fvm dart run tool/harness.dart structure
```

`doctor` reports tool versions and generated-file state. `structure` runs the
structural guard tests that protect harness assumptions.

## Full Check

```bash
fvm dart run tool/harness.dart check
```

The full check runs:

1. `fvm dart format --set-exit-if-changed lib test tool`
2. `fvm dart run tool/harness.dart structure`
3. `fvm flutter analyze`
4. `fvm flutter test`

## Bootstrap

```bash
fvm dart run tool/harness.dart bootstrap
```

Bootstrap runs dependency installation and code generation:

1. `fvm flutter pub get`
2. `fvm flutter packages pub run build_runner build --delete-conflicting-outputs`

## Failure Triage

- Formatting failure: run `fvm dart format lib test tool`.
- Generated-code failure: run the bootstrap command.
- Structural failure: read `docs/harness/ARCHITECTURE.md` and fix the import or
  documented exception.
- Test failure: prefer the narrowest failing test first, then the full suite.
- Analyzer failure: fix the warning instead of suppressing it unless there is a
  documented project reason.

## Flutter Version

The local source of truth is `.fvm/fvm_config.json`. As of this harness update,
the project uses Flutter `3.44.0`.
