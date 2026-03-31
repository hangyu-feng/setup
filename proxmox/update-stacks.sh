#!/usr/bin/env bash
# Update all running Docker Compose stacks on gameserver
# Usage: bash update-stacks.sh
set -euo pipefail

ssh gameserver 'bash -s' << 'EOF'
APPS_DIR="/opt/apps"
for dir in "$APPS_DIR"/*/; do
    compose="$dir/compose.yml"
    [ -f "$compose" ] || continue
    if ! docker compose -f "$compose" ps -q 2>/dev/null \
        | grep -q .; then
        continue
    fi
    echo "==> Updating $(basename "$dir")"
    docker compose -f "$compose" pull
    docker compose -f "$compose" up -d --remove-orphans
    echo ""
done
echo "==> Pruning unused images"
docker image prune -f
EOF
