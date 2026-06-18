---
name: wh002-hermes-maintenance
description: "Maintain and troubleshoot Hermes Agent Gateway on wh002 remote server. Covers model switching, API key sync, and gateway restart."
tags: [hermes, wh002, remote, feishu, model-switching]
---

# wh002 Hermes Maintenance

## Environment

- **Host**: `wh002` (SSH config alias)
- **User**: `root`
- **Source directory**: `/opt/WorkStation/hermes-agent/`
- **HERMES_HOME**: `/root/.hermes/`
- **Config files**: `/root/.hermes/config.yaml`, `/root/.hermes/.env`
- **Python**: python3.12 in venv at `/opt/WorkStation/hermes-agent/venv/`
- **Service**: No systemd — runs via `nohup` in background

## Gateway Management

wh002 does NOT use systemd for hermes-gateway. Use nohup:

```bash
# Stop
ssh wh002 "pkill -f 'hermes_cli.main gateway'"

# Start
ssh wh002 "cd /opt/WorkStation/hermes-agent && nohup /opt/WorkStation/hermes-agent/venv/bin/python -m hermes_cli.main gateway run --replace > /tmp/hermes-gateway.log 2>&1 &"

# Verify
ssh wh002 "ps aux | grep 'hermes_cli.main gateway' | grep -v grep"
ssh wh002 "tail -20 /tmp/hermes-gateway.log"
```

Look for: `[Lark] [INFO] connected to wss://msg-frontier.feishu.cn/ws/v2`

## Model Switching Pitfall

When switching hermes model/provider on wh002 (or any remote), check BOTH config.yaml AND .env:

### Symptom
After changing `model.default` and `model.provider` in config.yaml, hermes still errors:
```
Provider 'alibaba' is set in config.yaml but no API key was found.
Set the DASHSCOPE_API_KEY environment variable...
```

### Root Causes (check in order)

1. **config.yaml has stale `api_key` field** — if `model.api_key` is set in config.yaml, it overrides .env. Remove it:
   ```bash
   ssh wh002 "sed -i '/^  api_key: sk-/d' ~/.hermes/config.yaml"
   ```

2. **API key mismatch between machines** — DASHSCOPE_API_KEY in .env may differ from the working local key. Sync it:
   ```bash
   # Compare keys
   ssh wh002 "grep '^DASHSCOPE_API_KEY' ~/.hermes/.env | cut -d= -f2 | md5sum"
   grep '^DASHSCOPE_API_KEY' ~/.hermes/.env | cut -d= -f2 | md5sum
   
   # If different, copy local key to remote
   LOCAL_KEY=$(grep '^DASHSCOPE_API_KEY' ~/.hermes/.env | cut -d= -f2)
   ssh wh002 "sed -i \"s|^DASHSCOPE_API_KEY=.*|DASHSCOPE_API_KEY=${LOCAL_KEY}|\" ~/.hermes/.env"
   ```

3. **Restart gateway** after any config/key change:
   ```bash
   ssh wh002 "pkill -f 'hermes_cli.main gateway' && sleep 2"
   ssh wh002 "cd /opt/WorkStation/hermes-agent && nohup /opt/WorkStation/hermes-agent/venv/bin/python -m hermes_cli.main gateway run --replace > /tmp/hermes-gateway.log 2>&1 &"
   ```

### Correct config.yaml model section (alibaba provider)
```yaml
model:
  base_url: https://coding.dashscope.aliyuncs.com/v1
  context_length: 1000000
  default: qwen3.7-plus
  provider: alibaba
```

Note: NO `api_key` field — it comes from .env.

## Verification Checklist

After any maintenance, confirm:
1. `ps aux | grep 'hermes_cli.main gateway'` shows running process
2. `tail -20 /tmp/hermes-gateway.log` shows successful wss connection
3. Config matches expected model/provider: `grep -A 5 '^model:' ~/.hermes/config.yaml`
4. API key in .env matches local: compare md5sums
