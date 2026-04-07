# PROXMOX.md — Homelab Documentation

> This file is maintained by Claude Code. Update it after every significant change.
> Read `CLAUDE.md` for instructions on how to keep this file current.

---

## Changelog

| Date | Change |
|---|---|
| 2026-03-19 | Initial documentation written |
| 2026-03-19 | VM 111 (gameserver) created and configured |
| 2026-03-19 | Docker installed on gameserver; static IP `10.0.0.50`; SSH key auth configured |
| 2026-03-19 | Desynced dedicated server deployed (Wine+Docker, UDP 10099) |
| 2026-03-19 | Scaphandre v1.0.2 installed on Proxmox host |
| 2026-03-21 | Tailscale installed on gameserver with SSH enabled |
| 2026-03-21 | `proxy` Docker network created; Caddy and AdGuard Home deployed |
| 2026-03-21 | Caddy `tls internal` configured; Tailscale split DNS + AdGuard rewrite for `adguard.gameserver` |
| 2026-03-21 | AdGuard Home set as Tailscale global nameserver with override local DNS; split DNS entry for `gameserver` kept |
| 2026-03-23 | Monitoring stack deployed: Prometheus, Grafana, cAdvisor, Node Exporter, Uptime Kuma |
| 2026-03-23 | Scaphandre Prometheus exporter enabled as systemd service on `diu` |
| 2026-03-23 | Caddy updated with `grafana.gameserver` and `uptime.gameserver`; AdGuard DNS rewrites added |
| 2026-03-23 | Custom Docker Containers Grafana dashboard created (community dashboards incompatible with cAdvisor label format) |
| 2026-03-24 | Valheim dedicated server deployed and verified: vanilla, Tailscale-only, Supervisor UI via Caddy, UDP 2456-2457 |
| 2026-03-25 | CUPS print server deployed in Alpine LXC 112 with Tailscale; HP ENVY 6155e added via IPP |
| 2026-04-02 | Valheim: fixed backup retention (MAX_AGE=0 was deleting all zips); changed to 10-min interval, keep 10, 7-day max age |
| 2026-04-02 | Valheim: TZ changed from America/Chicago to America/Los_Angeles |
| 2026-04-02 | Valheim: added mods — AdventureBackpacks, Mining, Sailing, YamlDotNet; removed SkilledCarryWeight |
| 2026-04-02 | Valheim: world restored to 7:53 PM PDT save; manual backup in worlds_local_backup_20260402_204007 |

---

## 1. Host Node — `diu`

### Hardware
| Component | Details |
|---|---|
| CPU | Intel Core i5-12600K (12th Gen, 16 threads) |
| RAM | 62.58 GB |
| Boot disk | 93.93 GB (local) |
| Storage | ZFS-1: 3.62 TB total, ~2.51 TB free |
| Network | Single NIC `enp0s31f6`, bridged to `vmbr0` |

### Network
| Setting | Value |
|---|---|
| IP | `10.0.0.254/24` |
| Gateway | `10.0.0.1` |
| Bridge | `vmbr0` (all VMs and CTs attach here) |
| Domain | `vailgrass.com` |

### Software
- Proxmox VE 8.4.17
- Kernel: Linux 6.8.12-20-pve
- Boot mode: EFI
- Storage pools: `local`, `local-lvm`, `ZFS-1`, `ZFS-2`
- Scaphandre v1.0.2 (power monitoring) — Prometheus exporter on `:8080` (systemd: `scaphandre-exporter.service`)

---

## 2. Virtual Machines

| VMID | Name | RAM | Disk | Status | Purpose |
|---|---|---|---|---|---|
| 103 | openmediavault | 16 GB | 64 GB | stopped | NAS/media storage |
| 104 | dockersdock | 4 GB | 32 GB | stopped | Docker host (general) |
| 107 | pzserver | 8 GB | 64 GB | stopped | Project Zomboid game server |
| 111 | gameserver | 16 GB | 50 GB | running | Game server host (Docker) |

---

## 3. LXC Containers

| VMID | Name | Status | Purpose |
|---|---|---|---|
| 100 | jellyfin-old | stopped | Old Jellyfin media server |
| 101 | downloader | stopped | Download automation |
| 102 | pihole | stopped | DNS ad-blocking |
| 105 | ddns | stopped | Dynamic DNS updater |
| 106 | mounter | stopped | Mount helper |
| 108 | cloudflared | stopped | Cloudflare tunnel |
| 109 | transmission | stopped | BitTorrent client |
| 110 | jellyfin | stopped | Jellyfin media server |
| 112 | cups | running | CUPS print server (Alpine 3.23, Tailscale) |

---

## 4. VM 111 — `gameserver`

### Specs
| Setting | Value |
|---|---|
| OS | Debian GNU/Linux 13 (Trixie) |
| Kernel | 6.12.74+deb13+1-amd64 |
| vCPU | 8 cores, type: `host` |
| RAM | 16 GB |
| Disk | 50 GB on ZFS-1, VirtIO SCSI, discard=on, iothread=on |
| Network | VirtIO, bridge `vmbr0` |
| BIOS | OVMF (UEFI) |
| Machine | q35 |
| QEMU Agent | enabled |

### Network
| Setting | Value |
|---|---|
| Static IPv4 | `10.0.0.50/24` |
| Tailscale IP | `100.93.238.124` |
| Gateway | `10.0.0.1` |
| Interface | `ens18` |
| IPv6 | SLAAC via router |
| Hostname | `gameserver.vailgrass.com` |

### SSH Access
```bash
ssh gameserver               # via ~/.ssh/config (LAN)
ssh root@gameserver          # via Tailscale MagicDNS
ssh root@10.0.0.50           # direct LAN
```

`~/.ssh/config`:
```
Host gameserver
    HostName 10.0.0.50
    User root
    IdentityFile ~/.ssh/id_ed25519

Host gameserver-ts
    HostName gameserver
    User root
```

Emergency access via Proxmox host: `qm terminal 111` (exit with Ctrl+O)

### Installed Software
- Docker CE (latest stable, official Docker repo)
- docker-compose-plugin (`docker compose` CLI)
- qemu-guest-agent
- Tailscale (SSH enabled via `tailscale up --ssh`)
- vim, htop, curl, wget, git

### Docker
- Daemon enabled on boot: `systemctl enable docker`
- TRIM timer enabled: `systemctl enable fstrim.timer` (important for ZFS-backed disk)

---

## 5. Apps & Game Servers

All Docker apps live under `/opt/apps/`. Each app has its own subdirectory with a `compose.yml`.

**Docker network:** `proxy` (bridge, external — shared by Caddy and all proxied apps)

```
/opt/apps/
├── adguard-home/
│   ├── compose.yml
│   ├── conf/              (config — persisted via volume)
│   └── work/              (runtime data — persisted via volume)
├── caddy/
│   ├── compose.yml
│   ├── Caddyfile
│   ├── data/              (certs — persisted via volume)
│   └── config/            (auto-config — persisted via volume)
├── desynced/
│   ├── Dockerfile
│   ├── compose.yml
│   ├── entrypoint.sh
│   ├── server/            (save data — persisted via volume)
│   └── cache/             (Wine prefix — persisted via volume)
├── monitoring/
│   ├── compose.yml
│   ├── prometheus/
│   │   ├── prometheus.yml
│   │   └── rules/
│   │       └── aggregation.yml
│   ├── grafana/
│   │   └── data/          (persisted via volume)
│   └── uptime-kuma/
│       └── data/          (persisted via volume)
└── valheim/
    ├── compose.yml
    ├── .env               (DISCORD_WEBHOOK)
    ├── config/            (world saves, backups — persisted via volume)
    │   ├── worlds_local/  (vailgrass_world.db, .fwl)
    │   ├── backups/       (zip backups, max 10, 7-day retention)
    │   ├── worlds_local_backup_*/  (manual backups)
    │   └── bepinex/
    │       └── plugins/   (mod DLLs)
    └── server/            (Valheim server binaries — persisted via volume)
```

### Deployed Apps
| App | Status | Path | Notes |
|---|---|---|---|
| Caddy | running | `/opt/apps/caddy/` | Reverse proxy, ports 80/443; `tls internal` for `*.gameserver` hostnames |
| AdGuard Home | running | `/opt/apps/adguard-home/` | DNS ad-blocking, port 53 (TCP+UDP); web UI at `https://adguard.gameserver` |
| Desynced | running | `/opt/apps/desynced/` | Wine+SteamCMD, App ID 2943070, UDP 10099 |
| Prometheus | running | `/opt/apps/monitoring/` | Metrics store, 2d raw retention + recording rules for hourly/daily aggregates |
| Grafana | running | `/opt/apps/monitoring/` | Dashboards at `https://grafana.gameserver` |
| cAdvisor | running | `/opt/apps/monitoring/` | Per-container CPU/memory/network/disk metrics |
| Node Exporter | running | `/opt/apps/monitoring/` | VM-level system metrics |
| Uptime Kuma | running | `/opt/apps/monitoring/` | Service health monitoring at `https://uptime.gameserver` |
| Valheim | running | `/opt/apps/valheim/` | Modded dedicated server (BepInEx), UDP 2456-2457; Supervisor UI at `https://valheim.gameserver` |
| Watchtower | planned | `/opt/apps/watchtower/` | Auto-updates containers with `com.centurylinklabs.watchtower.enable=true` label |

### Valheim

**Mods (BepInEx):** All mods require matching client-side installation.

| Mod | Author | Description |
|---|---|---|
| Jotunn | ValheimModding | Modding library (dependency) |
| YamlDotNet | ValheimModding | YAML library (dependency) |
| AdventureBackpacks | Vapok | Progression-based backpacks per biome |
| AzuCraftyBoxes | Azumatt | Craft from nearby containers |
| AzuExtendedPlayerInventory | Azumatt | Extra inventory rows, equipment slots, quick slots |
| Mining | Smoothbrain | Mining skill — more damage + yield |
| Sailing | Smoothbrain | Sailing skill — faster ships + exploration radius |
| MultiUserChest | MSchmoecker | Multiple players use same chest |
| PlantEverything | Advize | Plant any resource anywhere |
| PlantEasily | Advize | Bulk planting with grid snapping |
| QuickStackStore | goldenrevolver | Quick stack, sort, trash, restock |
| TargetPortal | Smoothbrain | Target any portal from map UI |
| TeleportEverything | OdinPlus | Teleport with restricted items |

**Backups:**
- Container zip backups: every 10 min, keep 10, 7-day max age, skip when idle
- Game engine autosave: every 30 min (default), keeps `.db.old` + 4 `_backup_auto-*` files
- Manual backups: `config/worlds_local_backup_<timestamp>/` (not auto-deleted)

To make a manual backup:
```bash
cp -a /opt/apps/valheim/config/worlds_local \
  /opt/apps/valheim/config/worlds_local_backup_$(date +%Y%m%d_%H%M%S)
```

### Caddy

Local Caddyfile: `caddy/Caddyfile` in this repo. Always edit locally, then SCP to server.

- All `*.gameserver` hostnames use `tls internal` (not public TLDs, Let's Encrypt will reject them)
- Deploy: `scp caddy/Caddyfile gameserver:/opt/apps/caddy/Caddyfile`
- Reload: `ssh gameserver "docker exec caddy caddy reload --config /etc/caddy/Caddyfile"`

---

## 6. Workflows

### Adding a New App or Game Server

1. SSH into gameserver: `ssh gameserver`
2. Create directory: `mkdir -p /opt/apps/<appname>`
3. Write compose file — attach to `proxy` network if it needs Caddy proxying
4. Start: `cd /opt/apps/<appname> && docker compose up -d`
5. If public port needed: forward on router (`10.0.0.1`) to `10.0.0.50`, add to section 7
6. Update this file: add to deployed apps table

### Adding a New Internal Service via Caddy

1. Edit `caddy/Caddyfile` locally (this repo), add a block:
```
<name>.gameserver {
    reverse_proxy <container-name>:<port>
    tls internal
}
```
2. SCP to server: `scp caddy/Caddyfile gameserver:/opt/apps/caddy/Caddyfile`
3. Reload Caddy: `ssh gameserver "docker exec caddy caddy reload --config /etc/caddy/Caddyfile"`
4. Add DNS rewrite in AdGuard: `<name>.gameserver` → `100.93.238.124`

### Updating All Running Stacks

Pull latest images and recreate containers for every running compose stack in `/opt/apps/`. Scripts are in this repo.

| OS | Command |
|---|---|
| **Windows** | `powershell -File update-stacks.ps1` |
| **Linux/macOS** | `bash update-stacks.sh` |

Both scripts SSH into `gameserver` remotely — no need to log in first.

### Trusting Caddy's Internal CA

All `*.gameserver` sites use `tls internal`, so browsers show a cert warning by default. Install Caddy's root CA once per device to fix this.

**Get the cert** (from any machine with SSH access to gameserver):
```bash
ssh gameserver "docker exec caddy cat /data/caddy/pki/authorities/local/root.crt" > caddy-root-ca.crt
```

A copy is kept in this repo at `caddy-root-ca.crt`.

| OS | Steps |
|---|---|
| **Windows** | Double-click `caddy-root-ca.crt` → Install Certificate → Local Machine → "Trusted Root Certification Authorities" → Finish |
| **macOS** | Double-click → add to login Keychain → open Keychain Access → find "Caddy Local Authority" → Get Info → Trust → "Always Trust" |
| **Linux** | `sudo cp caddy-root-ca.crt /usr/local/share/ca-certificates/caddy-root-ca.crt && sudo update-ca-certificates` |
| **iOS** | AirDrop/email the `.crt` → Install Profile → Settings → General → About → Certificate Trust Settings → enable "Caddy Local Authority" |
| **Android** | Settings → Security → Encryption & credentials → Install a certificate → CA certificate → select file |

Restart the browser after installing.

### Adding a New VM to Proxmox

Recommended settings:
| Setting | Value |
|---|---|
| Machine | q35 |
| BIOS | OVMF (UEFI) |
| CPU type | host |
| Network | VirtIO, bridge vmbr0 |
| Disk bus | VirtIO SCSI single, discard=on, iothread=on |
| QEMU Agent | enabled |

Use `ZFS-1` for VM disks. Avoid `local-lvm` for large VMs.

---

## 7. Network

### Static IPs
| IP | Host |
|---|---|
| `10.0.0.1` | Home router / gateway |
| `10.0.0.254` | Proxmox host (diu) |
| `10.0.0.50` | gameserver (VM 111) |
| `10.0.0.51` | cups (LXC 112) |
| `100.93.238.124` | gameserver (Tailscale) |
| `100.87.48.68` | cups (Tailscale) |

### Port Forwards (Router → gameserver `10.0.0.50`)
| App | Protocol | Port | Status |
|---|---|---|---|
| Desynced | UDP | 10099 | active |

### Internal DNS (`*.gameserver`)

All Tailscale clients route DNS through AdGuard Home:

| Layer | Config |
|---|---|
| Tailscale admin → Global nameserver | `100.93.238.124` (AdGuard Home), override local DNS enabled |
| Tailscale admin → Split DNS | `gameserver` → `100.93.238.124` (kept alongside global nameserver) |
| AdGuard DNS rewrites | `adguard.gameserver`, `grafana.gameserver`, `uptime.gameserver`, `valheim.gameserver` → `100.93.238.124` |
| Caddy TLS | `tls internal` (Caddy's local CA — not Let's Encrypt) |

To add a new `*.gameserver` hostname: see "Adding a New Internal Service via Caddy" in section 6.

### Public Access for Game Servers

Friends connect via Tailscale node sharing — gameserver is shared from personal tailnet to a separate friends tailnet. Friends install Tailscale, join the friends tailnet, and connect to `100.93.238.124:<port>`.

---

## 8. Monitoring

Full monitoring stack deployed. See `MONITORING.md` for architecture, configuration, retention strategy, and recording rules.

| Component | Location | Access |
|---|---|---|
| Scaphandre exporter | `diu` (systemd: `scaphandre-exporter.service`) | `:8080/metrics` |
| Prometheus | gameserver (Docker) | internal only (no host port) |
| Grafana | gameserver (Docker) | `https://grafana.gameserver` |
| cAdvisor | gameserver (Docker) | internal only |
| Node Exporter | gameserver (Docker) | internal only |
| Uptime Kuma | gameserver (Docker) | `https://uptime.gameserver` |

**Retention:** raw 15s → 1 day, hourly aggregates → 7 days, daily aggregates → forever.

**Limitations:** RAPL measures CPU package power only — no IPMI/BMC on this board, no PSU wattage readout. For true wall draw, use a smart plug.

**CLI quick check** (on `diu`):
```bash
scaphandre stdout                              # total host + top consumers
scaphandre --vm stdout --process-regex qemu    # per-VM breakdown
```

---

## 9. Known Issues

| Issue | Status | Notes |
|---|---|---|
| ZFS-2 pool not visible in `zpool list` | unresolved | Visible in UI but not imported — run `zpool import` to investigate |
| Non-production Proxmox repo enabled | low priority | May receive unstable updates — switch to `pve-no-subscription` for stability |
| `PermitRootLogin yes` on gameserver | todo | Change to `prohibit-password` once Windows SSH key is confirmed working |
| All legacy VMs/containers stopped | unknown | Unclear which are still needed — audit before starting any |

> This file is maintained by Claude Code. Update it after every significant change.
> Read `CLAUDE.md` for instructions on how to keep this file current.
