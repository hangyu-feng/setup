# PROXMOX.md — Homelab Documentation

> This file is maintained by Claude Code. Update it after every significant change.
> Read `CLAUDE.md` for instructions on how to keep this file current.

---

## Changelog

| Date | Change |
|---|---|
| 2026-03-19 | Initial documentation written |
| 2026-03-19 | VM 111 (gameserver) created and configured |
| 2026-03-19 | Docker installed on gameserver |
| 2026-03-19 | Static IP set to `10.0.0.50` on gameserver |
| 2026-03-19 | SSH key auth configured (Proxmox host → gameserver) |
| 2026-03-19 | Desynced dedicated server deployed and running (Wine+Docker, UDP 10099) |
| 2026-03-19 | Scaphandre v1.0.2 installed on Proxmox host for power monitoring |
| 2026-03-21 | Tailscale installed on gameserver with SSH enabled |

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
- Scaphandre v1.0.2 (power monitoring)

---

## 2. Virtual Machines

| VMID | Name | Type | RAM | Disk | Status | Purpose |
|---|---|---|---|---|---|---|
| 103 | openmediavault | VM | 16 GB | 64 GB | stopped | NAS/media storage |
| 104 | dockersdock | VM | 4 GB | 32 GB | stopped | Docker host (general) |
| 107 | pzserver | VM | 8 GB | 64 GB | stopped | Project Zomboid game server |
| 111 | gameserver | VM | 16 GB | 50 GB | running | Game server host (Docker) |

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
| Gateway | `10.0.0.1` |
| Interface | `ens18` |
| IPv6 | SLAAC via router |
| Hostname | `gameserver.vailgrass.com` |

### SSH Access
```bash
ssh root@10.0.0.50           # local network
ssh root@gameserver          # via Tailscale MagicDNS
ssh gameserver               # via ~/.ssh/config alias
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

```
/opt/apps/
├── <appname>/
│   └── compose.yml
└── desynced/
    ├── Dockerfile
    ├── compose.yml
    ├── entrypoint.sh
    ├── server/            (save data — persisted via volume)
    └── cache/             (Wine prefix — persisted via volume)
```

### Common Commands
```bash
# Start
cd /opt/apps/<appname> && docker compose up -d

# Stop
docker compose down

# Logs
docker compose logs -f

# Restart
docker compose restart

# Update (pre-built image only)
docker compose pull && docker compose up -d

# Rebuild custom image (e.g. after game update)
docker compose build --no-cache && docker compose up -d
```

### Deployed Apps
| App | Status | Path | Notes |
|---|---|---|---|
| Desynced | running | `/opt/apps/desynced/` | Wine+SteamCMD image, App ID 2943070, UDP 10099; local saves at `C:\Users\VailG\AppData\Local\Desynced` |

---

## 6. Adding a New App or Game Server

1. SSH into gameserver: `ssh gameserver`
2. Create directory: `mkdir -p /opt/apps/<appname>`
3. Write compose file: `vim /opt/apps/<appname>/compose.yml`
4. Start: `cd /opt/apps/<appname> && docker compose up -d`
5. If ports need external access, forward them on the router (`10.0.0.1`) to `10.0.0.50`
6. Update this file: add app to section 5, ports to section 7

---

## 7. Network — IP Assignments & Port Forwards

### Static IPs
| IP | Host |
|---|---|
| `10.0.0.1` | Home router / gateway |
| `10.0.0.254` | Proxmox host (diu) |
| `10.0.0.50` | gameserver (VM 111) |

### Port Forwards (Router → gameserver `10.0.0.50`)
| App | Protocol | Port | Status |
|---|---|---|---|
| Desynced | UDP | 10099 | active |

---

## 8. Adding a New VM to Proxmox

### Recommended Settings
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

## 9. Power Monitoring

Scaphandre v1.0.2 installed on Proxmox host (`diu`). Uses Intel RAPL.

> RAPL measures CPU package power only — excludes RAM, disks, NIC, fans. For true wall draw, use a smart plug.

```bash
# Total host + top consumers
scaphandre stdout

# Per-VM breakdown (QEMU processes)
scaphandre --vm stdout --process-regex qemu
```

RAPL is not accessible from inside the gameserver VM — per-container breakdown unavailable without additional VM config.

**Planned: Grafana dashboard**
- Scaphandre as a systemd service with Prometheus exporter on `diu`
- Prometheus + Grafana stack
- Import Hubblo's official Scaphandre dashboard for per-VM wattage graphs

---

## 10. Planned: Public Access for Game Servers

**Goal:** Allow friends to connect to game servers without IPv6 or joining a personal tailnet.

**Constraints:**
- Cloudflare Tunnel — TCP only, no UDP
- Tailscale Funnel/Serve — TCP/HTTPS only, no UDP

**Options:**

| Option | Effort | Notes |
|---|---|---|
| **Tailscale node sharing** | Low | Preferred — see below |
| **Direct IPv6 + DNS AAAA record** | Very low | Only works if friend has IPv6 |
| **Cloudflare Spectrum** | Low | Supports UDP but requires paid plan |
| **VPS UDP relay** | High | VPS forwards UDP home via `socat`/WireGuard |

**Preferred: Tailscale node sharing**
1. Install Tailscale on gameserver — stays on personal tailnet
2. Create a second Tailscale account (different email) as the "friends" tailnet
3. Tailscale admin: Machines → gameserver → **Share** → enter friends' tailnet email
4. Invite friends to the friends' tailnet
5. Friends connect to `<tailscale-ip>:10099` — personal tailnet stays private

**Status:** Tailscale installed on gameserver (step 1 done). Node sharing not yet configured.

---

## 11. Known Issues

| Issue | Status | Notes |
|---|---|---|
| ZFS-2 pool not visible in `zpool list` | unresolved | Visible in UI but not imported — run `zpool import` to investigate |
| Non-production Proxmox repo enabled | low priority | May receive unstable updates — switch to `pve-no-subscription` for stability |
| `PermitRootLogin yes` on gameserver | todo | Change to `prohibit-password` once Windows SSH key is confirmed working |
| All legacy VMs/containers stopped | unknown | Unclear which are still needed — audit before starting any |

> This file is maintained by Claude Code. Update it after every significant change.
> Read `CLAUDE.md` for instructions on how to keep this file current.
