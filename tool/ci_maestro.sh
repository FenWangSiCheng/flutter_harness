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

python3 - <<'PY' > /tmp/done-specs.txt
import json

with open("feature_list.json", encoding="utf-8") as file:
    features = json.load(file)["features"]

for feature in features:
    if feature.get("status") == "done" and feature.get("spec"):
        print(feature["spec"])
PY

if [ ! -s /tmp/done-specs.txt ]; then
  echo "No done specs found in feature_list.json."
  exit 1
fi

while IFS= read -r spec; do
  [ -n "$spec" ] || continue
  fvm dart run tool/harness.dart spec accept "$spec" --maestro --platform "$platform"
done < /tmp/done-specs.txt
