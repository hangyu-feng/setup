# Connecting to the Desynced Server

**Port:** UDP 10099

---

## Option 1: Local Network (same WiFi/LAN)

Connect directly using the server's local IP:

```
10.0.0.50:10099
```

---

## Option 2: IPv6 (if your ISP supports it)

If you have IPv6, connect directly:

```
[2601:600:9281:3300::21a3]:10099
```

Only works if your ISP provides IPv6. Most modern home connections do — try it first.

---

## Option 3: Tailscale (recommended for friends)

1. Get invited to the shared Tailscale network (ask the host)
2. Install Tailscale: https://tailscale.com/download
3. Sign in and connect
4. Connect in-game using the Tailscale IP provided by the host

> This is the most reliable option for players outside the local network.

---

## Option 4: Direct IP (port forward required)

If the host has set up a port forward on their router, connect using the public IP:

```
73.221.16.219:10099
```

Note: home IPs can change unless you have a static IP or DDNS set up.

---

## Not Supported

- **Cloudflare Tunnel** — TCP only, does not support UDP
- **Tailscale Funnel** — TCP/HTTPS only, does not support UDP
