# Quality Ledger

This ledger is intentionally compact. It gives agents a durable view of where
the project is strong, where it is thin, and what to improve next.

## Scorecard

| Area | Status | Notes |
| --- | --- | --- |
| Architecture | Good | Feature-first layering is clear and now guarded by tests. |
| Configuration | Good | Flavor behavior is centralized in `AppConfig`. |
| Networking | Good | Dio setup supports mocks, proxy behavior, and error handling. |
| Tests | Good | Logic, data, BLoC, network, and harness tests are present; `check` now gates non-UI logic coverage at 90%; UI behavior is verified with Maestro instead of widget tests. |
| Observability | Good | Startup, network initialization, and user-flow success/failure states emit structured harness events referenced by acceptance reports. |
| Spec Evaluation | Good | Specs support dual-platform Maestro acceptance with `--platform all`; committed evidence is promoted with metadata and checked by a read-only review gate. |
| Documentation | Good | Agent map and harness docs now cover the working loop and walkinglabs five-subsystem model. |
| Agent Skills | Good | Official Flutter and Dart skills are checked into `.agents/skills` and guarded by structure tests. |
| Session Lifecycle | Good | Root feature state, progress, init, and handoff artifacts make sessions restartable. |
| CI | Good | GitHub Actions runs `./init.sh` for the standard gate and `.github/workflows/maestro.yml` for iOS simulator and Android emulator Maestro acceptance without release artifacts. |
| Dependency Health | Watch | Dio is current within the direct dependency set; Flutter still warns that `native_flutter_proxy` and `flutter_inappwebview_ios` do not yet support iOS Swift Package Manager. |

## Golden Principles

- Every repeated review comment should become documentation, a test, or a tool
  check.
- Keep context discoverable in the repository.
- Prefer narrow, composable modules over clever global behavior.
- Preserve mechanical validation over manual inspection.
- Keep feature status, progress, and handoff evidence current before ending an
  agent session.
- Update this file when a quality gap is discovered or retired.

## Known Follow-Ups

- Watch the first metadata-enriched Maestro CI run and tune simulator/emulator
  image selection if the hosted runner inventory changes.
- Track iOS Swift Package Manager support for `native_flutter_proxy` and
  `flutter_inappwebview_ios`; Flutter reports this will become an error in a
  future release.
