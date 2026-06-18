# Quality Ledger

This ledger is intentionally compact. It gives agents a durable view of where
the project is strong, where it is thin, and what to improve next.

## Scorecard

| Area | Status | Notes |
| --- | --- | --- |
| Architecture | Good | Feature-first layering is clear and now guarded by tests. |
| Configuration | Good | Flavor behavior is centralized in `AppConfig`. |
| Networking | Good | Dio setup supports mocks, proxy behavior, and error handling. |
| Tests | Good | Unit, widget, BLoC, and harness tests are present. |
| Observability | Emerging | Startup and network initialization emit structured harness events. |
| Documentation | Good | Agent map and harness docs now cover the working loop. |
| CI | Needs follow-up | GitLab CI existed before the harness; align it with `tool/harness.dart`. |

## Golden Principles

- Every repeated review comment should become documentation, a test, or a tool
  check.
- Keep context discoverable in the repository.
- Prefer narrow, composable modules over clever global behavior.
- Preserve mechanical validation over manual inspection.
- Update this file when a quality gap is discovered or retired.

## Known Follow-Ups

- Wire `fvm dart run tool/harness.dart check` into CI as the primary test command.
- Add integration-test smoke coverage for a real device or simulator.
- Extend structured events around user-flow success and failure states.
- Add coverage thresholds once current coverage is measured and baselined.
