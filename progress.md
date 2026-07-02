# Session Progress Log

## Current State

**Last Updated:** 2026-07-02 CST
**Active Feature:** feat-004 Home todo list (done)
**Current Activity:** Harness simplification pass - consolidated eval commands, policy-driven structure tests, trimmed redundant evidence.

## Status

### What's Done

- [x] Added a Home todo list UI with task input, add button, active/completed counts, empty state, completion checkbox, and delete action.
- [x] Reworked Home todo into full feature-first architecture with domain entities/repository/use cases, data model/local datasource/repository implementation, and presentation BLoC.
- [x] Registered Home todo dependencies with injectable and regenerated `lib/core/injection/injection.config.dart`.
- [x] Added Home todo unit tests for domain, data, repository, use cases, events, state, and BLoC behavior.
- [x] Added stable semantics identifiers for the Home todo page and controls.
- [x] Added harness spec `docs/harness/specs/home-todolist/`.
- [x] Added iOS and Android Maestro flows for adding, completing, deleting, and returning to the empty state.
- [x] Regenerated `docs/harness/specs/ui-map.yaml` with Home todo targets.
- [x] Updated `docs/harness/policy.yaml` and `docs/harness/OPERABILITY.md` with Home todo flow events.
- [x] Started the `Pixel_9a` Android emulator and reran dual-platform acceptance.
- [x] Promoted Home todo acceptance evidence under `docs/harness/evidence/home-todolist/`.
- [x] `fvm dart run tool/harness.dart review home-todolist` reports PASS.
- [x] Simplified `tool/harness.dart` command construction by centralizing FVM/Dart/Flutter command helpers, format targets, dev build constants, Maestro flow path construction, and pretty JSON encoding.
- [x] Simplified acceptance verdict aggregation by normalizing verdicts once before applying the precedence order.
- [x] Updated harness structure guards so they assert the runner's command helpers and Maestro target routing instead of brittle pre-refactor array literals.
- [x] Split reusable harness support types into `tool/harness_support.dart`, reducing `tool/harness.dart` to command orchestration plus workflow logic.
- [x] Added the support file to the harness README, required-files policy, and structure guards so the repository map matches the runner layout.
- [x] Centralized `feature_list.json` and acceptance-file state access in `HarnessStateStore`, removing direct feature/spec state helpers from `tool/harness.dart`.
- [x] Moved canonical UI-map generation and YAML scalar formatting into `HarnessUiMapGenerator`, leaving `tool/harness.dart` to coordinate the `spec ui-map` command.
- [x] Consolidated four eval/eval-all/eval-ios/eval-android commands into a single `eval --platform` command.
- [x] Simplified the structure test to load required files and directories from `policy.yaml` instead of hardcoded paths.
- [x] Trimmed redundant verification evidence from `progress.md` and `session-handoff.md`.

### What's Next

1. Pick the next app feature, or refine Home todo persistence if desired.
2. Keep Android SDK `platform-tools` on PATH when running local acceptance commands that call `adb` directly.

## Blockers / Risks

- [ ] Flutter reports `native_flutter_proxy` and `flutter_inappwebview_ios` do not support iOS Swift Package Manager yet; the warning says this will become an error in a future Flutter release.
- [ ] Android build emits future-deprecation warnings for Gradle 8.7.0, Android Gradle Plugin 8.6.0, Kotlin 2.1.0, and Kotlin Gradle Plugin usage.

## Decisions Made

- **Full architecture for Home**: The todo feature now uses domain/data/presentation layers even though persistence is currently in-memory.
- **Maestro owns UI verification**: No widget test was added because this harness reserves UI behavior for Maestro flows.
- **Android SDK PATH**: Local shell PATH did not include `adb`; acceptance passed when run with `~/Library/Android/sdk/platform-tools` and `~/Library/Android/sdk/emulator` prepended.

## Files Modified This Session

- `lib/features/home/domain/entities/todo.dart` - Added Home todo domain entity.
- `lib/features/home/domain/repositories/todo_repository.dart` - Added Home todo repository contract.
- `lib/features/home/domain/usecase/*.dart` - Added Home todo use cases.
- `lib/features/home/data/datasource/todo_local_data_source.dart` - Added in-memory local data source.
- `lib/features/home/data/models/todo_model.dart` - Added data model mapping to domain.
- `lib/features/home/data/repositories/todo_repository_impl.dart` - Added repository implementation.
- `lib/features/home/presentation/bloc/*.dart` - Added Home todo BLoC, events, and state.
- `lib/features/home/presentation/pages/home_page.dart` - Updated Home todo UI to render BLoC state and dispatch events.
- `test/features/home/` - Added unit coverage for Home domain, data, use cases, and BLoC behavior.
- `lib/core/injection/injection.config.dart` - Regenerated injectable registrations for Home todo dependencies.
- `feature_list.json` - Added `feat-004`, linked spec/evidence, and marked done.
- `docs/harness/specs/home-todolist/spec.md` - Added human-readable Home todo acceptance spec.
- `docs/harness/specs/home-todolist/acceptance.yaml` - Added machine-readable Maestro acceptance criterion.
- `docs/harness/specs/home-todolist/ui-map.delta.yaml` - Added Home todo UI targets.
- `docs/harness/specs/ui-map.yaml` - Regenerated canonical UI map.
- `.maestro/ios/home_todolist_flow.yaml` - Added iOS Home todo acceptance flow.
- `.maestro/android/home_todolist_flow.yaml` - Added Android Home todo acceptance flow.
- `docs/harness/evidence/home-todolist/report.json` - Promoted dual-platform acceptance report.
- `docs/harness/evidence/home-todolist/report-ios.json` - Promoted iOS acceptance report.
- `docs/harness/evidence/home-todolist/report-android.json` - Promoted Android acceptance report.
- `docs/harness/policy.yaml` - Added Home todo acceptance report events.
- `docs/harness/OPERABILITY.md` - Documented Home todo flow events.
- `tool/harness.dart` - Centralized command/path/JSON helpers, simplified verdict aggregation, and delegated feature/spec state access to `HarnessStateStore`.
- `tool/harness_support.dart` - Added shared state, UI-map generation, policy, command, and coverage support types for the harness runner.
- `test/harness/architecture_guard_test.dart` - Updated harness runner guards for the simplified helper-based command construction.
- `docs/harness/README.md` - Documented the new harness support file.
- `docs/harness/policy.yaml` - Added `tool/harness_support.dart` to required harness files.
- `progress.md` - Updated session status.
- `session-handoff.md` - Updated restart notes.

## Evidence of Completion

- [x] `fvm dart run tool/harness.dart spec ui-map` passes: generated 9 targets from 1 approved spec delta.
- [x] `fvm flutter test test/features/home` passes: 31/31 Home feature tests pass.
- [x] `fvm dart run tool/harness.dart check` passes: format clean, structure 23/23, analyzer clean, 185 coverage-gated tests pass; included coverage is 332/358 lines (92.74%) against the 90% threshold.
- [x] Dual-platform Maestro acceptance: `spec accept home-todolist --maestro --platform all` passes (iOS PASS, Android PASS).
- [x] `fvm dart run tool/harness.dart evidence promote home-todolist` and `--check` both pass.
- [x] `fvm dart run tool/harness.dart review home-todolist` passes.
