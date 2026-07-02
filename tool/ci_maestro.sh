#!/usr/bin/env bash
set -euo pipefail

platform="${1:-}"
case "$platform" in
  ios|android)
    ;;
  *)
    echo "Usage: bash tool/ci_maestro.sh ios|android"
    exit 64
    ;;
esac

echo "Flutter version:"
fvm flutter --version

echo "Maestro version:"
maestro --version

if [ "$platform" = "ios" ]; then
  echo "Booted iOS devices:"
  xcrun simctl list devices booted || true
else
  echo "Android devices:"
  adb devices
fi

fvm dart run tool/harness.dart done-specs > /tmp/done-specs.txt

if [ ! -s /tmp/done-specs.txt ]; then
  echo "No done specs found in feature_list.json."
  exit 0
fi

while IFS= read -r spec; do
  [ -n "$spec" ] || continue
  fvm dart run tool/harness.dart spec accept "$spec" --maestro --platform "$platform"
done < /tmp/done-specs.txt
