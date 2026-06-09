---
name: cloud-server-maintenance
category: devops
description: Assess, clean up, back up, and decide whether to keep or decommission a cloud VPS. Covers runaway process detection, disk cleanup, service evaluation, backup triage, and OS reinstallation workflow.
---

# Cloud Server Maintenance

Use this skill when a user asks you to check on a cloud VPS, clean up disk space, decide whether to keep or decommission it, or prepare it for OS reinstallation.

## Phase 1: Rapid Assessment

Connect and gather the essentials in one shot:

```bash
ssh root@<IP> "
  echo '=== OS ==='; cat /etc/os-release 2>/dev/null || cat /etc/redhat-release 2>/dev/null
  echo '=== RESOURCES ==='; free -h 2>/dev/null; df -h
  echo '=== UPTIME ==='; uptime
  echo '=== LISTENING PORTS ==='; netstat -tlnp 2>/dev/null || ss -tlnp
  echo '=== TOP PROCESSES ==='; ps aux --sort=-%mem | head -15
  echo '=== CRON ==='; crontab -l 2>/dev/null
  echo '=== INIT.D ==='; ls /etc/init.d/ 2>/dev/null | grep -v -E '^(functions|halt|killall|netfs|network|single|rc|netconsole|restorecond)$'
"
```

## Phase 2: Identify Disk Hogs

**Runaway daemon logs are the #1 cause of 100% disk on old VPS.** Look for:

```bash
ssh root@<IP> "
  find /var/log -type f -size +50M -exec ls -lhS {} \; 2>/dev/null
  find /home -type f -size +100M -exec ls -lhS {} \; 2>/dev/null
  find /opt -type f -size +100M -name '*.tar.gz' -o -name '*.zip' 2>/dev/null
"
```

**Common culprits:**
- Daemon watchdog loops writing errors every few seconds (e.g., appdog, supervisor, custom scripts)
- Rotated logs that never get cleaned (`access.log`, `secure`, `btmp`, `messages`)
- Old package tarballs left in `/opt/` or `/root/` after manual installs

### Fix: Stop the daemon first, THEN truncate

```bash
# 1. STOP the daemon (critical — truncate won't help if it keeps writing)
service <daemon> stop 2>/dev/null
kill -9 <PID> 2>/dev/null

# 2. Truncate logs (don't rm — truncating avoids "file not found" errors)
> /var/log/appdog.log
> /home/wwwlogs/access.log

# 3. Clean old rotated logs
rm -f /var/log/*-2017* /var/log/*.gz 2>/dev/null

# 4. Remove old package archives
rm -f /opt/gcc/*.tar.gz /opt/emq/*.zip 2>/dev/null
```

**Verify:** `df -h` should show significant space freed.

## Phase 3: Service Evaluation Matrix

For each running service, evaluate:

| Service | Memory | Keep? | Reason |
|---------|--------|-------|--------|
| sshd | ~5MB | ✅ Yes | Essential for access |
| nginx (stopped) | ~5MB | ⚠️ Depends | Only if serving sites |
| php-fpm (stopped) | ~20MB | ❌ Usually | Needs nginx too |
| MySQL (stopped) | ~100MB | ❌ On 512MB | Too heavy |
| Custom daemon (looping) | Variable | ❌ No | Check if target still exists |
| cupsd | ~5MB | ❌ Usually | Print server, not needed |

### Low-memory VPS (≤512MB RAM) reality check

| What it CAN do | Memory |
|----------------|--------|
| SSH only (jump host) | ~5MB |
| SSH + dnsmasq (DNS forwarder) | ~7MB |
| SSH + cron scripts | ~15MB |
| SSH + nginx static files | ~10MB |
| **What it CANNOT do** | |
| Jenkins | Needs 512MB+ Java heap alone |
| Docker | Kernel 2.6.32 doesn't support overlayfs |
| Node.js apps | V8 needs 100MB+ minimum |
| MySQL/PostgreSQL | 100MB+ baseline |
| Tailscale Exit Node | Needs systemd + newer kernel |

## Phase 4: Backup Triage

Before OS reinstallation, systematically assess what's worth keeping:

### Worth keeping (back up to local)
- **Websites** in `/usr/share/` or `/var/www/` — especially if domain still resolves here
- **Database dumps** or raw data directories — even `.frm` files + `ibdata1` can be recovered
- **SSL/TLS certificates and keys** — self-signed CA, Let's Encrypt archives
- **Custom configs** in `/etc/nginx/`, `/etc/init.d/` scripts
- **SSH authorized_keys** — record which keys were deployed

### Can discard
- Package tarballs (`.tar.gz`, `.zip`) in `/opt/` or `/root/` — always re-downloadable
- Source code directories of open-source projects (nginx, ngrok, node.js) — available on GitHub
- Old logs (`/var/log/*`, `/home/wwwlogs/*`) — historical only
- `.pyenv` virtualenvs — easily recreated
- Build artifacts (`nohup.out`, `.zcompdump`, etc.)

### Backup workflow
```bash
# On remote: tar up directories first (faster than scp -r for many small files)
ssh root@<IP> "cd /usr/share && tar czf /tmp/site_backup.tar.gz yudijiaoyu.com/"
ssh root@<IP> "cd /root && tar czf /tmp/db_backup.tar.gz databases_backup_*/"

# Pull compressed archives to local
mkdir -p ~/backup-<hostname>/{website,database,certs,configs}
scp root@<IP>:/tmp/site_backup.tar.gz ~/backup-<hostname>/website/
scp root@<IP>:/tmp/db_backup.tar.gz ~/backup-<hostname>/database/

# Clean up remote temp files
ssh root@<IP> "rm -f /tmp/*_backup.tar.gz"
```

## Phase 5: DNS Resolution Check

If user reports "domains can't be opened":

```bash
# Check if DNS resolves to this IP
nslookup <domain> 2>&1 | grep "Address:"

# Check if nginx is listening
ss -tlnp | grep ':80'

# Check if nginx has vhost config for this domain
grep -r '<domain>' /etc/nginx/ 2>/dev/null

# Check HTTP response
curl -s -o /dev/null -w '%{http_code}' http://<domain>
```

**Common pattern:** DNS points to the IP, but:
1. Nginx is stopped → Connection refused
2. Nginx is running but no vhost config → 404 or default page
3. Nginx is running but upstream service is down → 502 Bad Gateway

**Fix:** Start nginx + add vhost config, OR update DNS to point to a different server.

## Phase 6: OS Reinstallation Decision

### Signs it's time to reinstall
- EOL OS (CentOS 6 EOL Nov 2020, CentOS 7 EOL June 2024)
- Disk corrupted or filesystem errors
- Can't install modern software (Docker, Node 18+, Python 3.10+)
- Too many accumulated configuration cruft

### Before reinstalling
1. Complete Phase 4 (backup triage)
2. Record current DNS entries (screenshot or export)
3. Note the cloud provider's default login user (Ubuntu → `ecs-user` or `ubuntu`, not `root`)
4. Plan post-install steps: Tailscale, SSH key setup, firewall

### CentOS 6 specific: Tailscale cannot be installed
- No systemd (uses init.d)
- Kernel 2.6.32 too old for WireGuard userspace networking
- **Alternative:** Use `ssh -D 1080` or `autossh -M 0 -f -N -D 1080 <user>@<IP>` for SOCKS5 proxy
  - Same effect as Exit Node for web browsing
  - Works on any system with sshd
  - Add to Mac login items for persistence
  - See `references/tailscale-alternatives.md` for detailed comparison and setup

## Pitfalls

- **appdog/daemon loops:** Always `service stop` + `kill -9` BEFORE truncating logs. Truncating alone just creates a race where the daemon writes more data.
- **scp -r on directories with many small files:** Much slower than `tar czf` on remote then `scp` the archive. Always compress first.
- **CentOS 6 yum failures:** Repos are offline since EOL. `yum install` will fail. Use `curl` to download RPMs directly or use `rpm -Uvh` with archived packages.
- **Ubuntu reinstall changes default user:** After reinstalling to Ubuntu, the default user is `ecs-user` or `ubuntu`, NOT `root`. Root login may be disabled by default in `sshd_config`.
- **Cloud provider "security hardening" checkbox:** On aliyun/腾讯云, the "free security hardening" (云安全中心) installs a daemon that uses 50-100MB RAM. On a 512MB VPS, this is 10-20% of total memory. Uncheck it during reinstall.
