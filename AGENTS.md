# Agent Map

This repository is a Flutter harness project. Treat the repo as the system of
record: prefer checked-in docs, scripts, tests, generated artifacts, and local
logs over outside memory.

## Startup Workflow

Before writing code:

1. Confirm the working directory with `pwd`.
2. Read this file completely.
3. Read `docs/harness/README.md` and any deeper harness doc relevant to the task.
4. Read `feature_list.json` and `progress.md` to identify the active feature,
   status, dependencies, evidence, and next step.
5. For Flutter or Dart tasks, review `docs/harness/SKILLS.md` and load only the
   matching skill from `.agents/skills/<skill>/SKILL.md`.
6. Run `./init.sh` when establishing a fresh baseline. For narrower iteration,
   run the smallest command from `docs/harness/VALIDATION.md`.
7. Review recent history with `git log --oneline -5` when task context depends
   on prior work.

If baseline verification is failing, repair or record that baseline before
adding new scope.

## Start Here

- Project map: `docs/harness/README.md`
- Architecture rules: `docs/harness/ARCHITECTURE.md`
- Validation commands: `docs/harness/VALIDATION.md`
- Agent skills: `docs/harness/SKILLS.md`
- Quality ledger: `docs/harness/QUALITY.md`
- Operating notes: `docs/harness/OPERABILITY.md`
- Active task pattern: `docs/harness/TASKS.md`
- Feature state: `feature_list.json`
- Session progress: `progress.md`
- Session handoff: `session-handoff.md`
- Acceptance evidence: `docs/harness/evidence/`

## Working Loop

1. Read the relevant harness docs before editing.
2. Pick one active feature from `feature_list.json`.
3. Make narrow changes that follow the existing feature-first structure.
4. Keep changes inside the active feature scope and its documented dependencies.
5. Run the smallest meaningful check while iterating.
6. Run `fvm dart run tool/harness.dart check` before handing off broad changes.
7. Update harness docs or state artifacts when a rule, workflow, repeated
   failure, feature status, or verification result changes.

## Required Artifacts

- `feature_list.json` - Feature tracker and source of truth for status,
  dependencies, and evidence.
- `progress.md` - Session continuity log with current state, next step, risks,
  decisions, files touched, and verification evidence.
- `init.sh` - Standard startup and verification path.
- `session-handoff.md` - Restart instructions and evidence for the next session.
- `tool/harness.dart` - Flutter-specific command runner.
- `docs/harness/` - Project map, architecture, validation, quality, operability,
  and task patterns.
- `docs/harness/evidence/` - Committed acceptance evidence for done features.
- `.agents/skills/` - Project-local Flutter and Dart agent skills.
- `docs/harness/SKILLS.md` - Skill inventory, update workflow, and usage rules.

## Scope Rules

- One feature at a time: do not start unrelated features while another feature is
  active unless `feature_list.json` records explicit dependencies or ownership.
- Stay in scope: avoid modifying files unrelated to the active feature unless
  needed to keep the harness, tests, or generated artifacts coherent.
- Do not mark a feature done until the target behavior, docs/state updates, and
  verification evidence are all present.
- If scope is ambiguous, re-read `feature_list.json` and `docs/harness/TASKS.md`
  before changing code.

## Definition of Done

A feature is done only when all of the following are true:

- Target behavior or repository-visible outcome is implemented.
- Relevant docs, feature state, and session progress match the code.
- Required verification actually ran: tests, analyzer, structural checks, or a
  documented narrower check for the touched surface.
- `fvm dart run tool/harness.dart spec accept <id> --maestro --platform all`
  has run and reports PASS on both iOS and Android for every spec linked to the
  feature. If either platform has no available simulator/device, record BLOCKED
  with the reason instead of marking done.
- Evidence is recorded in `feature_list.json`, `progress.md`, or
  `session-handoff.md`.
- Acceptance report is committed to `docs/harness/evidence/{spec-id}/report.json`.
- The repository remains restartable from `./init.sh` or a documented baseline
  command.

## End of Session

Before ending a session:

1. Update `progress.md` with current state, decisions, files changed, blockers,
   and verification evidence.
2. Update `feature_list.json` with feature status and evidence.
3. Update `session-handoff.md` when the work may continue in another session.
4. Leave the repo clean enough for the next session to run `./init.sh`
   immediately, or document the exact failing baseline and next action.

## Verification Commands

- Full startup and verification: `./init.sh`
- Bootstrap: `fvm dart run tool/harness.dart bootstrap`
- Doctor: `fvm dart run tool/harness.dart doctor`
- Structure guard: `fvm dart run tool/harness.dart structure`
- Coverage gate: `fvm dart run tool/harness.dart coverage`
- Full check: `fvm dart run tool/harness.dart check`
- App run: `fvm flutter run --flavor dev --dart-define-from-file=dart_defines/dev.json`

Required checks:

- Run `fvm dart run tool/harness.dart structure` after harness or architecture
  edits.
- Run `fvm dart run tool/harness.dart check` before handing off broad changes.
- Run `fvm dart run tool/harness.dart spec accept <id> --maestro --platform all`
  before marking a feature done. If either iOS or Android has no available
  simulator/device, record BLOCKED instead.
- Run `./init.sh` when proving the project is restartable from the standard
  walkinglabs lifecycle path.

## Legacy Flutter Rules

These project rules remain active:

- Keep domain code independent from data and presentation.
- Keep data code independent from presentation.
- Keep generated files synchronized after changing annotations.
- Use `AppConfig` for environment behavior; avoid ad hoc flavor checks.
- Verify user-visible UI behavior with Maestro flows. Keep Flutter tests for
  logic, data mapping, routing configuration, BLoC behavior, and harness rules.
- If a failure points to missing context, improve the harness instead of only
  patching the symptom.

## Escalation

- Architecture decisions: consult `docs/harness/ARCHITECTURE.md`.
- Validation failures: follow `docs/harness/VALIDATION.md`.
- Runtime debugging: consult `docs/harness/OPERABILITY.md` and search logs for
  `[harness]`.
- Repeated failure or new operating rule: encode it in docs, tests, tooling, or
  state artifacts before handing off.
