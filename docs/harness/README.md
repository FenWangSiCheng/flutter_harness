# Flutter Harness Project

This project is a Flutter application plus a repository-local harness for AI
coding agents. The harness makes the app legible, reproducible, and mechanically
checkable so agents can work without relying on hidden context.

The approach follows the OpenAI harness engineering field report and the
walkinglabs learn-harness-engineering model:

- Repository knowledge is the system of record.
- The top-level agent file is a map, not a manual.
- Architecture rules are explicit and tested.
- Validation is runnable from a single local entry point.
- Runtime behavior emits structured signals an agent can inspect.
- Quality and cleanup work are tracked as durable repo artifacts.
- Root state and lifecycle artifacts make sessions restartable.

## Repository Map

| Path | Purpose |
| --- | --- |
| `AGENTS.md` | Short entry point for coding agents. |
| `feature_list.json` | Feature state, dependencies, status, and evidence. |
| `progress.md` | Current session state, decisions, risks, next step, and proof. |
| `init.sh` | Standard startup and verification entrypoint. |
| `session-handoff.md` | Restart notes for the next agent session. |
| `.github/workflows/harness.yml` | CI gate that runs the standard harness startup. |
| `.github/workflows/maestro.yml` | CI gate that boots iOS/Android simulators and runs Maestro acceptance. |
| `.agents/skills/` | Project-local Flutter and Dart agent skills. |
| `docs/harness/policy.yaml` | Machine-readable harness policy for coverage, evidence, CI, and app ids. |
| `docs/harness/evaluators/` | Read-only review rubrics for independent harness evaluation. |
| `docs/harness/ARCHITECTURE.md` | Flutter and clean architecture boundaries. |
| `docs/harness/VALIDATION.md` | Commands, expected checks, and triage order. |
| `docs/harness/SKILLS.md` | Skill inventory, update workflow, and usage rules. |
| `docs/harness/QUALITY.md` | Current quality scorecard and known gaps. |
| `docs/harness/OPERABILITY.md` | Runtime logging and local observability notes. |
| `docs/harness/TASKS.md` | How to write durable execution plans. |
| `docs/harness/evidence/` | Committed acceptance evidence for done features. |
| `tool/harness.dart` | Local command runner for bootstrap, checks, and diagnostics. |
| `tool/harness_*.dart` | Focused runner support for acceptance, device install, evidence, process execution, state, policy, coverage, and UI-map generation. |
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

- The active feature in `feature_list.json` has explicit status, dependencies,
  and evidence.
- `progress.md` and `session-handoff.md` are current when work spans sessions.
- The relevant docs still match the code.
- `fvm dart run tool/harness.dart structure` passes.
- Flutter analysis and coverage-gated tests pass for the touched surface.
- New operational signals are structured enough for an agent to search.
- Acceptance evidence is promoted with `tool/harness.dart evidence promote`
  so reports include policy, environment, and acceptance metadata.
- Simulator-backed Maestro CI is available for iOS and Android acceptance.
- Any newly discovered recurring failure is captured in docs, tests, or tooling.

## Five Harness Subsystems

| Subsystem | Local artifact | Rule |
| --- | --- | --- |
| Instructions | `AGENTS.md`, `docs/harness/` | Keep root instructions short and route agents to deeper docs. |
| State | `feature_list.json`, `progress.md` | Track active scope, status, evidence, blockers, and next steps on disk. |
| Verification | `init.sh`, `tool/harness.dart` | Use `./init.sh` for restartable startup and `tool/harness.dart` for Flutter checks. |
| Scope | `feature_list.json`, `docs/harness/TASKS.md` | Work one feature at a time unless dependencies are recorded. |
| Lifecycle | `progress.md`, `session-handoff.md` | End sessions with verification evidence and a clean restart path. |
| Skills | `.agents/skills/`, `docs/harness/SKILLS.md` | Keep project-specific agent workflows checked in and progressively loaded. |
| Policy | `docs/harness/policy.yaml` | Keep thresholds, app ids, required artifacts, and evidence rules machine-readable. |

## Sources

- https://openai.com/index/harness-engineering/
- https://github.com/walkinglabs/learn-harness-engineering
- https://github.com/walkinglabs/awesome-harness-engineering
