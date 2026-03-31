# MONITORING.md — Power & Service Monitoring

> All monitoring containers run on gameserver (VM 111) under `/opt/apps/monitoring/`.
> Exception: Scaphandre exporter runs as a systemd service on the Proxmox host (`diu`), since RAPL is only accessible on bare metal.

---

## Architecture

```
diu (Proxmox host, 10.0.0.254)          gameserver (VM 111, 10.0.0.50)
┌──────────────────────────┐             ┌──────────────────────────────────┐
│ scaphandre prometheus    │             │ /opt/apps/monitoring/            │
│   exporter :8080/metrics │◄────scrape──│   prometheus        :9090       │
└──────────────────────────┘             │   grafana           :3000       │
                                         │   cadvisor          :8080       │
                                         │   node-exporter     :9100       │
                                         │   uptime-kuma       :3001       │
                                         └──────────────────────────────────┘
                                                      │
                                                   Caddy
                                                      │
                                         grafana.gameserver  (Tailscale only)
                                         uptime.gameserver   (Tailscale only)
```

### Data Flow

1. **Scaphandre** (on `diu`) → host CPU energy counter (RAPL) at `:8080/metrics`
2. **cAdvisor** (on gameserver) → per-container CPU%, memory, network, disk I/O at `:8080/metrics`
3. **Node Exporter** (on gameserver) → VM-level system metrics at `:9100/metrics`
4. **Prometheus** scrapes all three + itself every 15s
5. **Recording rules** roll up raw data into hourly and daily aggregates
6. **Grafana** queries Prometheus for dashboards
7. **Uptime Kuma** monitors service health independently (HTTP/TCP/ping checks)

### What You Can See

| Level | Source | Metrics |
|---|---|---|
| Host CPU watts | Scaphandre | Total package power, core/uncore breakdown (RAPL) |
| VM system stats | Node Exporter | CPU, memory, disk, network, load |
| Per-container resources | cAdvisor | CPU%, memory, network I/O, disk I/O per container |
| Per-container estimated watts | Grafana math | `(container_cpu% / vm_total_cpu%) × host_watts` |
| Service health | Uptime Kuma | Up/down, response time, uptime % |

### Limitations

- RAPL measures **CPU package power only** — excludes RAM, disks, NIC, fans, PSU losses
- No IPMI/BMC on this board (consumer i5-12600K LGA 1700) — verified, `ipmitool` not available
- `lm-sensors` (`nct6798` chip) exposes voltages, fan speeds, temps — but **no power readings**
- True wall draw requires a smart plug with power monitoring

---

## Key Metrics

Scaphandre exposes **energy counters** (microjoules), not power gauges. Use `rate()` to derive watts.

| Metric | Type | Description |
|---|---|---|
| `scaph_host_energy_microjoules` | counter | Total host CPU energy; `rate() / 1e6` = watts |
| `scaph_domain_energy_microjoules{domain_name="core"}` | counter | CPU core domain energy |
| `scaph_domain_energy_microjoules{domain_name="uncore"}` | counter | Uncore domain (memory controller, etc.) |
| `scaph_socket_energy_microjoules` | counter | Per-socket energy |
| `container_cpu_usage_seconds_total{name!="",cpu="total"}` | counter | Per-container CPU usage |
| `container_memory_usage_bytes{name!=""}` | gauge | Per-container memory |

### Useful Queries

```promql
# Current host power in watts
rate(scaph_host_energy_microjoules[5m]) / 1e6

# Per-container CPU usage (%)
rate(container_cpu_usage_seconds_total{name!="",cpu="total"}[5m]) * 100

# Estimated per-container watts
(rate(container_cpu_usage_seconds_total{name!="",cpu="total"}[5m])
  / scalar(sum(rate(container_cpu_usage_seconds_total{cpu="total"}[5m]))))
  * (rate(scaph_host_energy_microjoules[5m]) / 1e6)
```

---

## Retention Strategy

| Tier | Resolution | Retention | Estimated Size |
|---|---|---|---|
| Raw | 15s | 1 day | ~50-80 MB |
| Hourly aggregates | 1h | 7 days | ~2-5 MB |
| Daily aggregates | 1d | forever | ~10 MB/year |

Prometheus `--storage.tsdb.retention.time=2d` (1 day + buffer for recording rule evaluation).

Hourly and daily aggregates are computed by Prometheus **recording rules** and stored as separate time series. With 2d raw retention and lightweight aggregate series, total disk stays well under 1 GB indefinitely.

> Prometheus doesn't support per-series retention. Daily "forever" aggregates survive because they're continuously appended. To truly guarantee forever retention, a future option is VictoriaMetrics (see Future section).

---

## Configuration Reference

### Scaphandre Exporter (on `diu`)

Systemd service: `/etc/systemd/system/scaphandre-exporter.service`

```ini
[Unit]
Description=Scaphandre Prometheus Exporter
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/scaphandre prometheus --port 8080
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
systemctl status scaphandre-exporter
curl -s http://localhost:8080/metrics | grep scaph_host_energy
```

### Monitoring Stack (on gameserver)

Directory: `/opt/apps/monitoring/`

```
/opt/apps/monitoring/
├── compose.yml
├── prometheus/
│   ├── prometheus.yml
│   └── rules/
│       └── aggregation.yml
├── grafana/
│   └── data/              (owned by 472:472)
└── uptime-kuma/
    └── data/
```

Local copies of all config files are in `monitoring/` in this repo. Edit locally, then SCP:

```bash
scp monitoring/compose.yml gameserver:/opt/apps/monitoring/compose.yml
scp monitoring/prometheus/prometheus.yml gameserver:/opt/apps/monitoring/prometheus/prometheus.yml
scp monitoring/prometheus/rules/aggregation.yml gameserver:/opt/apps/monitoring/prometheus/rules/aggregation.yml
ssh gameserver "cd /opt/apps/monitoring && docker compose up -d"
```

### Docker Networks

- `monitoring` — internal bridge for inter-container communication (Prometheus → cAdvisor, etc.)
- `proxy` — external bridge shared with Caddy (Grafana and Uptime Kuma join this for reverse proxying)

### Notes

- **Grafana data directory** must be owned by UID 472: `chown -R 472:472 /opt/apps/monitoring/grafana/data`
- **cAdvisor** runs with `--docker_only=true --store_container_labels=true` to export container `name`/`image` labels
- **Scaphandre** sends blank Content-Type; Prometheus scrape config uses `fallback_scrape_protocol: PrometheusText0.0.4`
- **Prometheus** is not port-exposed to the host — only accessible via the `monitoring` Docker network

---

## Grafana Dashboards

### Docker Containers (custom)

Custom dashboard built for our cAdvisor setup. JSON file: `monitoring/dashboards/docker-monitoring.json`

Import: Grafana → Dashboards → Import → Upload JSON file

Panels: Running containers, CPU/memory per container, network Rx/Tx, filesystem usage.

> The datasource UID in the JSON must match your Prometheus datasource UID in Grafana. Check via: Connections → Data sources → Prometheus → the UID in the URL.

### Node Exporter Full (community)

Import dashboard ID `1860` from grafana.com. Works out of the box with node-exporter.

### Power Overview (build manually)

Create panels using the queries in the Key Metrics section above. Recommended panels:
- Host watts over time
- Core vs uncore power breakdown
- Per-container CPU% (stacked)
- Estimated per-container watts
- Daily energy (Wh) from recording rule `power:host_watthours:sum1d`

---

## Uptime Kuma

Access: `https://uptime.gameserver`

Suggested monitors:

| Monitor | Type | Target | Interval |
|---|---|---|---|
| Desynced | TCP | `10.0.0.50:10099` | 60s |
| Proxmox Web UI | HTTPS | `https://10.0.0.254:8006` | 60s |
| AdGuard Home | HTTP | `http://adguard-home:80` | 60s |
| Grafana | HTTP | `http://grafana:3000` | 60s |
| Prometheus | HTTP | `http://prometheus:9090` | 60s |

---

## Future Possibilities

### Alerts & Notifications

Grafana supports alerting to Discord, Telegram, Slack, email, and more:
1. Grafana → Alerting → Contact points → add webhook
2. Create alert rules: e.g. "host power > 150W for 5m", "container down for 2m"
3. No additional infrastructure needed

### True Wall Power

- **Smart plug** (Shelly Plug S, TP-Link Kasa, Tasmota-flashed): measures actual draw including PSU losses, RAM, fans. Some expose metrics via MQTT or HTTP API → scrape into Prometheus

### VictoriaMetrics (long-term storage)

If guaranteed tiered retention matters:
- Replace Prometheus with VictoriaMetrics (single binary, drop-in compatible)
- Native downsampling with per-tier retention
- Lower memory usage
- Swap is a single container change + same config files

### Per-Container Power (improved accuracy)

- Pass through RAPL to the gameserver VM via Proxmox device passthrough (`/sys/class/powercap/`)
- Run Scaphandre inside the VM with `--containers` flag for cgroup-aware power attribution
- Gives real per-container watts instead of CPU-proportional estimates
