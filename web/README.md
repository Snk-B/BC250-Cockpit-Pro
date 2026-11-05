# BC-250 Cockpit Pro Web Monitor

The web frontend for the `apu_telemetry` daemon: a lightweight Python HTTP server (`server.py`) that serves live telemetry JSON alongside the unified Titanium Studio Cockpit Pro.

## Endpoints

- `/` — Titanium Studio Cockpit Pro (integrated BASIC & ADVANCED modes, live Oberon board diagram, mobile PWA support).
- `/api/telemetry` — Live telemetry snapshot from `/run/apu_telemetry.json` (CORS enabled).
- `/api/topology` — CPU core and GPU Compute Unit topology.
- `/api/overclock` — Live frequency range and governor state.

## Install

Handled automatically by the top-level `./install.sh` (see the main [README](../README.md)) — it configures `bc250-web.service` with your user and working directory, then enables and starts the service.

## Configuration

Set in `/etc/systemd/system/bc250-web.service`:

- `BC250_WEB_PORT` — port to listen on (default `8090`).

## Checking it's running

```bash
sudo systemctl status bc250-web.service
```

Then open `http://localhost:8090` (or `http://<board-ip>:8090` from another machine on your local network).

## Logs

```bash
journalctl -u bc250-web.service -f
```
