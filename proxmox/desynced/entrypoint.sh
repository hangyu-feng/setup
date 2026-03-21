#!/bin/bash
set -e

INSTALL_DIR=/opt/desynced
SERVER_DIR=/desynced/server

export WINEDEBUG=-all

# Initialize Wine prefix on first run
if [ ! -d "$HOME/.wine" ]; then
    echo "[desynced] Initializing Wine prefix..."
    xvfb-run --auto-servernum wineboot --init
fi

# Server executable — UE5 Windows binary
EXE="${INSTALL_DIR}/Desynced/Binaries/Win64/DesyncedServer.exe"

if [ ! -f "$EXE" ]; then
    echo "[desynced] ERROR: Executable not found at $EXE"
    echo "[desynced] Directory tree:"
    find "${INSTALL_DIR}" -name "*.exe" 2>/dev/null
    exit 1
fi

SESSION_SETTINGS="{\"ServerName\":\"${SERVER_NAME:-My Desynced Server}\",\"MaxPlayers\":${MAX_PLAYERS:-10},\"Visibility\":\"${PRIVATE:-private}\",\"RunWithoutPlayers\":${RUN_WITHOUT_PLAYERS:-false}}"
GAME_SETTINGS="{\"ResourceRichness\":${RESOURCE_RICHNESS:-4},\"BlightThreshold\":${BLIGHT_THRESHOLD:-0.1},\"PeacefulMode\":${PEACEFUL_MODE:-2}}"

echo "[desynced] Starting Desynced dedicated server..."
exec xvfb-run --auto-servernum wine "$EXE" \
    "${WORLD_NAME:-World1}" \
    -Port=10099 \
    -log \
    -SessionSettings="${SESSION_SETTINGS}" \
    -GameSettings="${GAME_SETTINGS}" \
    "$@"
