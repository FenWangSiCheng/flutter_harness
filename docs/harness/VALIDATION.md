# Validation

Use `tool/harness.dart` as the stable entry point for local checks.

For a fresh agent session, prefer the walkinglabs lifecycle wrapper:

```bash
./init.sh
```

`init.sh` first resolves Flutter packages with `fvm flutter pub get`, then runs
bootstrap and the full harness check. The Flutter pub get preflight keeps fresh
CI runners from invoking the Dart harness before Flutter SDK packages are
discoverable. Use narrower commands below while iterating.

## Fast Checks

```bash
fvm dart run tool/harness.dart doctor
fvm dart run tool/harness.dart structure
fvm dart run tool/harness.dart coverage --check-only
```

`doctor` reports tool versions and generated-file state. `structure` runs the
structural guard tests that protect harness assumptions. `coverage --check-only`
rechecks an existing `coverage/lcov.info` report without rerunning tests.

## Full Check

```bash
fvm dart run tool/harness.dart check
```

The full check runs:

1. `fvm dart format --set-exit-if-changed lib test tool`
2. `fvm dart run tool/harness.dart structure`
3. `fvm flutter analyze`
4. `fvm dart run tool/harness.dart coverage`

## Coverage Gate

The coverage gate runs the Flutter test suite with coverage enabled:

```bash
fvm dart run tool/harness.dart coverage
```

The default minimum is 90% line coverage for non-UI logic. The gate excludes
files whose behavior is intentionally accepted by Maestro (`presentation/pages`,
`core/router`, `core/widgets`, `core/resources`, and `main.dart`) plus generated
files. Use `--min <percent>` for temporary local experiments, but keep the
checked-in default aligned with the current baseline.

## Test Policy

UI behavior is verified by Maestro flows, not Flutter widget tests. Keep
`kind: maestro` acceptance criteria for screens, controls, navigation, and
visible text. Use Flutter tests for logic, data mapping, repositories, BLoCs,
configuration, networking, and harness rules.

## Spec Evaluation (Required for Done)

Maestro flows are device-backed E2E checks and are intentionally outside the
default `check` command. However, dual-platform
`spec accept --maestro --platform all` is a required step in the Definition of
Done — do not mark a feature done without iOS and Android acceptance. If either
platform has no simulator or device available, record BLOCKED instead of done.
Keep these checks explicit until the project has stable device CI capacity.

Install Maestro, launch or install the `dev` app on a
simulator or device, then run:

```bash
fvm dart run tool/harness.dart eval
```

Platform-specific variants are available:

```bash
fvm dart run tool/harness.dart eval-all
fvm dart run tool/harness.dart eval-android
fvm dart run tool/harness.dart eval-ios
```

For feature acceptance evidence, prefer the spec command because it writes a
report under `build/harness/evidence/<spec-id>/`:

```bash
fvm dart run tool/harness.dart spec accept <id> --maestro --platform all
```

The dual-platform run writes `report-ios.json`, `report-android.json`, and a
summary `report.json`. Copy all three files into
`docs/harness/evidence/<spec-id>/` before marking the feature done.

The current flows live under `.maestro/android/` and `.maestro/ios/`, and
map to the human-readable specs in `docs/harness/specs/`.

## UI Target Map

Specs add new UI targets in per-spec `ui-map.delta.yaml` files. The shared
`docs/harness/specs/ui-map.yaml` file is generated from deltas whose linked
features are past Gate A (`spec-approved`, `implementing`, `accepted`, or
`done`):

```bash
fvm dart run tool/harness.dart spec ui-map
```

`structure` verifies the generated file is current by running:

```bash
fvm dart run tool/harness.dart spec ui-map --check
```

## Bootstrap

```bash
fvm dart run tool/harness.dart bootstrap
```

Bootstrap runs dependency installation and code generation:

1. `fvm flutter pub get`
2. `fvm dart run build_runner build`

## Failure Triage

- Formatting failure: run `fvm dart format lib test tool`.
- Generated-code failure: run the bootstrap command.
- Coverage failure: inspect `coverage/lcov.info`, add non-UI tests, or adjust
  the documented exclusion only if the file is truly Maestro-owned UI surface.
- Structural failure: read `docs/harness/ARCHITECTURE.md` and fix the import or
  documented exception.
- Walkinglabs structural failure: check `AGENTS.md`, `feature_list.json`,
  `progress.md`, `init.sh`, and `session-handoff.md` before patching code.
- Test failure: prefer the narrowest failing test first, then the full suite.
- Analyzer failure: fix the warning instead of suppressing it unless there is a
  documented project reason.

## External Harness Audit

When the walkinglabs course repository is available locally, run its structural
validator against this repo:

```bash
node /path/to/learn-harness-engineering/skills/harness-creator/scripts/validate-harness.mjs --target .
```

In the Codex desktop bundled runtime, `node` may be available at:

```bash
/Users/wangsicheng/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node
```

## CI

GitHub Actions runs the same standard lifecycle command on pull requests and
pushes to `main` or `master`:

```bash
./init.sh
```

The workflow installs FVM, installs the configured Flutter SDK from
`.fvm/fvm_config.json`, resolves Flutter packages, and then runs the standard
startup path.

## Maestro CI

GitHub Actions also has a simulator-backed Maestro workflow:

```bash
.github/workflows/maestro.yml
```

The workflow runs on pull requests, pushes to `main` or `master`, and manual
dispatch. It does not build downloadable IPA, APK, or AAB artifacts. Instead it:

1. Installs Flutter, FVM, project dependencies, generated code, and Maestro.
2. Boots an iOS simulator and runs every `done` spec from `feature_list.json`
   with `fvm dart run tool/harness.dart spec accept <id> --maestro --platform ios`.
3. Boots an Android emulator and runs every `done` spec with
   `fvm dart run tool/harness.dart spec accept <id> --maestro --platform android`.

The harness command builds and installs the `dev` app variant on the running
simulator/emulator before each Maestro flow, so no signing certificates are
required.

Android emulator CI invokes `bash tool/ci_android_maestro.sh` from
`reactivecircus/android-emulator-runner`. Keep the loop and Python spec
discovery in that repository script because the action executes its inline
`script` input through `/usr/bin/sh`.

## Flutter Version

The local source of truth is `.fvm/fvm_config.json`. As of this harness update,
the project uses Flutter `3.44.0`.
