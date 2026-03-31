# CLAUDE.md — Context for Claude Code

This file gives Claude Code the context needed to assist with this Proxmox homelab.
Always read `PROXMOX.md` before making any suggestions or changes.

---

## What This Repo Is

Documentation and configuration files for a personal Proxmox homelab running at home.
The primary goal is self-hosting game servers and media services for personal use and friends.

---

## How to Help

- Always read `PROXMOX.md` first to understand the current state of the server
- Update `PROXMOX.md` after any significant change (new VM, new container, IP change, issue resolved, etc.)
- When suggesting commands, assume the user is SSH'd into the relevant machine
- Prefer simple, minimal solutions — this is a home server, not enterprise infrastructure
- When writing compose files, follow the structure in `PROXMOX.md` section 5
- When modifying config files that exist both locally and on a server (e.g. Caddyfile, compose.yml): always edit the local file first, then `scp` it to the server

---

## User Preferences

- Shell: bash, editor: vim
- OS on gameserver VM: Debian 13 (Trixie)
- Compose files are named `compose.yml` and live in `/opt/apps/<appname>/compose.yml`
- No desktop environments on any VM — headless only
- Prefers direct SSH over Proxmox console
- Communication style: direct, concise, no fluff

---

## Rules for Updating PROXMOX.md

When the user completes a significant action, update `PROXMOX.md` accordingly:

- New VM created → add to section 2 (VMs table)
- New LXC container → add to section 3 (containers table)
- New app deployed → add to deployed apps table (section 5) and update directory structure
- New game server with public port → add to port forwards table (section 7)
- Static IP assigned → add to section 7 (IP table)
- New internal `*.gameserver` hostname → add DNS rewrite to section 7 DNS table
- Issue discovered → add to section 10 (known issues)
- Issue resolved → remove or update section 10 entry
- Software installed on Proxmox host → update section 1 (host software)
- Software installed on gameserver → update section 4 (installed software)

---

## Command Formatting

- Shell commands must not exceed 80 characters per line
- If a command is longer, split it across multiple lines
  - Bash: use `\` line continuations
  - PowerShell: use `` ` `` line continuations

---

## Do Not

- Do not suggest GUI tools — everything is CLI
- Do not suggest LXC containers for game servers — use Docker on the gameserver VM
- Do not change VM IDs or hostnames without noting it in PROXMOX.md
- Do not suggest cloud-based solutions — everything runs on-prem
- Do not use Let's Encrypt (ACME) for `*.gameserver` hostnames — use `tls internal`
