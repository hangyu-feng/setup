# CUPS Print Server — LXC Container on Proxmox

Remote printing via CUPS + Tailscale. Print from anywhere on the Tailnet to a WiFi printer on the home LAN.

## Architecture

```
You (remote, on Tailnet)
  → CUPS in LXC (on Tailnet + home LAN)
    → Printer (home LAN only, WiFi)
```

- CUPS LXC is on the same subnet as the printer (`10.0.0.x`)
- Tailscale on the LXC lets you reach CUPS from anywhere
- The printer does NOT need to be on the Tailnet

---

## Container Details

| Setting | Value |
|---|---|
| VMID | 112 |
| Hostname | `cups` |
| OS | Alpine 3.23 |
| RAM | 256 MB |
| Disk | 2 GB (local-lvm) |
| Cores | 1 |
| Static IP | `10.0.0.51/24` |
| Tailscale IP | `100.87.48.68` |
| CUPS version | 2.4.16 |
| CUPS Web UI | `https://100.87.48.68:631` |
| CUPS admin user | `cupsadmin` (in `lpadmin` + `sys` groups) |

### Printer

| Setting | Value |
|---|---|
| Model | HP ENVY 6155e |
| Hostname | `HPIB47474` |
| LAN IP | `10.0.0.26` |
| Connection | `ipp://10.0.0.26/ipp/print` |
| Driver | IPP Everywhere |
| CUPS name | `HP-Envy-6155e` |

---

## 1. Create LXC Container on Proxmox

From Proxmox host (`diu`):

```bash
pct create 112 local:vztmpl/alpine-3.23-default_20260116_amd64.tar.xz \
  --hostname cups \
  --memory 256 \
  --cores 1 \
  --rootfs local-lvm:2 \
  --net0 name=eth0,bridge=vmbr0,ip=10.0.0.51/24,gw=10.0.0.1 \
  --nameserver 10.0.0.1 \
  --unprivileged 1 \
  --features nesting=1 \
  --start 1
```

Then enable TUN device for Tailscale:

```bash
pct stop 112
pct set 112 --dev0 /dev/net/tun
pct start 112
```

> **Notes:**
> - VMID `112` — next available after gameserver (111)
> - Static IP `10.0.0.51` — must be on same subnet as printer
> - 256 MB RAM / 1 core / 2 GB disk — Alpine + CUPS is tiny
> - `nesting=1` required for Tailscale to work in unprivileged LXC
> - `/dev/net/tun` passthrough required for Tailscale

---

## 2. Install CUPS

```bash
pct enter 112

# Enable community repo (needed for cups and tailscale packages)
sed -i 's|#\(.*\/community\)|\1|' /etc/apk/repositories

# Update and install CUPS
apk update
apk add cups cups-filters

# Enable and start CUPS (Alpine uses OpenRC, not systemd)
rc-update add cupsd default
rc-service cupsd start

# Allow remote connections
cupsctl --remote-any --share-printers
```

### Configure CUPS access

Replace `/etc/cups/cupsd.conf` — the config file is kept in this repo at `cupsd.conf`.

From your local machine:
```bash
scp cupsd.conf root@10.0.0.254:/root/cupsd.conf
```

From Proxmox host:
```bash
pct push 112 /root/cupsd.conf /etc/cups/cupsd.conf
```

Key changes from default:
- `Listen localhost:631` → `Port 631` (listen on all interfaces)
- Added `Allow 10.0.0.*` and `Allow 100.64.0.0/10` to all `<Location>` blocks (LAN + Tailscale access)

Restart CUPS:

```bash
rc-service cupsd restart
```

### Create an admin user for CUPS web UI

Alpine doesn't have a root password by default, and CUPS admin pages require authentication:

```bash
adduser -D cupsadmin
passwd cupsadmin
addgroup cupsadmin lpadmin
addgroup cupsadmin sys
```

Use these credentials when CUPS prompts for admin login.

---

## 3. Install Tailscale

```bash
apk add tailscale

# Service name on Alpine 3.23 is "tailscale", not "tailscaled"
rc-update add tailscale default
rc-service tailscale start

tailscale up --ssh
```

Authenticate via the URL shown, then verify:

```bash
tailscale ip -4   # → 100.87.48.68
```

---

## 4. Add Printer

mDNS discovery does NOT work in unprivileged LXC containers — add the printer manually by IP.

1. Open `https://100.87.48.68:631`
2. **Administration** → **Add Printer**
3. Log in with `cupsadmin` credentials
4. Select **Internet Printing Protocol (ipp)**
5. Connection URL: `ipp://10.0.0.26/ipp/print`
6. Name: `HP-Envy-6155e`, Description: `HP ENVY 6155e`
7. Check **Share This Printer**
8. Make: **HP**, Model: **IPP Everywhere**
9. Click **Add Printer**, then **Set Default Options**

> **Important:** Use the printer's IP address, not hostname — the container can't resolve mDNS hostnames.

---

## 5. Print from Client Devices

All devices must be on the Tailnet to reach CUPS.

### Windows

1. Settings → Printers & scanners → Add a printer
2. "The printer that I want isn't listed"
3. Select "Select a shared printer by name"
4. Enter: `http://100.87.48.68:631/printers/HP-Envy-6155e`

### macOS

1. System Settings → Printers & Scanners → Add Printer
2. Click the IP tab
3. Address: `100.87.48.68`, Protocol: IPP
4. Queue: `/printers/HP-Envy-6155e`

### iOS

Should work via AirPrint if on the Tailnet. If not:
```
ipp://100.87.48.68:631/printers/HP-Envy-6155e
```

### Android

Settings → Connected devices → Printing → Default Print Service → add printer at:
```
ipp://100.87.48.68:631/printers/HP-Envy-6155e
```

---

## 6. DNS (Optional)

If you want `cups.gameserver` to reach the web UI:

1. Add AdGuard DNS rewrite: `cups.gameserver` → `100.87.48.68`
2. Note: CUPS web UI runs on `:631`, not `:443`, so Caddy proxying is optional

---

## Checklist

- [x] Create LXC 112 on Proxmox
- [x] Enable TUN device passthrough
- [x] Install CUPS and configure access
- [x] Create `cupsadmin` user
- [x] Install Tailscale and authenticate
- [x] Add HP ENVY 6155e by IP
- [ ] Test printing from a Tailnet device
- [ ] Add to `PROXMOX.md`
