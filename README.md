# Flutter Harness Project

This repository is a demo Flutter application used to showcase a
repository-local AI coding harness. The app surface is intentionally modest; the
important part is the framework around it: instructions, durable state,
repeatable validation, architecture guards, feature specs, acceptance evidence,
runtime signals, CI, and project-local agent skills.

The harness turns a Flutter codebase into a workspace that an agent can enter,
inspect, validate, modify, and hand off without relying on hidden context. It is
designed as a reusable pattern for Flutter projects that need predictable agent
workflows instead of one-off prompt memory.

## Harness Framework Goals

- Keep repository knowledge on disk and make it the system of record.
- Give every agent session a standard startup path.
- Track feature scope, status, dependencies, blockers, and evidence explicitly.
- Enforce clean architecture boundaries with structural tests.
- Separate non-UI logic verification from device-backed UI acceptance.
- Require committed evidence for user-visible feature completion.
- Preserve session state so work can continue across agents and time.
- Encode repeated failures into docs, tests, tooling, or state artifacts.

## Start Here

| File | Purpose |
| --- | --- |
| [`AGENTS.md`](AGENTS.md) | Agent startup workflow, scope rules, verification commands, and Definition of Done. |
| [`docs/harness/README.md`](docs/harness/README.md) | Harness map and subsystem overview. |
| [`feature_list.json`](feature_list.json) | Feature status, dependencies, specs, and evidence. |
| [`progress.md`](progress.md) | Current session state, decisions, risks, touched files, and verification evidence. |
| [`session-handoff.md`](session-handoff.md) | Restart notes for the next session. |
| [`docs/harness/VALIDATION.md`](docs/harness/VALIDATION.md) | Local command reference and failure triage. |

For a fresh baseline:

```bash
./init.sh
```

`init.sh` resolves Flutter packages, runs bootstrap, and then runs the full
harness check. Use it when proving that the repository is restartable from the
standard lifecycle entrypoint.

## What The Harness Provides

### Durable Instructions

Root instructions stay short and route agents to deeper docs:

- [`AGENTS.md`](AGENTS.md) is the entry map.
- [`docs/harness/ARCHITECTURE.md`](docs/harness/ARCHITECTURE.md) defines layer
  rules.
- [`docs/harness/TASKS.md`](docs/harness/TASKS.md) defines how larger work is
  planned and handed off.
- [`docs/harness/SKILLS.md`](docs/harness/SKILLS.md) lists project-local Flutter
  and Dart skills.

### Feature State

Feature scope and completion evidence are tracked in
[`feature_list.json`](feature_list.json). Session continuity lives in
[`progress.md`](progress.md), with restart notes in
[`session-handoff.md`](session-handoff.md).

The working rule is one feature at a time. Do not mark a feature done until the
behavior, docs/state updates, verification, dual-platform Maestro evidence, and
committed reports are all present.

### Validation Runner

[`tool/harness.dart`](tool/harness.dart) is the stable command runner for local
checks:

```bash
# Inspect tools, generated files, docs, and skills
fvm dart run tool/harness.dart doctor

# Run structural guard tests
fvm dart run tool/harness.dart structure

# Resolve packages and regenerate committed generated files
fvm dart run tool/harness.dart bootstrap

# Run format, structure, analyzer, and coverage-gated tests
fvm dart run tool/harness.dart check

# Recheck an existing coverage report without rerunning tests
fvm dart run tool/harness.dart coverage --check-only
```

The default full check runs:

1. `fvm dart format --set-exit-if-changed lib test tool`
2. `fvm dart run tool/harness.dart structure`
3. `fvm flutter analyze`
4. `fvm dart run tool/harness.dart coverage`

### Structure Guards

[`test/harness/architecture_guard_test.dart`](test/harness/architecture_guard_test.dart)
protects harness assumptions, including:

- Required root lifecycle artifacts.
- Feature state and committed evidence alignment.
- Flutter clean architecture import boundaries.
- UI test policy.
- Generated canonical UI map freshness.
- Local skill availability.
- CI wiring for standard checks and Maestro acceptance.

### Coverage Gate

`tool/harness.dart coverage` runs Flutter tests with coverage and enforces the
default 90% line-coverage threshold for non-UI logic.

```bash
fvm dart run tool/harness.dart coverage
```

The gate intentionally excludes Maestro-owned UI shell files, generated files,
router/widgets/resources, and `main.dart`, so Flutter tests measure logic, data,
BLoC, networking, configuration, and harness behavior.

### Specs, UI Map, And Maestro

Human-readable specs live under [`docs/harness/specs/`](docs/harness/specs/).
Each UI spec can add targets through a `ui-map.delta.yaml`; the canonical target
map is generated at [`docs/harness/specs/ui-map.yaml`](docs/harness/specs/ui-map.yaml):

```bash
fvm dart run tool/harness.dart spec ui-map
fvm dart run tool/harness.dart spec ui-map --check
```

User-visible UI behavior is accepted through Maestro, not Flutter widget tests.
Before marking a feature done, run:

```bash
fvm dart run tool/harness.dart spec accept <spec-id> --maestro --platform all
```

The dual-platform run writes:

- `report-ios.json`
- `report-android.json`
- `report.json`

Copy those reports from `build/harness/evidence/<spec-id>/` into
`docs/harness/evidence/<spec-id>/`, then update `feature_list.json`. If either
iOS or Android is unavailable, record `BLOCKED` instead of marking the feature
done.

### CI

The repository has two harness-oriented GitHub Actions workflows:

- [`.github/workflows/harness.yml`](.github/workflows/harness.yml) runs
  `./init.sh`.
- [`.github/workflows/maestro.yml`](.github/workflows/maestro.yml) boots hosted
  iOS and Android simulators/emulators and runs every `done` spec through
  Maestro.

The Maestro workflow installs and runs the dev app on simulators. It does not
produce IPA, APK, or AAB release artifacts and does not require signing
certificates.

### Runtime Signals

App-side harness logging lives in [`lib/core/harness/`](lib/core/harness/). It
emits searchable `[harness]` JSON-style debug events so agents can inspect
startup and networking behavior from logs. See
[`docs/harness/OPERABILITY.md`](docs/harness/OPERABILITY.md) for the event
catalog and troubleshooting notes.

## Flutter App Surface

The app follows a feature-first clean architecture layout:

```text
lib/features/<feature>/
  domain/
    entities/
    repositories/
    usecase/
  data/
    datasource/
    models/
    repositories/
  presentation/
    bloc/
    pages/
    widgets/
```

Request flow:

```text
UI -> Event -> BLoC -> UseCase -> Repository -> DataSource -> API/mock data
```

Response flow:

```text
API/mock data -> Model -> Entity -> UseCase -> BLoC -> State -> UI
```

Current stack:

- Flutter SDK `3.44.0`, managed by FVM.
- Dart SDK `>=3.9.2 <4.0.0`.
- Flavors: `dev`, `stg`, and `prod`.
- State management: `flutter_bloc`.
- Routing: `go_router`.
- Networking: Dio with mock API support.
- Dependency injection: `get_it` and `injectable`.
- Generated Dart files are committed and must stay synchronized after annotation
  changes.

## Run The App

```bash
# Development flavor with local mock API support
fvm flutter run --flavor dev --dart-define-from-file=dart_defines/dev.json

# Staging flavor
fvm flutter run --flavor stg --dart-define-from-file=dart_defines/stg.json

# Production flavor
fvm flutter run --flavor prod --dart-define-from-file=dart_defines/prod.json
```

## Build

```bash
# Development APK
fvm flutter build apk --flavor dev --dart-define-from-file=dart_defines/dev.json

# Staging APK
fvm flutter build apk --flavor stg --dart-define-from-file=dart_defines/stg.json

# Production APK
fvm flutter build apk --flavor prod --dart-define-from-file=dart_defines/prod.json

# Production iOS
fvm flutter build ios --flavor prod --dart-define-from-file=dart_defines/prod.json
```

## Harness References

- [OpenAI harness engineering field report](https://openai.com/index/harness-engineering/)
- [walkinglabs learn-harness-engineering](https://github.com/walkinglabs/learn-harness-engineering)
- [walkinglabs awesome-harness-engineering](https://github.com/walkinglabs/awesome-harness-engineering)

## License

Licensed under the Apache License, Version 2.0. See [`LICENSE`](LICENSE) for the
full license text.
