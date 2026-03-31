#!/bin/bash
set -e

INSTALL_DIR=/opt/desynced

export WINEDEBUG=-all
export WINEARCH=win64

# Clean up stale X lock from previous crash
rm -f /tmp/.X99-lock

# Start virtual display
Xvfb :99 -screen 0 1280x1024x24 -nolisten tcp &
export DISPLAY=:99
sleep 1

# Initialize Wine prefix on first run
if [ ! -d "$HOME/.wine" ]; then
    echo "[desynced] Initializing Wine prefix..."
    /usr/lib/wine/wine64 wineboot --init
fi

# Server executable — UE5 Windows binary
EXE="${INSTALL_DIR}/Desynced/Binaries/Win64/DesyncedServer.exe"

if [ ! -f "$EXE" ]; then
    echo "[desynced] ERROR: Executable not found at $EXE"
    echo "[desynced] Directory tree:"
    find "${INSTALL_DIR}" -name "*.exe" 2>/dev/null
    exit 1
fi

# Symlink persistent saves into Wine prefix
WINE_SAVE_DIR="$HOME/.wine/drive_c/users/root/AppData/Local/Desynced/Saved/SaveGames"
mkdir -p "$(dirname "$WINE_SAVE_DIR")"
ln -sfn /desynced/server/Saved/SaveGames "$WINE_SAVE_DIR"

echo "[desynced] Starting Desynced dedicated server..."

# NOTE: -SessionSettings and -GameSettings CLI args are disabled.
# Wine's command-line reconstruction breaks JSON parsing — the server
# only sees the first '{'. Settings must be configured in-game or via
# a config file once we find where Desynced reads one.

SAVE_FILE="C:\\users\\root\\AppData\\Local\\Desynced\\Saved\\SaveGames\\${WORLD_NAME:-World1}.desynced"
exec /usr/lib/wine/wine64 "$EXE" \
    "$SAVE_FILE" \
    -Port=10099 \
    -log \
    "$@"
