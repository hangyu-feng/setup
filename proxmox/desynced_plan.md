# Desynced Server — Setup & Friend Access Plan

**Goal:** Run a Desynced dedicated server (Wine+Docker on gameserver) and allow a friend to connect via a second Tailscale tailnet.

---

## 1. Server Setup

### Docker Stack

Container runs Wine64 + Xvfb to host the UE5 Windows dedicated server binary.

| Component | Details |
|---|---|
| Base image | `steamcmd/steamcmd:ubuntu-24` |
| Wine | `wine64` 9.0 (64-bit only) |
| Display | Xvfb on `:99` |
| Game files | SteamCMD app 2943070, installed to `/opt/desynced` |
| Port | UDP 10099 |
| Path on server | `/opt/apps/desynced/` |

Files:
- `Dockerfile` — builds image with SteamCMD + wine64 + Xvfb
- `entrypoint.sh` — starts Xvfb, initializes Wine prefix, launches server (bind-mounted for easy updates)
- `compose.yml` — container config, volumes, port mapping
- `build.sh` — wrapper that prompts for Steam password and passes as build args

### Issues Fixed

| Issue | Root Cause | Fix |
|---|---|---|
| `xvfb-run` hangs forever | `xdpyinfo` not installed (required by `xvfb-run`) | Replaced with direct `Xvfb` launch |
| "Bad EXE format" | Only `wine32:i386` installed; server exe is 64-bit | Switched to `wine64` package |
| `wine: not found` | `wine64` package provides binary at `/usr/lib/wine/wine64`, not in `$PATH` | Use full path in entrypoint |
| `wineboot: command not found` | Same PATH issue | Call via `/usr/lib/wine/wine64 wineboot` |
| X99 lock stale on crash | Xvfb leaves `/tmp/.X99-lock` after crash | Added `rm -f /tmp/.X99-lock` at startup |
| Local/server Dockerfile drift | Local used `COPY desynced-files/`, server used SteamCMD | Synced local to SteamCMD approach |
| SessionSettings JSON parse error | Wine's Windows command-line parsing splits on spaces | Removed settings args for now (uses defaults) |

### Useful Commands

```bash
# Rebuild (requires Steam password)
cd /opt/apps/desynced && ./build.sh

# Start / restart / logs
docker compose up -d
docker compose restart
docker compose logs -f --tail=50

# Update entrypoint without rebuild (bind-mounted)
scp desynced/entrypoint.sh gameserver:/opt/apps/desynced/entrypoint.sh
docker compose restart
```

---

## 2. Save Migration

Copy a local save to the server's Wine prefix:

```bash
# Create save directory
ssh gameserver "mkdir -p /opt/apps/desynced/cache/drive_c/users/root/AppData/Local/Desynced/Saved/SaveGames"

# Copy save file (rename to match WORLD_NAME)
scp "C:/Users/VailG/AppData/Local/Desynced/Saved/SaveGames/Freeplay 2026-03-21 13.16.13.desynced" \
    "gameserver:/opt/apps/desynced/cache/drive_c/users/root/AppData/Local/Desynced/Saved/SaveGames/World1.desynced"

# Restart to load
ssh gameserver "cd /opt/apps/desynced && docker compose restart"
```

---

## 3. Friend Access via Tailscale

### Architecture

```
Your personal tailnet
└── gameserver (100.93.238.124) ──[node share]──> friends tailnet
                                                       └── friend's device
```

- You own both tailnets (different email addresses)
- Gameserver is shared from personal tailnet to friends tailnet
- Friend joins friends tailnet and connects to `<shared-node-ip>:10099`

### Steps

1. **Share gameserver node** — Personal Tailscale admin → Machines → gameserver → Share → enter friends tailnet email
2. **Invite friend** — Friends tailnet admin → Users → Invite → enter friend's email
3. **Friend installs Tailscale** — Downloads from tailscale.com, signs in with invite, authorizes device
4. **Find shared IP** — Friends tailnet admin shows the `100.x.x.x` IP, or friend runs `tailscale status`
5. **Connect in-game** — Friend enters `<shared-node-ip>:10099` in Desynced

No port forwarding needed — traffic goes over the Tailscale tunnel.

### Access Control

Default ACLs allow full access between peers (fine for a friend group).
To revoke: Personal tailnet admin → Machines → gameserver → Remove share.

---

## 4. TODO: SessionSettings

The `-SessionSettings` and `-GameSettings` CLI args are **disabled** in `entrypoint.sh`. Wine's command-line reconstruction breaks JSON — the server only receives the first `{` regardless of quoting strategy.

### What was tried
- `-SessionSettings='{"key":"val"}'` — Wine strips quotes, splits on colons/commas
- `-SessionSettings={"key":"val"}` (no spaces in JSON, `=` syntax) — Wine still splits, server only sees `{`
- Removing spaces from values (e.g. `DesyncedServer`) — didn't help, the JSON structure itself gets mangled

### Possible alternatives (not yet tried)
- Check if Desynced reads a `ServerSettings.ini` or config file from the save directory
- Write a Windows `.bat` wrapper inside the Wine prefix that handles quoting natively
- Check if the server reads settings from environment variables directly
- Investigate Wine's `WINEDLLOVERRIDES` or registry for argument pass-through

### Settings that need to be configured
- ServerName, MaxPlayers, Visibility, RunWithoutPlayers
- ResourceRichness, BlightThreshold, PeacefulMode

---

## Checklist

### Server
- [x] Dockerfile with SteamCMD + wine64 + Xvfb
- [x] entrypoint.sh — starts Xvfb, Wine prefix init, launches server
- [x] compose.yml with bind-mounted entrypoint
- [x] Server starts and listens on UDP 10099
- [ ] Confirm server stays running stable (no crashes)
- [x] Copy local save file to server
- [x] Verify save loads correctly
- [ ] Fix SessionSettings/GameSettings CLI args (blocked — see section 4)

### Friend Access
- [x] Create friends tailnet (new email)
- [x] Local PC joined friends tailnet
- [x] Share gameserver node from personal tailnet to friends tailnet
- [x] Invite friend to friends tailnet
- [ ] Friend installs Tailscale and joins
- [ ] Friend connects to Desynced at `100.93.238.124:10099`
- [ ] Update PROXMOX.md section 9
