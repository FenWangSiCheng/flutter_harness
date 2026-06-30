# Session Progress Log

## Current State

**Last Updated:** 2026-06-30 CST
**Active Feature:** None (harness maintenance; feat-001 through feat-003 are done)


## Status

### What's Done

- [x] feat-001 (Home Step Counter) is implemented and accepted.
  - `lib/features/home/presentation/bloc/` owns counter events, states, and transitions.
  - `HomePage` renders BLoC state and dispatches counter events.
  - `test/features/home/presentation/bloc/home_counter_bloc_test.dart` covers initial, increment, repeated increment, and reset behavior with 100% coverage.
  - `.maestro/ios/home_counter_flow.yaml` and `.maestro/android/home_counter_flow.yaml` are the Maestro E2E flows.
  - `fvm dart run tool/harness.dart spec accept home-counter --maestro` passes on iOS.
  - `docs/harness/evidence/home-counter/report.json` is committed acceptance evidence.
- [x] feat-002 (Home Counter Decrement) is implemented and done.
  - `docs/harness/specs/home-counter-decrement/` defines spec, acceptance.yaml, and ui-map delta.
  - Added `DecrementHomeCounter` event and `_onDecrement` handler with zero-floor guard.
  - `HomePage` renders `-1` button with `Semantics(identifier: 'home.counter.decrement')`.
  - `.maestro/{ios,android}/home_counter_decrement_flow.yaml` covers decrement-at-zero, decrement-to-1, decrement-to-0 scenarios.
  - `test/features/home/presentation/bloc/home_counter_bloc_test.dart` expanded with 3 new decrement tests (above zero, at zero, 1→0).
  - `fvm dart run tool/harness.dart spec accept home-counter-decrement --maestro --platform ios` reports PASS.
  - `docs/harness/evidence/home-counter-decrement/report.json` is committed acceptance evidence.
  - Fixed `tool/harness.dart` to pass `--platform` to Maestro CLI in both `eval` and `_specAccept`.
- [x] feat-003 (Home User Display) is implemented and done.
  - `docs/harness/specs/home-user-display/` defines spec, acceptance.yaml (6 criteria), and ui-map delta (5 new targets).
  - Created `HomeUserBloc`, `HomeUserEvent`, `HomeUserState` in `lib/features/home/presentation/bloc/`.
  - `HomeUserBloc` depends on `GetUserUseCase` (constructor injection), loads user1 on init.
  - `HomePage` refactored to `MultiBlocProvider` with `_HomeUserSection` and `_HomeCounterSection` widgets.
  - User card displays avatar (`Images.userAvatar`), name, email above the counter in a `ListView`.
  - `.maestro/{ios,android}/home_user_display_flow.yaml` verifies user card, counter, and cross-interaction.
  - `test/features/home/presentation/bloc/home_user_bloc_test.dart` passes 6 tests (initial, loaded, generic error, ApiException error, correct userId, multi-event).
  - `fvm dart run tool/harness.dart check` passes: format clean, structure 21/21, analyzer clean, coverage-gated tests pass.
- [x] Flutter harness provides repository docs, structural tests, a Dart command runner, and debug runtime events.
- [x] `tool/harness.dart` provides bootstrap, doctor, format, structure, test, check, eval, and spec commands.
- [x] `./init.sh` wraps bootstrap and check for session startup.
- [x] CI workflow (`.github/workflows/harness.yml`) runs `./init.sh` as the primary harness gate.
- [x] Official Flutter and Dart agent skills are installed under `.agents/skills`.
- [x] UI behavior is verified by Maestro flows; Flutter/Dart tests are for non-UI logic, data, BLoC, repository, configuration, and harness rules.
- [x] `test/harness/architecture_guard_test.dart` guards harness structure, feature state, spec evaluation workflow, architecture layer boundaries, UI test policy, canonical UI map coverage, and committed evidence alignment.
- [x] Harness maintenance tightened `spec accept` so skipped acceptance criteria cannot be reported as overall PASS.
- [x] `docs/harness/specs/ui-map.yaml` now exists as the generated canonical UI target map derived from approved spec deltas.
- [x] `tool/harness.dart spec ui-map` regenerates the canonical UI target map, and `spec ui-map --check` verifies it is current.
- [x] `home-user-display` acceptance now verifies stable user-card rendering instead of a transient loading indicator; iOS Maestro evidence was regenerated.
- [x] Harness acceptance now supports dual-platform Maestro runs with `fvm dart run tool/harness.dart spec accept <id> --maestro --platform all`, writing `report-ios.json`, `report-android.json`, and a summary `report.json`.
- [x] `tool/harness.dart coverage` gates non-UI logic line coverage at 90% while excluding Maestro-owned UI shell/page/router files and generated files.
- [x] `tool/harness.dart check` now runs the coverage gate instead of a plain `flutter test` pass.
- [x] Bootstrap uses `fvm dart run build_runner build`, removing the ignored `--delete-conflicting-outputs` option from the standard startup path.
- [x] `AppConfig` is now provided through the injectable module so build_runner no longer warns that `DioClient` depends on an unregistered type.
- [x] Direct Dio dependency was upgraded to `^5.10.0` with `pubspec.lock` updated to 5.10.0.
- [x] Dio 5.10's `DioExceptionType.transformTimeout` is mapped to `ApiException("Transform timeout")` with unit coverage.
- [x] Device-backed Maestro remains an explicit done-path gate and stays outside the default `check` command.
- [x] `.github/workflows/maestro.yml` runs iOS simulator and Android emulator Maestro acceptance in CI without producing IPA/APK/AAB release artifacts.

### What's Next

1. Watch the first GitHub Actions `Maestro` run and tune simulator/emulator image selection if the hosted runner inventory changes.
2. Extend structured events around user-flow success and failure states.
3. Track iOS Swift Package Manager support for `native_flutter_proxy` and `flutter_inappwebview_ios`.
4. Consider what feature to implement next (feat-004).

## Blockers / Risks

- [ ] Maestro eval depends on simulator/emulator state; CI now provisions hosted simulators/emulators in `.github/workflows/maestro.yml`, while local `check` remains device-free.
- [ ] UI-only specs require `--maestro` for PASS because they intentionally have no `kind: test` criteria.
- [ ] Flutter reports `native_flutter_proxy` and `flutter_inappwebview_ios` do not support iOS Swift Package Manager yet; the warning says this will become an error in a future Flutter release.
- [x] Existing committed Home evidence was regenerated with iOS and Android reports using `--platform all`.

## Decisions Made

- **Use root artifacts for harness compatibility**: Keep `feature_list.json`, `progress.md`, `init.sh`, and `session-handoff.md` as root state artifacts.
- **Keep `tool/harness.dart` as the authoritative Flutter command runner**: `init.sh` wraps the Dart runner instead of duplicating Flutter commands.
- **Keep official agent skills checked into the project**: Store Flutter and Dart skills in `.agents/skills`.
- **Keep Maestro eval outside the default check**: Device-backed E2E should be explicit.
- **Use Maestro for UI behavior instead of widget tests**: Screen rendering, visible text, controls, and navigation are accepted through `.maestro/` flows.
- **Device-backed Maestro checks remain explicit**: Keep `--maestro` flag requirement.
- **Added ANDROID_HOME/platform-tools auto-discovery**: `tool/harness.dart` automatically searches common Android SDK locations for adb.
- **Reuse GetUserUseCase in HomeUserBloc**: feat-003 reuses the existing user feature domain layer via constructor injection instead of duplicating data access.
- **Treat skipped acceptance as non-passing**: `spec accept` now reports overall `SKIPPED` if any acceptance criterion is skipped, preventing mixed test/maestro specs from passing without the UI gate.
- **Generate canonical UI targets from deltas**: Approved `ui-map.delta.yaml` targets are generated into `docs/harness/specs/ui-map.yaml` with `fvm dart run tool/harness.dart spec ui-map`; `structure` verifies the generated file is current.
- **Require dual-platform Maestro for done evidence**: Use `fvm dart run tool/harness.dart spec accept <id> --maestro --platform all` before marking a feature done; if either platform is unavailable, record BLOCKED instead of done.
- **Gate non-UI logic coverage in the default check**: `fvm dart run tool/harness.dart check` runs `tool/harness.dart coverage`, which tests with coverage and requires at least 90% included line coverage.
- **Keep Maestro outside the default check**: Device-backed Maestro remains required for done evidence but explicit because it depends on simulator/emulator state.
- **Use simulator CI for Maestro, not release artifacts**: `.github/workflows/maestro.yml` installs and runs the dev build on iOS and Android simulators, then invokes `spec accept`; it does not build or upload IPA/APK/AAB artifacts, so no signing certificates are required.

## Files Modified This Session

- `tool/harness.dart` - Treat skipped acceptance criteria as overall `SKIPPED`; add `spec ui-map [--check]` to generate or verify the canonical UI target map; add `eval-all` and `spec accept --platform all` dual-platform Maestro evidence.
- `tool/harness.dart` - Add `coverage [--check-only] [--min <percent>]`; wire `check` to coverage-gated tests; update bootstrap to `fvm dart run build_runner build`.
- `test/harness/architecture_guard_test.dart` - Added guards for generated canonical UI map freshness, committed evidence alignment, skipped acceptance handling, dual-platform Maestro harness support, the coverage gate, and current build_runner command.
- `lib/core/injection/injection.dart` and `lib/core/injection/injection.config.dart` - Register `AppConfig` through the injectable module to keep generated dependency checks clean.
- `lib/core/network/error/dio_error_handler.dart` and `test/core/network/error/dio_error_handler_test.dart` - Handle Dio 5.10 `transformTimeout`.
- `docs/harness/specs/ui-map.yaml` - Generated canonical UI target map from approved spec deltas.
- `docs/harness/specs/README.md` - Documented UI map generation instead of manual merge.
- `docs/harness/VALIDATION.md` - Documented `spec ui-map` and `spec ui-map --check`.
- `docs/harness/VALIDATION.md` - Documented the non-UI logic coverage gate, explicit Maestro device policy, and current bootstrap command.
- `docs/harness/README.md` - Updated harness readiness language to mention coverage-gated tests.
- `docs/harness/specs/home-user-display/spec.md` - Removed transient loading from the reviewable acceptance steps.
- `docs/harness/specs/home-user-display/acceptance.yaml` - Replaced the loading claim with stable user-card rendering.
- `docs/harness/specs/home-counter/ui-map.delta.yaml` - Quoted YAML descriptions that contain colons and updated generation instructions.
- `docs/harness/specs/home-counter-decrement/ui-map.delta.yaml` - Updated generation instructions.
- `docs/harness/specs/home-user-display/ui-map.delta.yaml` - Quoted YAML descriptions that contain colons and updated generation instructions.
- `docs/harness/evidence/home-user-display/report.json` - Regenerated iOS PASS evidence for the updated acceptance claim.
- `docs/harness/evidence/home-counter/report.json` - Regenerated dual-platform PASS summary evidence.
- `docs/harness/evidence/home-counter/report-ios.json` - Regenerated iOS PASS evidence.
- `docs/harness/evidence/home-counter/report-android.json` - Generated Android PASS evidence.
- `docs/harness/evidence/home-counter-decrement/report.json` - Regenerated dual-platform PASS summary evidence.
- `docs/harness/evidence/home-counter-decrement/report-ios.json` - Regenerated iOS PASS evidence.
- `docs/harness/evidence/home-counter-decrement/report-android.json` - Generated Android PASS evidence.
- `docs/harness/evidence/home-user-display/report.json` - Regenerated dual-platform PASS summary evidence.
- `docs/harness/evidence/home-user-display/report-ios.json` - Regenerated iOS PASS evidence.
- `docs/harness/evidence/home-user-display/report-android.json` - Generated Android PASS evidence.
- `docs/harness/evidence/README.md` - Documented dual-platform committed evidence files.
- `docs/harness/QUALITY.md` - Updated spec evaluation status and follow-ups.
- `AGENTS.md` - Updated Definition of Done to require iOS and Android Maestro acceptance.
- `AGENTS.md` and `CLAUDE.md` - Added the coverage gate to verification commands and synchronized the dual-platform Maestro done rule.
- `docs/harness/TASKS.md` - Updated final acceptance evidence workflow for dual-platform reports.
- `pubspec.yaml` and `pubspec.lock` - Upgraded Dio to 5.10.0.
- `init.sh` - Updated check label to mention coverage.
- `.github/workflows/maestro.yml` - Added iOS simulator and Android emulator Maestro CI for all done specs.
- `test/harness/architecture_guard_test.dart` - Guarded that Maestro CI runs simulator acceptance and avoids release artifact packaging.
- `docs/harness/README.md`, `docs/harness/VALIDATION.md`, and `docs/harness/QUALITY.md` - Documented simulator-backed Maestro CI.
- `progress.md` - Updated this session log.
- `session-handoff.md` - Updated restart notes and verification evidence.

## Evidence of Completion

- [x] `fvm dart run tool/harness.dart structure` passes: 21/21 harness structure tests pass.
- [x] `fvm dart run tool/harness.dart check` passes: format clean, structure 21/21, analyzer clean, coverage-gated tests pass.
- [x] `fvm dart run tool/harness.dart coverage --check-only` passes: 257/276 included lines, 93.12% non-UI logic coverage, threshold 90% before the DI cleanup.
- [x] `fvm flutter test test/core/network/error/dio_error_handler_test.dart` passes: 11/11 tests, including `transformTimeout`.
- [x] `fvm flutter test test/core/injection/injection_test.dart` passes: 8/8 tests after `AppConfig` module registration.
- [x] `fvm dart run tool/harness.dart spec ui-map` generated 9 targets from 3 approved spec deltas.
- [x] `fvm dart run tool/harness.dart spec ui-map --check` reports the generated UI map is current.
- [x] `fvm dart run tool/harness.dart spec accept home-counter` reports `SKIPPED` and exits non-zero without `--maestro`.
- [x] `fvm dart run tool/harness.dart spec accept home-counter --platform all` writes `report-ios.json`, `report-android.json`, and summary `report.json`; reports `SKIPPED` without `--maestro` as expected.
- [x] `fvm dart run tool/harness.dart spec accept home-counter --maestro --platform all` reports PASS on iOS and Android.
- [x] `fvm dart run tool/harness.dart spec accept home-counter-decrement --maestro --platform all` reports PASS on iOS and Android.
- [x] `fvm dart run tool/harness.dart spec accept home-user-display --maestro --platform all` reports PASS on iOS and Android.
- [x] HomeUserBloc tests: 6/6 pass (initial, loaded, generic error, ApiException, userId, multi-event).
- [x] feat-003 status is done in feature_list.json with complete evidence.
- [x] `fvm dart run tool/harness.dart spec accept home-user-display --maestro --platform ios` reports PASS on iOS (6/6 criteria) after the stable acceptance claim update.
- [x] `docs/harness/evidence/home-user-display/report.json` committed as acceptance evidence.
- [x] `fvm dart run tool/harness.dart check` passes after dual-platform harness and coverage-gate changes: format clean, structure 21/21, analyzer clean, 164 coverage-gated tests pass; included coverage is 259/279 lines (92.83%) against the 90% threshold.
- [x] `./init.sh` passes after bootstrap cleanup: build_runner uses `fvm dart run build_runner build`, writes 0 outputs on the final run, then check passes with 21/21 structure tests and 92.83% included coverage.
- [x] `fvm flutter pub outdated` reports direct dependencies are all up-to-date after the Dio upgrade; remaining newer versions are dev/transitive and constrained.
- [x] `fvm dart run tool/harness.dart structure` passes after adding simulator-backed Maestro CI: 22/22 harness structure tests pass.
- [x] `fvm dart run tool/harness.dart check` passes after adding `.github/workflows/maestro.yml`: format clean, structure 22/22, analyzer clean, 165 coverage-gated tests pass; included coverage remains 259/279 lines (92.83%) against the 90% threshold.
