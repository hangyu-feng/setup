#!/bin/bash
set -euxo pipefail
PLUGINS=/opt/apps/valheim/config/bepinex/plugins
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "Fetching latest PlanBuild version..."
VERSION=$(curl -sf \
  "https://thunderstore.io/api/experimental/package/\
MathiasDecrock/PlanBuild/" \
  | python3 -c \
  "import sys,json; \
d=json.load(sys.stdin); \
print(d['latest']['version_number'])")

echo "Downloading PlanBuild $VERSION..."
curl -fL \
  "https://thunderstore.io/package/download/\
MathiasDecrock/PlanBuild/${VERSION}/" \
  -o "$TMP/planbuild.zip"

unzip -o "$TMP/planbuild.zip" -d "$TMP/planbuild"

cp -r "$TMP"/planbuild/plugins/PlanBuild "$PLUGINS/"

echo "Restarting Valheim..."
docker restart valheim
echo "Done."
