# Flutter Harness Project

This project is a Flutter application plus a repository-local harness for AI
coding agents. The harness makes the app legible, reproducible, and mechanically
checkable so agents can work without relying on hidden context.

The approach follows the OpenAI harness engineering field report and the
walkinglabs awesome harness engineering index:

- Repository knowledge is the system of record.
- The top-level agent file is a map, not a manual.
- Architecture rules are explicit and tested.
- Validation is runnable from a single local entry point.
- Runtime behavior emits structured signals an agent can inspect.
- Quality and cleanup work are tracked as durable repo artifacts.

## Repository Map

| Path | Purpose |
| --- | --- |
| `AGENTS.md` | Short entry point for coding agents. |
| `docs/harness/ARCHITECTURE.md` | Flutter and clean architecture boundaries. |
| `docs/harness/VALIDATION.md` | Commands, expected checks, and triage order. |
| `docs/harness/QUALITY.md` | Current quality scorecard and known gaps. |
| `docs/harness/OPERABILITY.md` | Runtime logging and local observability notes. |
| `docs/harness/TASKS.md` | How to write durable execution plans. |
| `tool/harness.dart` | Local command runner for bootstrap, checks, and diagnostics. |
| `test/harness/` | Structural tests that protect harness assumptions. |
| `lib/core/harness/` | Lightweight app-side logging primitives. |

## Current App Surface

- Feature-first Flutter app using BLoC, Dio, get_it, injectable, and go_router.
- Three flavors: `dev`, `stg`, and `prod`.
- Development flavor uses local mock API data from `assets/mock/`.
- Generated code is committed in this repo and must stay in sync with source
  annotations.

## Harness Definition Of Done

A change is harness-ready when:

- The relevant docs still match the code.
- `fvm dart run tool/harness.dart structure` passes.
- Flutter analysis and tests pass for the touched surface.
- New operational signals are structured enough for an agent to search.
- Any newly discovered recurring failure is captured in docs, tests, or tooling.

## Sources

- https://openai.com/index/harness-engineering/
- https://github.com/walkinglabs/awesome-harness-engineering
