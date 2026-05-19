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

### macOS Monitoring Setup
On macOS, the monitoring system lives in `~/.hermes/clash-monitor/`:
- **Monitoring Script**: `~/.hermes/clash-monitor/clash_monitor.py` (runs as cron job or manually)
- **Daily Report Script**: `~/.hermes/clash-monitor/clash_daily_report.py`
- **Active Log**: `~/.hermes/clash-monitor/monitor.log` (plain text, `[YYYY-MM-DD HH:MM:SS] ...` format)
- **Legacy Log**: `~/.hermes/clash-monitor/connectivity.log` (JSON lines format, may be stale)
- **Reports**: `~/.hermes/clash-monitor/daily_reports/YYYY-MM-DD.json`

The daily report script parses `monitor.log` as primary source (with `connectivity.log` as fallback). Usage: `python3 ~/.hermes/clash-monitor/clash_daily_report.py [YYYY-MM-DD]` (defaults to yesterday).

**Key log patterns in monitor.log:**
- `✅ <node>: <latency>ms 正常` — successful node test
- `<node>: timeout ✗` — failed node test
- `Current node OK: <latency>ms ✓` — standalone current-node check
- `Current node timed out or failed. Testing 圣何塞 nodes...` — triggered failover
- `切换: <node> (<latency>ms)` — successful proxy switch
- `检查节点: <node>` — named check start
- `❌ <node>: 超时，尝试圣何塞节点` — check failure triggering switch attempt

### ubuntu24 Server Setup
On the ubuntu24 server, the monitoring system consists of two scripts:
- **Monitoring Script**: `/root/scripts/clash-sj-monitor.py` (runs as daemon, logs to `/tmp/clash-sj-monitor.log`)
- **Daily Report Script**: `/root/.hermes/scripts/clash-daily-report.py` (runs via cron, parses `/tmp/clash-sj-monitor.log`)

### Monitoring Script (`clash-sj-monitor.py`)
- Checks current 🚀节点选择 proxy node latency
- If current node times out → tests all San Jose (圣何塞) nodes, switches to fastest
- Logs plain text to `/tmp/clash-sj-monitor.log` (format: `[YYYY-MM-DD HH:MM:SS] 节点检查/切换: ...`)
- Uses Unix socket `/tmp/verge/verge-mihomo.sock` (Note: On ubuntu24, mihomo uses HTTP API on `127.0.0.1:9090` — ensure socket exists or update script)
- Start/Stop: `/root/scripts/clash-sj-start.sh`, `/root/scripts/clash-sj-stop.sh`

### Daily Report Script (`clash-daily-report.py`)
- Parses plain text logs from `/tmp/clash-sj-monitor.log` (NOT JSON)
- Generates Markdown report with stats, delay rankings, switch history, and timeout periods
- Usage: `python3 /root/.hermes/scripts/clash-daily-report.py [YYYY-MM-DD]` (defaults to yesterday if no date given)
- Output is plain text/Markdown suitable for Feishu/Chat messages

### Node Testing via Clash API
Test individual nodes using the delay endpoint:

```bash
curl -s --noproxy '*' --unix-socket /tmp/verge/verge-mihomo.sock \
  "http://localhost/proxies/{NODE_NAME}/delay?timeout=5000&url=https://www.google.com/generate_204"
```

Returns `{"delay": 233}` on success, or `{"message": "timeout"}` on failure.

### Python Socket Approach (Alternative to curl)
For Python scripts, use Unix socket directly to avoid `--noproxy` issues. Key requirement: handle chunked transfer encoding in responses. See the Pitfalls section below for details.

## Pitfalls
1. **Requests intercepted by proxy**: Always use `--noproxy '*'` with curl, otherwise the request goes through the proxy and returns 404 or HTML.
2. **Unix socket vs HTTP port**: Clash Verge 2 on macOS uses Unix socket (`/tmp/verge/verge-mihomo.sock`). Standalone mihomo on ubuntu24 uses HTTP API (`127.0.0.1:9090`). The monitoring script expects the Unix socket — if deploying on ubuntu24, either create the socket or update the script to use HTTP API.
3. **Log format is plain text, NOT JSON**: `/tmp/clash-sj-monitor.log` uses format `[YYYY-MM-DD HH:MM:SS] 节点检查/切换: ...`. The daily report script parses this plain text with regex, NOT `json.loads()`.
4. **Unicode in URLs**: Group names with emojis must be URL-encoded in the PUT request path.
5. **Latency data**: The `history` field contains the last speed test result. If empty, the node hasn't been tested recently — trigger a test from the UI first.
6. **Node type values are capitalized**: Clash API returns types like `"Vless"`, `"Hysteria2"` (capitalized first letter), NOT lowercase `"vless"` or `"hysteria2"`. When filtering nodes by type, use `.lower()` for case-insensitive matching.
7. **PUT requests return HTTP 204 (empty body)**: When switching proxies via `PUT /proxies/{group}`, the API returns 204 No Content with an empty response body. **Do NOT check for non-empty JSON to determine success.**
   - **curl**: Check `exit code == 0` — empty stdout with exit code 0 means success.
   - **Python raw socket**: The 204 status line appears in the HTTP header before `\r\n\r\n`. Check if `"204"` is in the first line of the response header and return `{}` (truthy empty dict) instead of `None`. Also handle empty `body_data` after the header separator — return `{}` instead of trying to parse empty bytes as JSON. Bug pattern: if your `clash_request()` function tries `json.loads(body_data)` on an empty byte string, it raises `JSONDecodeError` and returns `None`, making the caller think the PUT failed when it actually succeeded.
8. **Chunked transfer encoding**: Clash API responses use chunked transfer encoding. When using Python's raw `socket` module (not `urllib` or `requests`), you must decode chunked responses manually: read size hex line, then that many bytes of data, repeat until size is 0. Using `curl` or `urllib` handles this automatically.
9. **Python socket Connection: close header**: When making requests via raw Unix socket in Python, always include `Connection: close` in the HTTP request headers, otherwise the socket may hang waiting for the server to close the connection.
10. **Tailscale MagicDNS intercepted by Clash proxy**: `*.ts.net` domains are intercepted by Clash Verge's system proxy (port 7890) even when `prepend-rules` contains `DOMAIN-SUFFIX,.ts.net,DIRECT`. The `prepend-rules` may not be injected into runtime rules. Symptoms: `curl http://xxx.tailcc8506.ts.net/` returns 502, while `curl --noproxy '*'` works.
    - **Root causes**: (a) `~/.curlrc` has `proxy = http://127.0.0.1:7890` forcing all traffic through Clash. (b) macOS system proxy (Wi-Fi) also points to 7890. (c) `prepend-rules` not loaded at runtime — verify with `/rules` API endpoint. (d) **Even with Clash set to 直连 mode, macOS system SOCKS proxy still sends requests to 127.0.0.1:7890, and Clash's DNS resolver returns fake `198.18.x.x` (CGNAT) IPs instead of real Tailscale `100.x.x.x` IPs.**
    - **Fix curl**: Add `noproxy = localhost,127.0.0.1,.ts.net,100.64.0.0/10` to `~/.curlrc`.
    - **Fix browser (macOS System Settings)**: System Settings → Network → Wi-Fi → Details → Proxy → "Bypass proxy settings for these Hosts & Domains" → add `*.ts.net, 100.64.0.0/10`. **This is the definitive fix** — Clash Verge UI bypass settings alone are insufficient because macOS system proxy still intercepts the traffic.
    - **Fix browser (Clash Verge UI)**: In Clash Verge → Settings → System Proxy → Bypass domains, also add `*.ts.net, 100.64.0.0/10` as secondary defense.
    - **Diagnose**: `curl -sv http://xxx.ts.net/ 2>&1 | head` — if you see `Connected to 127.0.0.1 (127.0.0.1) port 7890`, traffic is being proxied. `dig xxx.ts.net` — if IP is `198.18.x.x` instead of `100.x.x.x`, DNS is being hijacked by Clash.
    - **Verify runtime rules**: `curl -s --noproxy '*' --unix-socket /tmp/verge/verge-mihomo.sock 'http://localhost/rules'` — search for `.ts.net` in the payload. If absent, `prepend-rules` failed to load.

## Find Clash Verge Process
```bash
ps aux | grep -i clash | grep -v grep
# Socket path is shown in the verge-mihomo -ext-ctl-unix argument
```
