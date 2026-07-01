#!/usr/bin/env bash
set -euo pipefail

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
  fvm dart run tool/harness.dart spec accept "$spec" --maestro --platform android
done < /tmp/done-specs.txt
