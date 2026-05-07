---
name: ubuntu24-hermes-maintenance
description: Maintain and troubleshoot Hermes Agent Gateway on ubuntu24 remote server (root@ubuntu24.tailcc8506.ts.net). Covers directory migration recovery, venv rebuild, service restart, and common failure modes.
tags: [hermes, ubuntu, systemd, venv, feishu, deployment]
---

# Ubuntu24 Hermes Maintenance

## Environment

- **Host**: `root@ubuntu24.tailcc8506.ts.net` (Tailscale)
- **Source directory**: `/opt/WorkStation/agent/hermes-agent/` (migrated from `/root/WorkStation/`)
- **HERMES_HOME**: `/root/.hermes/` (HOME=/root, unchanged by migration)
- **Config files**: `/root/.hermes/config.yaml`, `/root/.hermes/.env` (in HOME, NOT in source dir)
- **Service**: `hermes-gateway.service`
- **Systemd unit**: `/etc/systemd/system/hermes-gateway.service`
- **Node.js**: `/www/server/nodejs/v24.14.0/bin/node`
- **Python**: python3.12 in venv

## Directory Migration Recovery (/root/WorkStation → /opt/WorkStation)

When the WorkStation directory is moved, three things break simultaneously:

### Step 1: Update systemd service file paths

```bash
ssh root@ubuntu24.tailcc8506.ts.net \
  "sed -i 's|/root/WorkStation|/opt/WorkStation|g' /etc/systemd/system/hermes-gateway.service"
```

Paths affected: `ExecStart`, `WorkingDirectory`, `PATH`, `VIRTUAL_ENV` env vars.

### Step 2: Rebuild venv from scratch (NOT --upgrade)

**Critical pitfall**: `python -m venv venv --upgrade` does NOT fix existing script shebangs. The old shebangs in `venv/bin/pip`, `venv/bin/python3.12`, etc. still point to the old path. You MUST delete and recreate:

```bash
ssh root@ubuntu24.tailcc8506.ts.net \
  "cd /opt/WorkStation/agent/hermes-agent && rm -rf venv && python3.12 -m venv venv"
```

### Step 3: Install with [feishu] extra

**Critical pitfall**: `pip install -e .` does NOT install `lark-oapi`. The feishu channel requires it as an extra dependency. Must use:

```bash
ssh root@ubuntu24.tailcc8506.ts.net \
  "cd /opt/WorkStation/agent/hermes-agent && /opt/WorkStation/agent/hermes-agent/venv/bin/pip install -e '.[feishu]'"
```

Symptom of missing lark-oapi: `WARNING gateway.run: Feishu: lark-oapi not installed or FEISHU_APP_ID/SECRET not set`

### Step 4: Reload and restart

```bash
ssh root@ubuntu24.tailcc8506.ts.net \
  "systemctl daemon-reload && systemctl restart hermes-gateway.service"
```

### Step 5: Verify

```bash
ssh root@ubuntu24.tailcc8506.ts.net \
  "systemctl status hermes-gateway.service --no-pager && \
   journalctl -u hermes-gateway.service --no-pager -n 10"
```

Look for: `[Lark] [INFO] connected to wss://msg-frontier.feishu.cn/ws/v2`

## Common Failure Modes

| Symptom | Cause | Fix |
|---------|-------|-----|
| `OSError: Could not find a suitable TLS CA certificate bundle` | Old venv with hardcoded `/root/WorkStation/` paths | Rebuild venv from scratch |
| `lark-oapi not installed` | Installed with `-e .` instead of `-e '.[feishu]'` | Reinstall with feishu extra |
| Service exits immediately with `exit-code` | Path mismatch in systemd unit or missing deps | Check journalctl, verify paths match actual directory |
| `venv/bin/pip: bad interpreter` | venv shebangs point to moved/deleted path | `rm -rf venv && python3.12 -m venv venv` |

## Verification Checklist

After any maintenance, confirm:
1. `systemctl status hermes-gateway.service` shows `active (running)`
2. `journalctl -u hermes-gateway.service` shows successful wss connection
3. `ps aux | grep hermes` shows PID with `/opt/WorkStation/` path (not `/root/WorkStation/`)
4. No TLS/certifi path errors in logs
