---
name: macos-clash-verge-troubleshooting
description: Diagnose and fix Clash Verge (mihomo) connectivity issues on macOS — proxy not working, sites unreachable, DNS problems, CA certificate errors.
---

## Trigger Conditions
- User reports a website is unreachable on macOS
- "代理配置" / "翻墙" / Clash / proxy-related connectivity issues
- curl HTTPS requests fail with certificate errors

## Diagnostic Steps

### 1. Quick Test
```bash
# Test direct (bypass proxy)
curl -v --noproxy '*' https://example.com --connect-timeout 10 2>&1 | head -20

# Test via proxy
curl -v -x http://127.0.0.1:7890 https://example.com --connect-timeout 10 2>&1 | head -20

# Test with correct UA (some sites block curl UA)
curl -sI --noproxy '*' -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" https://example.com --connect-timeout 10 2>&1 | head -10
```

### 2. Find Clash Verge Directory
**IMPORTANT**: The actual directory is NOT `~/Library/Application Support/clash-verge/`. It is:
```bash
CLASH_DIR="$HOME/Library/Application Support/io.github.clash-verge-rev.clash-verge-rev"
```

### 3. Check CA Certificate Issue
```bash
ls -la /usr/share/curl/curl-ca-bundle.crt 2>&1
```
If missing, curl HTTPS fails with `error setting certificate verify locations: CAfile: /usr/share/curl/curl-ca-bundle.crt CApath: none`.

Fix (requires sudo):
```bash
sudo mkdir -p /usr/share/curl
sudo ln -sf /etc/ssl/cert.pem /usr/share/curl/curl-ca-bundle.crt
```

Workaround (no sudo):
```bash
export CURL_CA_BUNDLE=/etc/ssl/cert.pem
```

### 4. Check Clash Core Status
```bash
ps aux | grep -i clash | grep -v grep
lsof -i :7890 -P -n 2>/dev/null | head -5
```

### 5. Check Clash Config
```bash
cat "$CLASH_DIR/config.yaml" 2>/dev/null
cat "$CLASH_DIR/verge.yaml" 2>/dev/null
```

Key fields in `verge.yaml`:
- `enable_tun_mode` - TUN mode on/off
- `enable_system_proxy` - system proxy on/off
- `clash_core` - usually `verge-mihomo`

### 6. Check System Proxy Status
```bash
networksetup -getwebproxy Wi-Fi
networksetup -getsecurewebproxy Wi-Fi
networksetup -getsocksfirewallproxy Wi-Fi
```
If all show `Enabled: No`, system proxy is not active even if Clash config says `enable_system_proxy: true`.

### 7. Query Clash API via Unix Socket
```bash
# Proxies status
curl -s --unix-socket /tmp/verge/verge-mihomo.sock "http://localhost/proxies"

# Connections
curl -s --unix-socket /tmp/verge/verge-mihomo.sock "http://localhost/connections"

# DNS query
curl -s --unix-socket /tmp/verge/verge-mihomo.sock "http://localhost/dns/query?name=example.com"

# Rules (check if domain hits DIRECT)
curl -s --unix-socket /tmp/verge/verge-mihomo.sock "http://localhost/rules"
```

### 8. Check Site-Specific Rules
```bash
# Check if domain has DIRECT rule
curl -s --unix-socket /tmp/verge/verge-mihomo.sock "http://localhost/rules" | grep -i "aliyun\|baidu\|example"
```

### 9. Check Clash Logs
```bash
tail -50 "$CLASH_DIR/logs/latest.log"
```

### 10. Check TUN Interface and Routing
```bash
ifconfig | grep utun
netstat -rn | grep -E "default|198.18"
scutil --dns
```

## Common Issues and Fixes

| Issue | Symptom | Fix |
|-------|---------|-----|
| CA cert missing | curl error 77 for ALL https sites | `sudo ln -sf /etc/ssl/cert.pem /usr/share/curl/curl-ca-bundle.crt` |
| System proxy disabled | `Enabled: No` in networksetup | Toggle system proxy in Clash Verge UI |
| TUN mode routing issue | Some sites unreachable via browser | Toggle TUN mode off/on in UI |
| Subscription update failing | Log shows "TLS verifier failed" | Fix CA cert first, then update subscription |
| UA blacklist (403) | `denied by UA ACL = blacklist` | Use browser User-Agent string |
| Wrong Clash directory | Can't find config files | Use `io.github.clash-verge-rev.clash-verge-rev` path |

## Pitfalls
- **Never assume `~/Library/Application Support/clash-verge/`** — the rev version uses `io.github.clash-verge-rev.clash-verge-rev`
- System proxy showing `Enabled: No` even when Clash config has `enable_system_proxy: true` — toggle in UI to fix
- TUN mode intercepts traffic independently of system proxy settings
- Some Chinese CDN sites (aliyun, alibaba) block curl's default UA — need browser UA string
- Clash API on port 9097 may be disabled; always use unix socket `/tmp/verge/verge-mihomo.sock`
- `no_proxy` env vars may be empty in terminal sessions even if set in shell config files