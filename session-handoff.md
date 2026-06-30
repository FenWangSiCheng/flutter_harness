# Session Handoff

## Current Objective

- Goal: Keep this Flutter repository as a harness project with three verified features (Home Step Counter, Decrement, User Display).
- Current status: feat-001 (Home Step Counter) is done. feat-002 (Home Counter Decrement) is done. feat-003 (Home User Display) is done — all code, tests, structure checks, and Maestro E2E pass with committed evidence.
- Harness rule update: done-path acceptance requires iOS and Android Maestro with `fvm dart run tool/harness.dart spec accept <id> --maestro --platform all`. Existing Home reports were regenerated with dual-platform evidence.
- CI startup update: fresh runners now run `fvm flutter pub get` before Dart harness entrypoints, ensuring Flutter SDK packages are discoverable before `tool/harness.dart` imports package dependencies.
- Android CI shell update: `reactivecircus/android-emulator-runner` runs its `script` under `/usr/bin/sh`, so Android Maestro CI uses `set -eu` rather than Bash-only `pipefail`.
- Branch / commit: Inspect with `git status --short` and `git log --oneline -1`.

## Completed

- [x] feat-001 (Home Step Counter) is implemented with BLoC pattern, Maestro E2E flows, and committed acceptance evidence.
- [x] feat-002 (Home Counter Decrement) is implemented and done.
  - `DecrementHomeCounter` event + `_onDecrement` handler with zero-floor guard (`if (state.steps > 0)`).
  - `HomePage` renders `-1` button alongside `+1` and `Reset` with `Semantics(identifier: 'home.counter.decrement')`.
  - 3 new BLoC tests: decrement above zero, decrement at zero (no emit), decrement 1→0. Total 7/7 pass.
  - `.maestro/{ios,android}/home_counter_decrement_flow.yaml` covers: decrement at zero stays 0, increment to 2 → decrement to 1 → decrement to 0 → decrement again stays 0.
  - `docs/harness/specs/home-counter-decrement/` defines spec, acceptance.yaml, and ui-map delta.
  - `fvm dart run tool/harness.dart spec accept home-counter-decrement --maestro --platform ios` reports PASS.
  - `docs/harness/evidence/home-counter-decrement/report.json` is committed acceptance evidence.
  - Fixed `tool/harness.dart` to pass `--platform` to Maestro CLI in both `eval` and `_specAccept` methods.
- [x] feat-003 (Home User Display) is implemented and done.
  - `docs/harness/specs/home-user-display/` defines spec, 6 acceptance criteria, 5 new UI targets.
  - `HomeUserBloc` depends on `GetUserUseCase` (constructor injection), loads user1 (John Doe) on init.
  - `HomePage` refactored to `MultiBlocProvider` with `_HomeUserSection` (avatar, name, email) above `_HomeCounterSection`.
  - `test/features/home/presentation/bloc/home_user_bloc_test.dart`: 6 tests (initial, loaded, generic error, ApiException, userId, multi-event).
  - `.maestro/{ios,android}/home_user_display_flow.yaml` verifies user card + counter cross-interaction.
  - `fvm dart run tool/harness.dart spec accept home-user-display --maestro --platform ios` reports PASS (6/6 criteria).
  - `docs/harness/evidence/home-user-display/report.json` is committed acceptance evidence.
- [x] Harness structure tests guard feature state, spec evaluation workflow, architecture boundaries, and UI test policy.
- [x] Harness structure tests also guard canonical UI map coverage and committed evidence alignment.
- [x] `tool/harness.dart` includes ANDROID_HOME/platform-tools auto-discovery.
- [x] `tool/harness.dart` reports overall `SKIPPED` when any acceptance criterion is skipped, so specs cannot pass without required Maestro gates.
- [x] `tool/harness.dart spec ui-map` regenerates `docs/harness/specs/ui-map.yaml` from approved spec deltas; `spec ui-map --check` verifies freshness.
- [x] `docs/harness/specs/ui-map.yaml` is the generated canonical UI target map, not a hand-edited merge file.
- [x] `tool/harness.dart` supports `eval-all` and `spec accept <id> --maestro --platform all`, writing per-platform reports plus a summary report.
- [x] `tool/harness.dart coverage` runs tests with coverage and gates non-UI logic line coverage at 90%.
- [x] `tool/harness.dart check` uses coverage-gated tests after format, structure, and analyzer.
- [x] Bootstrap uses `fvm dart run build_runner build`, avoiding the ignored legacy `--delete-conflicting-outputs` option.
- [x] `AppConfig` is provided through the injectable module so build_runner does not warn about `DioClient` depending on an unregistered type.
- [x] Dio was upgraded to 5.10.0.
- [x] Dio 5.10 `transformTimeout` errors are mapped and tested.
- [x] Device-backed Maestro remains explicit for feature done evidence and outside the default `check` command.
- [x] `.github/workflows/maestro.yml` runs iOS simulator and Android emulator Maestro acceptance in CI without producing release artifacts.
- [x] CI runs `./init.sh` as the primary harness gate.
- [x] `init.sh` and Maestro CI resolve Flutter dependencies before invoking `fvm dart run tool/harness.dart ...`, avoiding fresh-runner package resolution failures.
- [x] Android Maestro CI script uses POSIX-safe shell flags for the emulator-runner action.

## Verification Evidence

| Check | Command | Result | Notes |
|---|---|---|---|
| Harness doctor | `fvm dart run tool/harness.dart doctor` | Pass | Reports all tools and skills. |
| Structure guard | `fvm dart run tool/harness.dart structure` | Pass | 22/22 harness structure tests pass after adding Maestro CI guard. |
| Flutter harness check | `fvm dart run tool/harness.dart check` | Pass | Format clean, structure 22/22, analyzer clean, 165 coverage-gated tests pass; included coverage is 259/279 lines (92.83%). |
| UI map generation | `fvm dart run tool/harness.dart spec ui-map` | Pass | Generated 9 targets from 3 approved spec deltas. |
| UI map freshness | `fvm dart run tool/harness.dart spec ui-map --check` | Pass | Generated canonical map is current. |
| Coverage gate | `fvm dart run tool/harness.dart coverage --check-only` | Pass | 257/276 included lines, 93.12%, threshold 90%, before DI cleanup. |
| Dio error handler test | `fvm flutter test test/core/network/error/dio_error_handler_test.dart` | Pass | 11/11 tests, including `transformTimeout`. |
| Injection test | `fvm flutter test test/core/injection/injection_test.dart` | Pass | 8/8 tests after `AppConfig` module registration. |
| Dependency freshness | `fvm flutter pub outdated` | Pass | Direct dependencies are all up-to-date; remaining newer versions are dev/transitive and constrained. |
| Skipped acceptance guard | `fvm dart run tool/harness.dart spec accept home-counter` | Pass | Reports `SKIPPED` and exits non-zero without `--maestro`. |
| Dual-platform report shape | `fvm dart run tool/harness.dart spec accept home-counter --platform all` | Pass | Writes `report-ios.json`, `report-android.json`, and summary `report.json`; reports `SKIPPED` without `--maestro` as expected. |
| Home Counter dual-platform acceptance | `fvm dart run tool/harness.dart spec accept home-counter --maestro --platform all` | Pass | iOS and Android Maestro reports PASS. |
| Decrement dual-platform acceptance | `fvm dart run tool/harness.dart spec accept home-counter-decrement --maestro --platform all` | Pass | iOS and Android Maestro reports PASS. |
| Home User Display dual-platform acceptance | `fvm dart run tool/harness.dart spec accept home-user-display --maestro --platform all` | Pass | iOS and Android Maestro reports PASS. |
| Standard startup | `./init.sh` | Pass | Bootstrap completed without build_runner or injectable dependency warnings; full check passed with 92.83% included coverage. |
| Standard startup after CI preflight fix | `./init.sh` | Pass | `fvm flutter pub get` runs before Dart harness bootstrap; full check passed with 165 coverage-gated tests and 92.83% included coverage. |
| Structure guard after CI preflight fix | `fvm dart run tool/harness.dart structure` | Pass | 22/22 harness structure tests pass. |
| Android emulator runner shell fix | GitHub Actions Android Maestro rerun | Investigated | After dependency preflight succeeded, Android reached emulator startup and failed because `/usr/bin/sh` does not support `pipefail`; workflow was updated to `set -eu`. |
| CI harness gate | `.github/workflows/harness.yml` | Present | Runs `./init.sh` on PRs and pushes. |
| Maestro simulator CI | `.github/workflows/maestro.yml` | Added | Resolves Flutter packages, then runs all `done` specs on iOS simulator and Android emulator with `spec accept --maestro`; no IPA/APK/AAB artifact packaging. |
| Home Counter BLoC test | `fvm flutter test test/features/home/presentation/bloc/home_counter_bloc_test.dart` | Pass | 7 tests. |
| HomeUserBloc test | `fvm flutter test test/features/home/presentation/bloc/home_user_bloc_test.dart` | Pass | 6 tests. |
| Home Counter iOS acceptance | `fvm dart run tool/harness.dart spec accept home-counter --maestro` | Pass | Maestro flow passes on iOS. |
| Decrement iOS acceptance | `fvm dart run tool/harness.dart spec accept home-counter-decrement --maestro --platform ios` | Pass | All 4 Maestro criteria pass on iOS. |
| Home User Display iOS acceptance | `fvm dart run tool/harness.dart spec accept home-user-display --maestro --platform ios` | Pass | All 6 Maestro criteria pass on iOS with refreshed committed evidence. |

## Blockers / Risks

- Maestro eval depends on simulator/emulator state and remains outside the default `check` command.
- UI-only specs intentionally need `--maestro` to produce PASS.
- Local device-backed Maestro remains outside the default `check` command; CI provisions hosted iOS and Android simulators in `.github/workflows/maestro.yml`.
- Flutter reports `native_flutter_proxy` and `flutter_inappwebview_ios` do not support iOS Swift Package Manager yet; this warning says it will become an error in a future Flutter release.

## Next Session Startup

1. Read `AGENTS.md`.
2. Read `docs/harness/SKILLS.md` when a task touches Flutter or Dart behavior.
3. Read `feature_list.json` and `progress.md`.
4. Review this handoff.
5. Run `./init.sh` or `fvm dart run tool/harness.dart check` before editing.

## Recommended Next Step

- Watch the first GitHub Actions `Maestro` run and tune hosted simulator/emulator selection if needed.
- Track iOS Swift Package Manager support for `native_flutter_proxy` and `flutter_inappwebview_ios`.
- Consider what feature to implement next (feat-004).
