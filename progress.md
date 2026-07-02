# Session Progress Log

## Current State

**Last Updated:** 2026-07-02 CST
**Active Feature:** feat-004 Home todo list (done)
**Current Activity:** Harness simplification pass - runner responsibilities split, policy owns static inventories, structure tests reduced hardcoded source-shape checks.

## Status

### What's Done

- [x] `feat-004` Home todo list is implemented, accepted on iOS and Android, promoted under `docs/harness/evidence/home-todolist/`, and review-gated PASS.
- [x] Split `tool/harness.dart` into focused support modules for process execution, device build/install, acceptance reporting, evidence/review, and shared policy/state helpers.
- [x] Moved generated-file and agent-skill inventories into `docs/harness/policy.yaml`.
- [x] Updated structure guards to read policy-owned inventories and rely less on private runner source layout.
- [x] Updated harness README and policy required-file lists for the new runner module layout.

### What's Next

1. Pick the next app feature, or refine Home todo persistence if desired.
2. Keep Android SDK `platform-tools` on PATH when running local acceptance commands that call `adb` directly.
3. If future harness work touches acceptance or evidence, update the focused module instead of growing `tool/harness.dart`.

## Blockers / Risks

- [ ] Flutter reports `native_flutter_proxy` and `flutter_inappwebview_ios` do not support iOS Swift Package Manager yet; the warning says this will become an error in a future Flutter release.
- [ ] Android build emits future-deprecation warnings for Gradle 8.7.0, Android Gradle Plugin 8.6.0, Kotlin 2.1.0, and Kotlin Gradle Plugin usage.

## Decisions Made

- **Runner orchestration only**: `tool/harness.dart` now routes commands and delegates acceptance, evidence, device, and process responsibilities.
- **Policy owns static inventories**: generated files and expected agent skills live in `docs/harness/policy.yaml`, so doctor and structure tests share one source.
- **Maestro owns UI verification**: UI behavior remains covered by Maestro acceptance rather than Flutter widget tests.

## Files Modified This Session

- `tool/harness.dart` - Reduced to command routing and high-level workflow coordination.
- `tool/harness_acceptance.dart` - Added acceptance execution and report generation.
- `tool/harness_device.dart` - Added dev app build/install helpers for iOS and Android.
- `tool/harness_evidence.dart` - Added evidence promotion and read-only review logic.
- `tool/harness_process.dart` - Added shared process execution, command builders, and `adb` PATH discovery.
- `tool/harness_support.dart` - Extended policy model for generated files and agent skills.
- `docs/harness/policy.yaml` - Added new harness files plus generated-file and skill inventories.
- `docs/harness/README.md` - Updated runner support file map.
- `test/harness/architecture_guard_test.dart` - Updated guards for policy-driven inventories and split runner modules.
- `progress.md` - Trimmed to current state and this session's evidence.
- `session-handoff.md` - Trimmed to restart notes and current verification state.

## Evidence of Completion

- [x] `fvm dart analyze tool test/harness` passes.
- [x] `fvm dart run tool/harness.dart structure` passes: 23/23 structure tests.
- [x] `fvm dart run tool/harness.dart check` passes: format clean, structure 23/23, analyzer clean, 175 coverage-gated tests pass; included coverage is 300/325 lines (92.31%) against the 90% threshold.
- [x] `fvm dart run tool/harness.dart evidence promote --all --check` passes.
- [x] `fvm dart run tool/harness.dart review home-todolist` passes.
