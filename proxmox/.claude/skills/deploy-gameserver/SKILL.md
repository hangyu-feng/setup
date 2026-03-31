---
name: deploy-gameserver
description: Deploy a new game server on the gameserver VM. Use when the user wants to set up a new dedicated game server.
disable-model-invocation: true
argument-hint: [game name]
---

# Deploy Game Server: $ARGUMENTS

You are deploying a new dedicated game server for **$ARGUMENTS** on the gameserver VM.
Read `PROXMOX.md` and `CLAUDE.md` before starting. Follow the phases below in order.

---

## Phase 1: Research

Investigate how to run a dedicated server for $ARGUMENTS in Docker.

1. **Search for existing Docker images** — look for community-maintained images on GitHub and Docker Hub. Evaluate by: stars/activity, configuration via env vars, built-in features (backups, auto-update, graceful shutdown), and documentation quality.

2. **Check if a custom Dockerfile is needed** — some games only ship Windows server binaries (like Desynced needed Wine+Xvfb). If no good Docker image exists, investigate:
   - Is there a Linux dedicated server binary? (ideal)
   - Is there a SteamCMD app ID for the dedicated server?
   - Does the server require Wine? (adds complexity — see `desynced/` for reference)
   - Is Docker even viable, or would a bare install on the VM be simpler?

3. **Identify key server properties:**
   - Game ports (TCP/UDP) and what each port does
   - Expected RAM and CPU usage (idle and under load)
   - Save file location and format
   - Configuration method (env vars, config files, CLI args)
   - Graceful shutdown behavior (does it need time to save?)
   - Update mechanism (SteamCMD, built-in, manual)

4. **Present findings as a comparison table** if there are multiple image options. Include trade-offs. Make a recommendation.

---

## Phase 2: Interview

Ask the user the following questions. Don't assume defaults — let the user decide. Ask all questions in a single message.

- **Server name and world/save name** — what should they be called?
- **Password** — is one needed? Any requirements (min length, etc.)?
- **Visibility** — public (Steam server browser) or private (Tailscale only)?
- **Max players** — how many?
- **Mods** — vanilla or modded? If modded, which mod framework?
- **Game-specific settings** — difficulty, map size, game mode, etc. (varies by game — research what's configurable in Phase 1)
- **Web UI** — does the chosen image have a management UI? Should it be exposed via Caddy?
- **Backups** — frequency, retention count, idle-skip?
- **Auto-update** — should the server auto-update? Schedule? Only when empty?
- **Port forwarding** — does this need a router port forward (public) or is Tailscale-only sufficient?
- **Save migration** — does the user have an existing save to import?

---

## Phase 3: Plan

Create a deployment plan as a markdown file at `<game>/plan.md` in this repo. Use the Valheim plan (`valheim.md`) as a structural reference. The plan should include:

1. **Image selection** — which image and why (or Dockerfile approach if custom)
2. **Server configuration** — table of all settings with chosen values
3. **Compose file** — complete `compose.yml` ready to deploy
4. **Persistent storage** — directory tree showing mounts and what each stores
5. **Networking** — ports, protocols, exposure method, Caddy block if applicable
6. **Resource estimate** — expected RAM/CPU idle and under load, headroom on the VM
7. **Backup strategy** — if applicable
8. **Deployment steps** — numbered steps with verification commands after each
9. **Gotchas** — anything non-obvious learned during research

### Compose file conventions (from past deployments):

- Path: `/opt/apps/<game>/compose.yml`
- Container name: `<game>` (lowercase, no prefix)
- `restart: unless-stopped`
- Add `stop_grace_period` if the server needs time to save on shutdown
- Add `cap_add: [sys_nice]` if Steam/game server sets thread priority
- Join the `proxy` network if exposing a web UI via Caddy
- Use bind mounts (`./config:/config`) not named volumes
- Add `logging.options` with `max-size: 5m` and `max-file: 3` for custom images without log rotation
- Set `TZ=America/Chicago`

### Checklist (append to plan):

Generate a checklist of all deployment and verification steps. Mark nothing as complete yet.

Present the plan to the user for review before proceeding.

---

## Phase 4: Validate

Before executing, verify with the user:

- Review the compose file — any changes?
- Review the Caddyfile addition (if applicable)
- Review port forwards needed (if applicable)
- Confirm the plan looks good

If the user requests changes, update the plan file and compose file accordingly.

---

## Phase 5: Execute

Deploy step by step. After each step, verify before moving to the next.

1. **Write local files** — create `<game>/compose.yml` (and `Dockerfile`, `entrypoint.sh` if custom build) in this repo
2. **Create server directory** — `ssh gameserver "mkdir -p /opt/apps/<game>"`
3. **Copy files to server** — `scp` compose file (and Dockerfile, entrypoint, etc.) to gameserver
4. **Pull/build and start** — `docker compose pull && docker compose up -d` or `docker compose build && docker compose up -d`
5. **Watch logs** — `docker compose logs -f` until the server is fully started. Note what "ready" looks like in the logs.
6. **Update Caddyfile** (if web UI) — edit locally, SCP, reload Caddy, add AdGuard DNS rewrite
7. **Verify game connection** — guide the user through connecting from their game client
8. **Verify backups** (if applicable) — wait for first backup cycle, confirm files appear
9. **Import save** (if applicable) — copy save files to the correct location, restart
10. **Update PROXMOX.md** — add to deployed apps table, directory tree, port forwards, DNS rewrites as applicable
11. **Update plan checklist** — mark all completed steps

---

## Reference: Past Deployments

### Valheim (community image)
- **Image:** `ghcr.io/community-valheim-tools/valheim-server` — well-maintained, all config via env vars
- **Pattern:** pull image, configure via environment, bind-mount config + server dirs
- **Web UI:** Supervisor HTTP on port 9001, proxied via Caddy
- **Backups:** Built into the image (cron-based, zip, retention count)
- **Gotchas:** first start downloads ~1GB, `SERVER_PASS` must be >= 5 chars, needs `stop_grace_period: 2m`, `cap_add: sys_nice`

### Desynced (custom Dockerfile)
- **Approach:** No Linux server binary — built custom image with Wine64 + Xvfb + SteamCMD
- **Pattern:** Dockerfile builds image with game files baked in, entrypoint.sh handles Wine setup
- **Build requires:** Steam credentials passed as build args (not stored in image)
- **Gotchas:** Wine breaks JSON CLI args, `xvfb-run` hangs without `xdpyinfo`, must use `/usr/lib/wine/wine64` full path
- **Lesson:** If a game only has a Windows server binary, expect Wine issues. Budget extra time for debugging.

### Common patterns across both:
- All files live under `/opt/apps/<game>/`
- Compose file named `compose.yml`
- Local copies of config files kept in this repo under `<game>/`
- Edit locally first, SCP to server
- Game ports exposed on host, web UI ports kept internal (Caddy proxies them)
- Monitoring via Uptime Kuma + cAdvisor (already running)
