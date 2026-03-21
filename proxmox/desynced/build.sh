#!/bin/bash
read -rsp "Steam password: " STEAM_PASS
echo
docker compose build --no-cache \
  --build-arg STEAM_USER=vailgrass \
  --build-arg STEAM_PASS="$STEAM_PASS"
