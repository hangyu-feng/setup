# Update all running Docker Compose stacks on gameserver
# Usage: powershell -File update-stacks.ps1

$script = @'
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
'@

$script | ssh gameserver 'tr -d \\r | bash -s'
