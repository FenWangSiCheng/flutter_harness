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
2. Copy the reports from `build/harness/evidence/{spec-id}/` to `docs/harness/evidence/{spec-id}/`
3. Commit to git
4. Update the evidence path in feature_list.json

## Evidence Format

Each summary `report.json` contains:
- spec: The spec ID
- feature: The feature ID
- platform: all
- result: PASS/BLOCKED/SKIPPED
- platforms: Array containing the iOS and Android platform reports

Each platform report contains:
- spec: The spec ID
- feature: The feature ID
- platform: ios/android
- result: PASS/BLOCKED/SKIPPED
- acceptance: Array of individual acceptance criteria results
