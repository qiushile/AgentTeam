---
name: clash-verge-proxy-management
category: devops
description: Manage Clash Verge 2 (mihomo) proxies via CLI — query proxy groups, check node latency, and switch nodes programmatically.
trigger: User wants to check or change Clash Verge proxy nodes, find fastest nodes by latency, or automate proxy switching.
---

## Overview
Clash Verge 2 (mihomo core) exposes an external API via Unix socket on macOS. Use this to query proxy state, check latency, and switch nodes programmatically.

## Key Facts
- **API socket**: `/tmp/verge/verge-mihomo.sock`
- **Must use**: `curl --unix-socket /tmp/verge/verge-mihomo.sock` for all requests
- **Must use**: `--noproxy '*'` flag on curl to prevent requests from routing through the proxy itself
- **Config file**: `~/Library/Application Support/io.github.clash-verge-rev.clash-verge-rev/clash-verge.yaml`

## Query All Proxy Groups and Current Selections

```bash
curl -s --unix-socket /tmp/verge/verge-mihomo.sock http://localhost/proxies | python3 -c "
import json,sys
d=json.load(sys.stdin)
proxies = d.get('proxies', {})
for name, info in proxies.items():
    ptype = info.get('type', '')
    now = info.get('now', '')
    all_count = len(info.get('all', []))
    if ptype in ['Selector', 'URLTest', 'Fallback', 'LoadBalance']:
        print(f'{name} (类型: {ptype}, 当前: {now or \"无\"}, 子节点: {all_count}个)')
"
```

## Find Nodes by Name Pattern (e.g., 圣何塞/San Jose)

```bash
curl -s --unix-socket /tmp/verge/verge-mihomo.sock http://localhost/proxies | python3 -c "
import json,sys
d=json.load(sys.stdin)
proxies = d.get('proxies', {})
# Find all proxies matching a keyword
for name, info in proxies.items():
    if '圣何塞' in name:
        history = info.get('history', [])
        delay = history[-1].get('delay', 'N/A') if history else 'N/A'
        ptype = info.get('type', '')
        print(f'{name} (类型: {ptype}, 延迟: {delay}ms)')
"
```

## Check Latency of Nodes in a Group

```bash
curl -s --unix-socket /tmp/verge/verge-mihomo.sock http://localhost/proxies | python3 -c "
import json,sys
d=json.load(sys.stdin)
us = d.get('proxies',{}).get('美国节点',{})
for n in us.get('all', []):
    info = d.get('proxies',{}).get(n, {})
    history = info.get('history', [])
    delay = history[-1].get('delay', 'N/A') if history else 'N/A'
    print(f'{n}: {delay}ms')
"
```

## Switch a Proxy Group to a Specific Node

```bash
# URL-encode the group name (e.g., 🤖AI网站 → %F0%9F%A4%96AI%E7%BD%91%E7%AB%99)
curl -s --unix-socket /tmp/verge/verge-mihomo.sock \
  -X PUT http://localhost/proxies/{URL_ENCODED_GROUP_NAME} \
  -d '{"name":"TARGET_NODE_NAME"}' \
  -H "Content-Type: application/json"
```

### URL Encoding Common Group Names
- `🤖AI网站` → `%F0%9F%A4%96AI%E7%BD%91%E7%AB%99`
- `🚀节点选择` → `%F0%9F%9A%80%E8%8A%82%E7%82%B9%E9%80%89%E6%8B%A9`
- `🇯🇵日本节点` → `%F0%9F%87%AF%F0%9F%87%B5%E6%97%A5%E6%9C%AC%E8%8A%82%E7%82%B9`
- `🇺🇸美国节点` → `%F0%9F%87%BA%F0%9F%87%B8%E7%BE%8E%E5%9B%BD%E8%8A%82%E7%82%B9`
- `GLOBAL` → `GLOBAL` (no encoding needed)

## Automated Node Monitoring System

A complete monitoring system is deployed at `~/.hermes/scripts/` with two cron jobs. It continuously checks AI website proxy connectivity and auto-switches to the fastest available San Jose node.

### Components

**Monitoring Script** (`~/.hermes/scripts/clash_monitor.py`):
- Normal mode: checks every 17 minutes
- If current node times out → tests all San Jose nodes, switches to fastest
- If ALL San Jose nodes timeout → enters emergency mode (checks every 3 minutes)
- When any node recovers → exits emergency mode, resumes 17-minute checks

**Daily Report Script** (`~/.hermes/scripts/clash_daily_report.py`):
- Runs at 00:00 daily
- Generates connectivity stats from previous day's logs
- Saves JSON report to `~/.hermes/clash-monitor/daily_reports/YYYY-MM-DD.json`

### Notification Strategy
Only sends notifications on mode changes (normal → emergency or emergency → normal). All checks and auto-switches are silent but logged to `~/.hermes/clash-monitor/connectivity.log`.

### Node Testing via Clash API
The script uses the Clash delay endpoint to test individual nodes:

```bash
curl -s --unix-socket /tmp/verge/verge-mihomo.sock \
  "http://localhost/proxies/{NODE_NAME}/delay?timeout=5000&url=https://www.google.com/generate_204"
```

Returns `{"delay": 233}` on success, or `{"message": "timeout"}` on failure.

### State Management
- State file: `~/.hermes/clash-monitor/state.json`
- Tracks: mode (normal/emergency), last check time, check/switch counts, current proxy

### Cron Jobs
- `clash节点监控`: runs `clash_monitor.py` every 3 minutes (script controls actual frequency)
- `clash节点日报`: runs `clash_daily_report.py` at 00:00 daily

## Pitfalls
1. **Requests intercepted by proxy**: Always use `--noproxy '*'` with curl, otherwise the request goes through the proxy and returns 404 or HTML.
2. **Unix socket vs HTTP port**: Clash Verge 2 uses Unix socket (`/tmp/verge/verge-mihomo.sock`), NOT the `external-controller` port defined in `config.yaml` (9090).
3. **Unicode in URLs**: Group names with emojis must be URL-encoded in the PUT request path.
4. **Latency data**: The `history` field contains the last speed test result. If empty, the node hasn't been tested recently — trigger a test from the UI first.

## Find Clash Verge Process
```bash
ps aux | grep -i clash | grep -v grep
# Socket path is shown in the verge-mihomo -ext-ctl-unix argument
```
