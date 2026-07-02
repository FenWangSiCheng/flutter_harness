# Session Handoff

## Current Objective

- Goal: Keep the repository-local Flutter harness simple, restartable, and mechanically checked.
- Current status: `feat-004` Home todo list is complete, marked `done`, and has promoted dual-platform acceptance evidence.
- Harness state: `tool/harness.dart` is now an orchestration layer; acceptance, evidence, device install, process execution, and shared policy/state logic live in focused `tool/harness_*.dart` modules.

## Completed

- [x] Split acceptance report generation into `tool/harness_acceptance.dart`.
- [x] Split iOS/Android dev app build/install into `tool/harness_device.dart`.
- [x] Split evidence promotion and read-only review into `tool/harness_evidence.dart`.
- [x] Split process execution, command helpers, and `adb` PATH discovery into `tool/harness_process.dart`.
- [x] Moved generated-file and agent-skill inventories into `docs/harness/policy.yaml`.
- [x] Updated structure guards to consume policy-owned inventories and check less private runner shape.
- [x] Trimmed session docs so `progress.md` tracks current state and this file tracks restart context.

## Verification Evidence

| Check | Command | Result |
|---|---|---|
| Static analysis | `fvm dart analyze tool test/harness` | PASS |
| Structure guard | `fvm dart run tool/harness.dart structure` | PASS, 23/23 |
| Full harness check | `fvm dart run tool/harness.dart check` | PASS, 92.31% coverage |
| Evidence check | `fvm dart run tool/harness.dart evidence promote --all --check` | PASS |
| Review gate | `fvm dart run tool/harness.dart review home-todolist` | PASS |

## Blockers / Risks

- Flutter reports `native_flutter_proxy` and `flutter_inappwebview_ios` do not support iOS Swift Package Manager yet; this warning says it will become an error in a future Flutter release.
- Android build warns that Gradle, Android Gradle Plugin, Kotlin, and Kotlin Gradle Plugin usage will need upgrades for future Flutter releases.

## Next Session Startup

1. Read `AGENTS.md`.
2. Read `feature_list.json`, `progress.md`, and this handoff.
3. Run `./init.sh` for a fresh baseline or `fvm dart run tool/harness.dart check` for narrower verification.
4. If touching Flutter or Dart behavior, read `docs/harness/SKILLS.md` and the matching skill.

## Recommended Next Step

- Pick the next app feature or persist the Home todo list.
