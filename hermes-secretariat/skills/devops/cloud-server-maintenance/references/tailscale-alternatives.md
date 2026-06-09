# Tailscale Exit Node Alternatives on Legacy Systems

When a cloud VPS cannot run Tailscale (CentOS 6, no systemd, kernel < 3.10), use SSH dynamic forwarding as a drop-in replacement for Exit Node functionality.

## SSH SOCKS5 Proxy (one-shot)

```bash
ssh -D 1080 -C -N root@<IP>
```

- `-D 1080`: Opens SOCKS5 proxy on local port 1080
- `-C`: Compresses data (saves bandwidth on slow links)
- `-N`: No remote command (pure tunnel)
- Configure browser/system proxy to SOCKS5 `127.0.0.1:1080`

## autossh (persistent, auto-reconnect)

```bash
brew install autossh
autossh -M 0 -f -N -D 1080 -C root@<IP>
```

- `-M 0`: Disables autossh monitoring port (avoids conflicts)
- `-f`: Forks to background
- Auto-reconnects if SSH drops (network change, server reboot)

Add to Mac login items for persistence:
```bash
# In ~/Library/LaunchAgents/local.autossh.plist or just add to ~/.zshrc:
autossh -M 0 -f -N -D 1080 -C root@<IP>
```

## Comparison: Tailscale Exit Node vs SSH SOCKS5

| Feature | Tailscale Exit Node | SSH -D |
|---------|-------------------|--------|
| Setup complexity | Install + configure + approve | One command |
| CentOS 6 support | ❌ No | ✅ Yes |
| All traffic routed | ✅ Yes (IP layer) | ⚠️ Only SOCKS5-aware apps |
| Memory usage | ~50MB daemon | ~1MB ssh process |
| Auto-reconnect | ✅ Built-in | ✅ With autossh |
| Bandwidth limit | VPS bandwidth | Same |

## System-wide proxy (macOS)

To route ALL traffic (not just browser) through SSH SOCKS5:

```bash
# Set system proxy
networksetup -setsocksfirewallproxy "Wi-Fi" 127.0.0.1 1080
networksetup -setsocksfirewallproxystate "Wi-Fi" on

# To disable later:
networksetup -setsocksfirewallproxystate "Wi-Fi" off
```
