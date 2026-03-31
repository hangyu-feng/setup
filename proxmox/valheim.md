# Valheim Dedicated Server

> **Status: Deployed and verified.** Server live since 2026-03-24. BepInEx + 7 QoL mods deployed 2026-03-25. Game connection, Supervisor UI, Caddy proxy, DNS, and mods all working.

---

## 1. Image Selection

**Image:** `ghcr.io/community-valheim-tools/valheim-server`
**Repo:** https://github.com/community-valheim-tools/valheim-server-docker

**Why this image:**
- Most widely used Valheim Docker image (~1.5k stars)
- Built-in backup system with cron + retention
- Auto-update with idle-player check
- Supervisor HTTP UI for process management
- All config via environment variables — no manual file editing
- Actively maintained (forked from original lloesche/valheim-server)

---

## 2. Server Configuration

| Setting | Value |
|---|---|
| Server name | `vailgrss_server` |
| World name | `vailgrass_world` |
| Password | *(none)* |
| Public | `false` (Tailscale only) |
| Max players | 5 (Valheim default is 10) |
| Crossplay | `false` |
| Mods | BepInEx + 7 QoL mods (see section 10) |

---

## 3. Compose File

**Path:** `/opt/apps/valheim/compose.yml`
**Local copy:** `valheim/compose.yml` in this repo

```yaml
services:
  valheim:
    image: ghcr.io/community-valheim-tools/valheim-server
    container_name: valheim
    restart: unless-stopped
    stop_grace_period: 2m
    cap_add:
      - sys_nice
    ports:
      - "2456:2456/udp"
      - "2457:2457/udp"
    networks:
      - proxy
    environment:
      # Server
      - SERVER_NAME=vailgrss_server
      - WORLD_NAME=vailgrass_world
      - SERVER_PASS=
      - SERVER_PUBLIC=false
      # Backups — every 5 minutes, keep 3
      - BACKUPS=true
      - BACKUPS_CRON=*/5 * * * *
      - BACKUPS_MAX_COUNT=3
      - BACKUPS_MAX_AGE=0
      - BACKUPS_IF_IDLE=false
      - BACKUPS_IDLE_GRACE_PERIOD=3600
      - BACKUPS_ZIP=true
      # Auto-update — daily at 5 AM, only if empty
      - UPDATE_CRON=0 5 * * *
      - UPDATE_IF_IDLE=true
      # Restart — daily at 5:10 AM, only if empty
      - RESTART_CRON=10 5 * * *
      - RESTART_IF_IDLE=true
      # Supervisor web UI
      - SUPERVISOR_HTTP=true
      - SUPERVISOR_HTTP_PORT=9001
      - SUPERVISOR_HTTP_USER=admin
      - SUPERVISOR_HTTP_PASS=960730
      # Discord notifications
      - "PRE_SERVER_LISTENING_HOOK=curl -sfSL -X POST -H 'Content-Type: application/json' -d '{\"content\":\"Valheim server is starting...\"}' ${DISCORD_WEBHOOK}"
      - "POST_SERVER_LISTENING_HOOK=curl -sfSL -X POST -H 'Content-Type: application/json' -d '{\"content\":\"Valheim server is online and ready!\"}' ${DISCORD_WEBHOOK}"
      - "PRE_SERVER_SHUTDOWN_HOOK=curl -sfSL -X POST -H 'Content-Type: application/json' -d '{\"content\":\"Valheim server is shutting down...\"}' ${DISCORD_WEBHOOK}"
      - "POST_SERVER_SHUTDOWN_HOOK=curl -sfSL -X POST -H 'Content-Type: application/json' -d '{\"content\":\"Valheim server has shut down.\"}' ${DISCORD_WEBHOOK}"
      # BepInEx mod framework
      - BEPINEX=true
      # Timezone
      - TZ=America/Chicago
    env_file:
      - .env
    volumes:
      - ./config:/config
      - ./server:/opt/valheim

networks:
  proxy:
    external: true
```

### Key decisions:

- **`stop_grace_period: 2m`** — gives the server time to save the world before Docker kills it. The image handles SIGTERM gracefully via supervisord.
- **`cap_add: sys_nice`** — allows the Steam library to set thread priority for better CPU scheduling. Without it, the server still works but logs warnings.
- **`BACKUPS_MAX_AGE=0`** — disables age-based deletion so retention is purely count-based (keep 3).
- **`BACKUPS_IF_IDLE=false`** — no point backing up when nobody has played. Grace period of 3600s ensures a final backup after the last player leaves.
- **`SERVER_PUBLIC=false`** — not listed in Steam browser. Friends connect directly via Tailscale IP.
- **`proxy` network** — needed so Caddy can reach the supervisor UI on port 9001.
- **BepInEx + 7 QoL mods** — deployed 2026-03-25. See section 10 for full list.
- **No `deploy.resources` block** — Docker Compose v2 resource limits require `--compatibility` flag or swarm mode. Instead, we rely on the VM's 16GB being sufficient. Valheim vanilla with 5 players uses ~3-4GB RAM.

---

## 4. Persistent Storage

```
/opt/apps/valheim/
├── compose.yml
├── .env               ← DISCORD_WEBHOOK (not in repo)
├── config/            ← world saves, backups, admin lists
│   ├── worlds_local/  ← vailgrass_world.db, .fwl files
│   ├── backups/       ← zip backups (max 3)
│   └── bepinex/
│       └── plugins/   ← mod DLLs (8 files)
└── server/            ← downloaded Valheim server files (~1 GB)
```

| Mount | Container path | Purpose |
|---|---|---|
| `./config` | `/config` | World saves, backups, config files. **Critical data.** |
| `./server` | `/opt/valheim` | Server binaries. Avoids re-downloading ~1GB on container recreate. |

> **Important:** `backups/` must NOT be inside `worlds_local/` or each backup recursively includes all previous backups.

---

## 5. Networking

### Ports

| Port | Protocol | Purpose | Exposure |
|---|---|---|---|
| 2456 | UDP | Game traffic | Host → container |
| 2457 | UDP | Steam query | Host → container |
| 9001 | TCP | Supervisor UI | Via Caddy (`valheim.gameserver`) |

### Access method

Friends connect via Tailscale: `100.93.238.124:2456`

No router port forwarding needed — all players are on the Tailscale network.

### Supervisor UI via Caddy

Port 9001 is NOT exposed to the host. Instead, Caddy reaches it over the `proxy` Docker network.

**Caddyfile addition:**
```
valheim.gameserver {
    reverse_proxy valheim:9001
    tls internal
}
```

**AdGuard DNS rewrite:**
`valheim.gameserver` → `100.93.238.124`

**Access:** `https://valheim.gameserver` (user: `admin`, pass: `960730`)

---

## 6. Resource Usage

Expected for vanilla, 5 players:

| Metric | Idle | 5 players |
|---|---|---|
| RAM | ~2.8 GB | ~3-4 GB |
| CPU | ~30% of 1 core | ~50-60% of 1 core |

Valheim is effectively single-threaded for heavy work — clock speed matters more than core count. The i5-12600K has strong single-core performance, so this will run well.

The VM has 16GB RAM and 8 vCPUs. Valheim leaves plenty of headroom for the other services (Desynced, Caddy, monitoring stack).

---

## 7. Backup Strategy

| Setting | Value |
|---|---|
| Schedule | Every 5 minutes (`*/5 * * * *`) |
| Max backups kept | 3 |
| Location | `/opt/apps/valheim/config/backups/` |
| Format | Compressed zip |
| When idle | Skip (no backup if no players connected) |
| Grace period | 3600s (one final backup after last player leaves) |

**Recovery:** Stop the server, extract the desired backup zip into `config/worlds_local/`, restart.

```bash
# List backups
ls -la /opt/apps/valheim/config/backups/

# Restore a backup (server must be stopped)
cd /opt/apps/valheim
docker compose down
cd config
unzip -o backups/<backup-file>.zip -d worlds_local/
cd ..
docker compose up -d
```

---

## 8. Auto-Update & Restart

| Action | Schedule | Condition |
|---|---|---|
| Update check | Daily at 5:00 AM (`0 5 * * *`) | Only if no players connected |
| Server restart | Daily at 5:10 AM (`10 5 * * *`) | Only if no players connected |

The update check runs first at 5:00 AM. If an update is found and the server is empty, it downloads and installs. Then the scheduled restart at 5:10 AM restarts the server process cleanly.

If players are connected at 5 AM, both update and restart are skipped until the next day.

---

## 9. Discord Notifications

The server sends status messages to a Discord channel via webhook hooks built into the image.

| Event | Message |
|---|---|
| `PRE_SERVER_LISTENING_HOOK` | "Valheim server is starting..." |
| `POST_SERVER_LISTENING_HOOK` | "Valheim server is online and ready!" |
| `PRE_SERVER_SHUTDOWN_HOOK` | "Valheim server is shutting down..." |
| `POST_SERVER_SHUTDOWN_HOOK` | "Valheim server has shut down." |

**Setup:**
- The webhook URL is stored in `valheim/.env` as `DISCORD_WEBHOOK` (not committed to compose.yml directly).
- Each hook calls `curl` to POST a JSON payload to the Discord webhook.
- To change the channel, update the webhook URL in `.env` and recreate the container.

---

## 10. Mods

### Native features (no mods needed)

These are built into Valheim and work on the vanilla server right now:

- **Shared map exploration** — build a Cartography Table in-game. Players interact with it to upload/download explored map areas.
- **Player positions on map** — each player opens map and toggles "Visible to other players" checkbox.

### QoL mods (deployed 2026-03-25)

BepInEx is enabled via `BEPINEX=true` env var. All mods below are installed on the server and require installation on every client via r2modman. Jotunn is installed as a dependency of MultiUserChest.

| Mod | Author | What it does |
|---|---|---|
| `AzuCraftyBoxes` | Azumatt | Craft using materials from nearby containers (~20m range) |
| `AzuExtendedPlayerInventory` | Azumatt | Extra inventory rows and equipment slots |
| `PlantEverything` | Advize | Plant berry bushes, mushrooms, and anything you pick |
| `PlantEasily` | Advize | Grid-snap planting so you can place rows/grids instead of one-by-one |
| `Quick_Stack_Store_Sort_Trash_Restock` | Goldenrevolver | One-click sort, stack, and restock items into nearby chests |
| `TargetPortal` | Smoothbrain | Pick portal destination from a list instead of matching portal names |
| `MultiUserChest` | MSchmoecker | Multiple players can open and use the same chest simultaneously |

#### Server mod location

DLLs are in `/opt/apps/valheim/config/bepinex/plugins/`

#### Client setup

1. Install [r2modman](https://thunderstore.io/package/ebkr/r2modman/)
2. Select **Valheim** (not Valheim Dedicated Server)
3. Install mods via **Online** tab, or import a profile code via **Settings → Profile → Import → From code**
4. r2modman auto-installs `BepInExPack_Valheim` and `Jotunn` as dependencies
5. **Always launch via r2modman "Start modded"** — launching from Steam directly skips BepInEx and mods won't load
6. To share with friends: **Settings → Profile → Export profile as code** → friend imports via **Import → From code**

---

## 11. Deployment Reference

Server was deployed 2026-03-24. Key steps for future reference (e.g. redeploying from scratch):

1. `mkdir -p /opt/apps/valheim`
2. `scp valheim/compose.yml gameserver:/opt/apps/valheim/`
3. Create `.env` with `DISCORD_WEBHOOK=<url>`
4. `docker compose pull && docker compose up -d`
5. `scp caddy/Caddyfile gameserver:/opt/apps/caddy/Caddyfile` → reload Caddy
6. AdGuard DNS rewrite: `valheim.gameserver` → `100.93.238.124`
7. Download mod DLLs into `config/bepinex/plugins/` and restart
8. Verify: Supervisor UI at `https://valheim.gameserver`, game connect to `100.93.238.124:2456`

---

## 12. Management Commands

```bash
# SSH to gameserver
ssh gameserver
cd /opt/apps/valheim

# Start / stop / restart
docker compose up -d
docker compose down
docker compose restart

# View logs (live)
docker compose logs -f

# Check resource usage
docker stats valheim --no-stream

# Force update check now
docker compose exec valheim \
  supervisorctl start valheim-updater

# List backups
ls -la config/backups/

# Manual backup
docker compose exec valheim \
  supervisorctl start valheim-backup

# List installed mod DLLs
ls config/bepinex/plugins/

# Update a mod (example: Jotunn)
cd config/bepinex/plugins
curl -L -o mod.zip \
  "https://thunderstore.io/package/download/\
AUTHOR/MOD/VERSION/"
unzip -o -j mod.zip "*/ModName.dll" -d .
rm mod.zip
cd /opt/apps/valheim && docker compose restart
```

---

## 13. Gotchas

- **First start takes several minutes** — SteamCMD downloads ~1GB of server files. Don't panic if logs show download progress for a while.
- **`SERVER_PASS`** — if set, must be ≥ 5 characters. Leave empty to disable password.
- **World name is the save filename** — if you ever need to use a different world, change `WORLD_NAME` to match the `.db` filename (without extension) in `config/worlds_local/`.
- **Backups run while server is running** — files may be in an open state. The `.db.old` files in `worlds_local/` are always in a consistent state.
- **Supervisor UI password** — currently matches the server password. Change `SUPERVISOR_HTTP_PASS` in compose.yml if you want them separate.
- **Cartography Table** — shared map requires building this in-game. It's a 2-star workbench craft. Each player must interact with it individually to upload/download map data.
- **Jotunn version must match** — r2modman installs the latest Jotunn on clients. If the server's Jotunn is older, you'll get a "version incompatible" error on connect. Update the server's `Jotunn.dll` to match.
- **Launch from r2modman, not Steam** — launching Valheim directly from Steam won't load BepInEx or mods. Always use "Start modded" in r2modman.
- **Thunderstore zip structure** — mod DLLs are usually in a `plugins/` subdirectory inside the zip, not at root. Use `unzip -o -j` with `-j` to flatten paths when extracting.
