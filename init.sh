#!/bin/bash
set -e

echo "=== Harness Initialization ==="
echo "Working directory: $(pwd)"

echo "=== Resolve Flutter dependencies ==="
fvm flutter pub get

echo "=== Bootstrap dependencies and generated code ==="
fvm dart run tool/harness.dart bootstrap

echo "=== Static/build check: format + structure + lint/analyze + coverage ==="
fvm dart run tool/harness.dart check

echo "=== Verification Complete ==="
echo ""
echo "Next steps:"
echo "1. Read feature_list.json to see current feature state."
echo "2. Pick ONE unfinished feature to work on."
echo "3. Keep changes inside that feature's scope and dependencies."
echo "4. Re-run ./init.sh or fvm dart run tool/harness.dart check before claiming done."
echo "5. Run fvm dart run tool/harness.dart spec accept <id> --maestro --platform all before marking done."
echo "6. Record evidence in progress.md and session-handoff.md."
