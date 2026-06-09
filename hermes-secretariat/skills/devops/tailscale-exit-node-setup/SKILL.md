---
name: tailscale-exit-node-setup
category: devops
description: Configure a Linux server as a Tailscale Exit Node — installation, daemon config, persistent prefs, and UDP GRO optimization.
---

# Tailscale Exit Node Setup on Linux

## When to use this skill

- Setting up a Linux VPS/server as a Tailscale Exit Node
- Configuring `tailscaled` systemd service with correct environment variables
- Troubleshooting `tailscaled` service failures related to `/etc/default/tailscaled`

## Installation

```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

## IP Forwarding (required for Exit Node)

```bash
# Enable immediately
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.all.forwarding=1

# Persist
cat > /etc/sysctl.d/99-tailscale.conf << 'EOF'
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF
```

## Systemd Daemon Configuration

**Critical:** `/etc/default/tailscaled` is read by systemd. The service unit uses `$FLAGS` and `${PORT}` variables from this file.

```bash
cat > /etc/default/tailscaled << 'EOF'
PORT=41641
EOF
```

**⚠️ PITFALLS:**

1. **`$FLAGS` must NOT contain `tailscale up` flags.** The `$FLAGS` variable in the systemd unit is passed to the `tailscaled` daemon process, NOT to `tailscale up`. Flags like `--accept-dns=false`, `--advertise-exit-node`, `--accept-routes` are **client-level preferences** stored in the tailscale state file — they are NOT daemon flags. Putting them in `$FLAGS` causes `tailscaled` to exit with `status=2/INVALIDARGUMENT`.

2. **`PORT` must be set.** If `PORT` is unset, it expands to empty string, causing `tailscaled` to fail with `invalid value "" for flag -port: can't be the empty string`.

3. **`/etc/default/tailscale` vs `/etc/default/tailscaled`.** The systemd service reads `/etc/default/tailscaled` (with a `d`). The file without `d` is ignored by the service.

4. **After editing `/etc/default/tailscaled`, always run:**
   ```bash
   systemctl daemon-reload
   systemctl reset-failed tailscaled
   systemctl restart tailscaled
   ```

## Authenticating and Setting Exit Node

First start the daemon (must succeed before running `tailscale up`):

```bash
systemctl start tailscaled
```

Then configure the node preferences (these are persisted in the state file, NOT in systemd config):

```bash
tailscale up --accept-dns=false --accept-routes --advertise-exit-node
```

Equivalent form (also valid):
```bash
tailscale up --accept-dns=false --accept-routes --advertise-routes=0.0.0.0/0,::/0
```

**Note:** `tailscale up` must be run after `tailscaled` is running. If you run `tailscale up` while the daemon is stopped, it will try to start it inline but may fail.

## Verify Exit Node is Advertised

```bash
# Check via local API
curl -s --unix-socket /run/tailscale/tailscaled.sock \
  http://local-tailscaled.sock/localapi/v0/prefs | \
  python3 -c "import json,sys; d=json.load(sys.stdin); print('AdvertiseRoutes:', d.get('AdvertiseRoutes',[]))"

# Or check JSON status
tailscale status --json | python3 -c "
import json,sys
d=json.load(sys.stdin)
self=d.get('Self',{})
print('ExitNodeOption:', self.get('ExitNodeOption'))
print('PrimaryRoutes:', self.get('PrimaryRoutes'))
"
```

## Admin Console Approval

After the node advertises itself as an exit node, go to [Tailscale Admin Console](https://login.tailscale.com/admin) → find the node → enable **"Use as exit node"**.

## UDP GRO Optimization (performance)

Tailscale warns about suboptimal UDP GRO on fresh installs. Fix it:

```bash
# Enable immediately
ethtool -K eth0 rx-gro-list on
ethtool -K eth0 rx-udp-gro-forwarding on

# Persist via udev rule
cat > /etc/udev/rules.d/70-tailscale-gro.rules << 'EOF'
ACTION=="add", SUBSYSTEM=="net", NAME=="eth0", RUN+="/usr/sbin/ethtool -K eth0 rx-gro-list on rx-udp-gro-forwarding on"
EOF
```

## Architecture Summary

| Layer | Config Location | What Goes Here |
|-------|----------------|----------------|
| Daemon (systemd) | `/etc/default/tailscaled` | `PORT=41641` only (maybe `--debug` etc.) |
| Client prefs (state) | Stored via `tailscale up` | `--accept-dns`, `--advertise-exit-node`, `--accept-routes`, etc. |
| Kernel | `/etc/sysctl.d/` | `net.ipv4.ip_forward=1` |

## Troubleshooting

### `tailscaled` fails with `status=2/INVALIDARGUMENT`

Check `journalctl -u tailscaled.service` — if you see the help text printed, an invalid flag was passed via `$FLAGS`. Remove all `tailscale up` flags from `/etc/default/tailscaled`.

### `tailscaled` fails with `invalid value "" for flag -port`

`PORT` is not set in `/etc/default/tailscaled`. Add `PORT=41641`.

### `Start request repeated too quickly`

The service hit the restart limit. Run `systemctl reset-failed tailscaled` before retrying.

### `tailscale up` says "failed to connect to local tailscaled"

The daemon is not running. Start it first: `systemctl start tailscaled`.