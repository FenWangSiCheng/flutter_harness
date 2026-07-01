# Harness Evidence Directory

This directory contains committed acceptance evidence for features that have reached "done" status.

## Directory Structure

```
docs/harness/evidence/
├── README.md
└── {spec-id}/
    ├── report.json          # Dual-platform summary report
    ├── report-ios.json      # iOS acceptance report
    └── report-android.json  # Android acceptance report
```

## What Gets Committed

- **Final acceptance reports** for features marked as "done" in feature_list.json
- Evidence that should be auditable and persist across `flutter clean`

## What Doesn't Get Committed

- Intermediate build artifacts remain in `build/harness/evidence/` (gitignored)
- WIP (work in progress) acceptance runs

## How to Add Evidence

1. Run acceptance: `fvm dart run tool/harness.dart spec accept {spec-id} --maestro --platform all`
2. Promote the reports: `fvm dart run tool/harness.dart evidence promote {spec-id}`
3. Verify the committed reports: `fvm dart run tool/harness.dart evidence promote {spec-id} --check`
4. Run the review gate: `fvm dart run tool/harness.dart review {spec-id}`
5. Commit to git
6. Update the evidence path in feature_list.json

## Evidence Format

Each summary `report.json` contains:
- spec: The spec ID
- feature: The feature ID
- platform: all
- result: PASS/BLOCKED/SKIPPED
- platforms: Array containing the iOS and Android platform reports
- harness_events: Stable runtime event names relevant to this acceptance path
- harness_metadata: Git sha, promotion command, Flutter version, Maestro
  version, policy path, and acceptance summary

Each platform report contains:
- spec: The spec ID
- feature: The feature ID
- platform: ios/android
- result: PASS/BLOCKED/SKIPPED
- acceptance: Array of individual acceptance criteria results
- harness_metadata: Same promotion metadata as the summary report
