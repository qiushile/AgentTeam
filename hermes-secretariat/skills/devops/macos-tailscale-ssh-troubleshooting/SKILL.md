---
name: macos-tailscale-ssh-troubleshooting
category: devops
description: Diagnose and fix SSH connectivity issues between macOS machines on Tailscale, especially DNS hijacking by 114.114.114.114 causing false IP resolution (198.18.x.x fake IPs).
---

# macOS + Tailscale SSH Troubleshooting

## Symptoms
- SSH to Tailscale hostname (e.g., `ssh user@m3max`) connects briefly then closes
- No SSH banner received despite TCP connection succeeding
- `ping hostname` works but SSH fails
- Resolved IP shows `198.18.x.x` range (OrbStack-like but actually DNS hijacking)

## Root Cause: 114 DNS Hijacking
DNS server `114.114.114.114` does NOT return NXDOMAIN for unknown domains. Instead, it returns fake IPs in the `198.18.0.0/15` range (used by Chinese ISPs for search/ad redirect pages).

This causes `ssh user@hostname` to connect to a fake IP instead of the real Tailscale IP (`100.x.x.x`).

## Diagnosis Steps

### 1. Check DNS resolution
```bash
nslookup hostname          # May return fake 198.18.x.x
nslookup hostname.ts.net   # Should return real Tailscale IP if MagicDNS works
dscacheutil -q host -a name hostname
```

### 2. Check current DNS servers
```bash
scutil --dns               # Look for nameserver entries
networksetup -getdnsservers "Wi-Fi"
```

### 3. Verify Tailscale connectivity
```bash
tailscale status           # Find the real 100.x.x.x IP
ping -c 1 100.x.x.x        # Test direct Tailscale IP
ssh user@100.x.x.x         # Test SSH via direct IP
```

### 4. Check Tailscale MagicDNS
```bash
scutil --dns | grep -B 2 -A 2 'ts.net'
# Should show domain: ts.net with nameserver 100.100.100.100
# If flags show "Not Reachable", MagicDNS is not being used
ping -c 1 100.100.100.100  # Test Tailscale DNS server reachability
```

### 5. Confirm DNS hijacking
```bash
nslookup non-existent-domain-xyz123.com 114.114.114.114
# If it returns an IP (like 198.18.x.x) instead of NXDOMAIN → hijacking confirmed
```

## Fix

### Step 1: Replace DNS servers
```bash
# For Wi-Fi
sudo networksetup -setdnsservers "Wi-Fi" 223.5.5.5 119.29.29.29

# For wired (adjust service name as needed)
sudo networksetup -setdnsservers "USB 10/100/1G/2.5G LAN" 223.5.5.5 119.29.29.29

# Flush DNS cache
sudo dscacheutil -flushcache
```

### Step 2: (Optional) Add hosts entry for critical hosts
```bash
sudo sh -c 'echo "100.86.50.21 m3max" >> /etc/hosts'
```

### Step 3: Verify
```bash
nslookup m3max  # Should now fail (NXDOMAIN) or resolve correctly
ssh m3max@m3max # Should now work
```

## Pitfalls
- **OrbStack coincidence**: The `198.18.x.x` range IS used by OrbStack internally, but in this case the fake IP comes from DNS hijacking, NOT OrbStack. Always verify by testing `nslookup` of a random non-existent domain against the DNS server.
- **ISP-level UDP 53 hijacking**: If `nslookup` of non-existent domains returns fake IPs even after switching to known-good DNS servers (223.5.5.5, 119.29.29.29, 8.8.8.8), the hijacking is at the ISP/router level via transparent UDP 53 proxy. Changing DNS servers in system settings will NOT fix this. Use the SSH config `HostName` workaround with full Tailscale MagicDNS name instead.
- **MagicDNS not active**: Tailscale configures `ts.net` domain to use `100.100.100.100`, but macOS marks it as "Not Reachable" and falls back to system DNS. This is why `hostname.ts.net` queries also fail.
- **Multiple network interfaces**: If user uses both Wi-Fi and Ethernet, DNS must be changed for BOTH interfaces.
- **SSH config Include**: OrbStack adds `Include ~/.orbstack/ssh/config` to `~/.ssh/config`. After uninstalling OrbStack, remove this line to prevent SSH warnings/errors.

## OrbStack Cleanup (if installed but not used)
```bash
brew uninstall --cask --force orbstack 2>&1 || true
rm -rf ~/.orbstack
# Edit ~/.ssh/config to remove the Include ~/.orbstack/ssh/config line
```

## Inbound Connectivity Blocked: tailscale ping works but SSH/ping fails

### Symptoms
- Remote node (Linux/Windows) → macOS: `ping` and `ssh` both timeout
- `tailscale ping` from remote to macOS: **works** (uses Tailscale UDP/TCP encapsulation, not ICMP)
- macOS → remote: works fine (asymmetric failure)
- macOS firewall disabled, pf not enabled, sshd running
- `tailscale status` shows both nodes active with direct connection

### Root Causes
1. **Clash Verge / Mihomo TUN mode** intercepting Tailscale interface traffic — most common
2. **macOS kernel-level packet filtering** on the Tailscale utun interface
3. **Multiple utun interfaces conflicting** (Clash, Tailscale, VPN all create utun devices)

### Diagnosis Steps

#### Step 1: Identify Tailscale utun interface
```bash
# Find the Tailscale utun (has 100.x.x.x IP)
for i in $(seq 0 30); do
  addr=$(ifconfig utun$i 2>/dev/null | grep "inet " | awk '{print $2}')
  [ -n "$addr" ] && echo "utun$i: $addr"
done
# Note which interface has your 100.x.x.x address (e.g., utun26)
```

#### Step 2: Capture packets to see if they reach the interface
```bash
# On macOS, in one terminal:
sudo tcpdump -i utun26 -n host 100.X.X.X  # Replace with remote node's Tailscale IP

# On remote node, in another terminal:
ping -c 2 100.Y.Y.Y  # Replace with macOS Tailscale IP
```

- **If tcpdump shows NO packets** → Tailscale network layer issue or Clash intercepting before utun
- **If tcpdump shows packets but no reply** → macOS kernel dropping incoming packets

#### Step 3: Check for Clash Verge / proxy interference
```bash
# Check if Clash processes are running
ps aux | grep -i "clash\|mihomo" | grep -v grep

# Check all utun interfaces (too many = conflict)
ifconfig | grep -E "^utun[0-9]+:" | wc -l
# Normal: 1-3 (Tailscale + maybe one VPN). 10+ means something is creating many virtual interfaces
```

#### Step 4: Check routing for conflicts
```bash
netstat -rn | grep -E "default|100\."
# The 100.64/10 (Tailscale) route should point to the correct utun
# If Clash TUN also claims this range, packets will go to wrong interface
```

### Fixes

#### Fix 1: Completely quit Clash Verge (not just disable TUN)
- Click Clash Verge 2 in menu bar → **Quit** (fully exit, don't just toggle TUN off)
- Verify no processes remain: `ps aux | grep -i "clash\|mihomo" | grep -v grep`
- Test again from remote node: `ssh user@mac-hostname`

#### Fix 2: Configure Clash TUN to exclude Tailscale CIDR
In Clash Verge TUN configuration, add Tailscale CIDR to `auto-route` exclusion or `strict-route: false`:
```yaml
tun:
  enable: true
  auto-route: true
  auto-detect-interface: true
  # Add this to prevent Clash from stealing Tailscale traffic:
  dns-hijack: []
```

#### Fix 3: If packets reach utun but macOS doesn't respond
```bash
# Try adding explicit pf rule to allow all traffic on Tailscale interface
echo "pass in quick on utun26 proto { tcp, udp, icmp } all keep state" | sudo pfctl -f - -a com.apple/tailscale

# Or try reloading the pf configuration
sudo pfctl -e  # Enable pf
sudo pfctl -F all  # Flush all rules
```

### Pitfalls
- **Clash "off" ≠ processes killed**: Toggling TUN off in Clash UI doesn't stop the mihomo process. Must fully quit the app.
- **pf "not enabled" is normal on macOS**: Even with pf disabled, macOS Application Firewall (`socketfilterfw`) can block traffic independently.
- **Application Firewall whitelist**: `sshd-keygen-wrapper` must be in the allowed apps list. Check with `/usr/libexec/ApplicationFirewall/socketfilterfw --listapps`.
- **macOS 14+ stricter network extension policies**: Newer macOS versions have tighter restrictions on multiple network extensions (Tailscale + Clash TUN + VPN) competing for routing.

## Workaround: SSH config with full Tailscale domain (bypasses DNS hijacking entirely)

If DNS hijacking cannot be fixed (e.g., ISP-level UDP 53 hijacking that affects all DNS servers), use the full Tailscale MagicDNS name in `~/.ssh/config`:

```text
Host m3max
    HostName m3max.tailcc8506.ts.net
    User m3max
```

This works because `ssh` resolves `m3max.tailcc8506.ts.net` correctly — the Tailscale client handles resolution internally for `*.ts.net` domains, bypassing the system DNS.

Find the full MagicDNS name with:
```bash
tailscale status
# OR
tailscale dns-status  # if supported
```