---
name: openclaw-sentinel-troubleshooting
category: devops
description: Diagnose and fix OpenClaw sentinel service issues on ubuntu24, especially Feishu connection failures, env config drift, and startup delays.
---
## Trigger
Use when OpenClaw sentinel (`openclaw.service`) fails to start, crashes, or cannot connect to Feishu after a system restart or deployment on ubuntu24.

## Architecture Reference
- Sentinel service: `systemctl status openclaw.service`
- Service runs from: `/opt/openclaw/`
- EnvironmentFile: `/opt/openclaw-team/.env`
- Config repo: `/opt/openclaw-team/`
- Node.js: `/www/server/nodejs/v24.14.0/bin/node`

## Common Issues & Fixes

### 1. Feishu WebSocket Connection Fails (`system busy` / `400 Bad Request`)
**Symptoms:**
- `code: 1000040346, system busy` in logs
- `GET /open-apis/bot/v3/info` returns 400
- Bot identity cannot be resolved

**Root Cause (Historical):** `FEISHU_SENTINEL_APP_ID` and `FEISHU_SENTINEL_APP_SECRET` in `/opt/openclaw-team/.env` were overwritten with placeholder values (`cli_xxxx`, `***`) during a config update or git pull.

**Verification:**
```bash
ssh root@ubuntu24 "grep FEISHU_SENTINEL_APP /opt/openclaw-team/.env"
# Expected: real values like cli_a92682269af8dbdf, NOT cli_xxxx
```

**Fix:**
1. Restore real Feishu App ID/Secret in `/opt/openclaw-team/.env`
2. Restart: `ssh root@ubuntu24 "systemctl restart openclaw"`
3. Verify: `ssh root@ubuntu24 "journalctl -u openclaw -n 50 --no-pager | grep -E 'ws client ready|bot identity'"`

### 2. Port 18789 Not Listening After Start
**Symptoms:** Service shows `active (running)` but port 18789 is not bound.
**Cause:** `--force` flag in systemd service triggers full rebuild/npm install. Takes 30-60 seconds.
**Fix:** Wait 60s, then check: `ss -tlnp | grep 18789`

### 3. System Restart Wipes Running State
Sentinel was historically left running for months (PID unchanged since March). System restarts force re-read of `.env`, exposing stale/placeholder configs. Always verify `.env` after restarts.