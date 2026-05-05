#!/usr/bin/env python3
"""
Clash 节点连通性监控脚本
1. 检查当前 🤖AI网站 代理节点的连通性
2. 如果超时，自动切换到圣何塞最快的可用节点
3. 如果所有圣何塞节点都超时，进入紧急模式（高频检测）
4. 状态和日志保存在 ~/.hermes/clash-monitor/
"""

import json
import os
import socket
import sys
import time
from datetime import datetime
from urllib.parse import quote

CLASH_SOCKET = "/tmp/verge/verge-mihomo.sock"
LOG_DIR = os.path.expanduser("~/.hermes/clash-monitor")
TEST_URL = "https://www.google.com/generate_204"
TIMEOUT = 5  # seconds

os.makedirs(LOG_DIR, exist_ok=True)
LOG_FILE = os.path.join(LOG_DIR, "monitor.log")
STATUS_FILE = os.path.join(LOG_DIR, "status.json")


def clash_request(method, path, body=None):
    """Make an HTTP request to Clash API via Unix socket"""
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.settimeout(15)
    try:
        sock.connect(CLASH_SOCKET)

        headers = f"Host: localhost\r\nConnection: close\r\n"
        if body:
            body_str = json.dumps(body)
            headers += f"Content-Type: application/json\r\nContent-Length: {len(body_str)}\r\n"
            req = f"{method} {path} HTTP/1.1\r\n{headers}\r\n{body_str}"
        else:
            req = f"{method} {path} HTTP/1.1\r\n{headers}\r\n"

        sock.sendall(req.encode())

        data = b""
        while True:
            chunk = sock.recv(4096)
            if not chunk:
                break
            data += chunk

        # Parse HTTP response
        header_end = data.find(b"\r\n\r\n")
        if header_end == -1:
            return None

        body_data = data[header_end + 4:]

        # Decode chunked transfer encoding if present
        headers_part = data[:header_end].decode().lower()
        if "chunked" in headers_part:
            raw = body_data
            decoded = b""
            while raw:
                line_end = raw.find(b"\r\n")
                if line_end == -1:
                    break
                size_hex = raw[:line_end].decode().strip()
                try:
                    size = int(size_hex, 16)
                except ValueError:
                    break
                if size == 0:
                    break
                decoded += raw[line_end + 2:line_end + 2 + size]
                raw = raw[line_end + 2 + size + 2:]
            body_data = decoded

        try:
            return json.loads(body_data)
        except json.JSONDecodeError:
            return None
    except Exception:
        return None
    finally:
        sock.close()


def log(msg):
    ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    line = f"[{ts}] {msg}"
    print(line)
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(line + "\n")


def get_current_proxy():
    """Get the current selected proxy for 🤖AI网站 group"""
    data = clash_request("GET", "/proxies")
    if not data:
        return None, None
    ai_group = data.get("proxies", {}).get("🤖AI网站")
    if not ai_group:
        return None, None
    now = ai_group.get("now", "")
    all_nodes = ai_group.get("all", [])
    return now, all_nodes


def test_proxy_latency(proxy_name):
    """Test latency of a specific proxy via Clash API"""
    url = f"/proxies/{quote(proxy_name, safe='')}/delay?url={quote(TEST_URL, safe='')}&timeout={TIMEOUT * 1000}"
    result = clash_request("GET", url)
    if result and "delay" in result:
        return result["delay"]
    return None


def switch_proxy(group, proxy_name):
    """Switch the proxy group to a specific node"""
    path = f"/proxies/{quote(group, safe='')}"
    result = clash_request("PUT", path, {"name": proxy_name})
    return result is not None


def find_sj_nodes(all_nodes):
    """Find all San Jose (圣何塞) nodes"""
    return [node for node in all_nodes if "圣何塞" in node]


def test_nodes(nodes):
    """Test a list of nodes, return list of (name, latency_ms or None)"""
    results = []
    for node in nodes:
        latency = test_proxy_latency(node)
        results.append((node, latency))
    return results


def save_status(current, fastest=None, emergency=False):
    status = {
        "timestamp": datetime.now().isoformat(),
        "current_proxy": current,
        "fastest_proxy": fastest,
        "emergency_mode": emergency,
    }
    with open(STATUS_FILE, "w", encoding="utf-8") as f:
        json.dump(status, f, ensure_ascii=False, indent=2)


def main():
    log("Starting Clash node connectivity monitor...")

    # Get current proxy
    current_proxy, all_nodes = get_current_proxy()
    if not current_proxy:
        log("ERROR: Cannot reach Clash API or 🤖AI网站 group not found")
        log("Make sure Clash Verge is running")
        sys.exit(1)

    log(f"Current proxy: {current_proxy}")

    # Test current proxy
    current_latency = test_proxy_latency(current_proxy)

    if current_latency is not None and current_latency > 0:
        log(f"Current node OK: {current_latency}ms ✓")
        save_status(current_proxy, current_proxy)
        return

    # Current node failed, find SJ nodes
    log(f"Current node timed out or failed. Testing 圣何塞 nodes...")

    if not all_nodes:
        log("ERROR: No nodes in 🤖AI网站 group")
        save_status(current_proxy, emergency=True)
        return

    sj_nodes = find_sj_nodes(all_nodes)

    if not sj_nodes:
        log("ERROR: No 圣何塞 nodes found!")
        save_status(current_proxy, emergency=True)
        return

    # Test all SJ nodes
    results = test_nodes(sj_nodes)

    working_nodes = []
    for name, latency in results:
        if latency is not None and latency > 0:
            working_nodes.append((name, latency))
            log(f"  {name}: {latency}ms ✓")
        else:
            log(f"  {name}: timeout ✗")

    if working_nodes:
        # Sort by latency, pick fastest
        working_nodes.sort(key=lambda x: x[1])
        fastest_name, fastest_latency = working_nodes[0]
        log(f"Switching to fastest: {fastest_name} ({fastest_latency}ms)")

        ok = switch_proxy("🤖AI网站", fastest_name)
        if ok:
            log(f"✅ Switched to {fastest_name}")
            save_status(fastest_name, fastest_name)
        else:
            log(f"❌ Failed to switch proxy")
            save_status(current_proxy, emergency=True)
    else:
        log("⚠️ EMERGENCY MODE: All 圣何塞 nodes timed out!")
        log("Entering high-frequency detection mode...")
        save_status(current_proxy, emergency=True)

        # Emergency: re-test after short delay
        time.sleep(10)
        log("Re-testing 圣何塞 nodes...")
        results2 = test_nodes(sj_nodes)
        working2 = [(n, l) for n, l in results2 if l is not None and l > 0]

        if working2:
            working2.sort(key=lambda x: x[1])
            fastest_name, fastest_latency = working2[0]
            log(f"Recovery found: {fastest_name} ({fastest_latency}ms)")
            switch_proxy("🤖AI网站", fastest_name)
            log(f"✅ Recovered to {fastest_name}")
            save_status(fastest_name, fastest_name)
        else:
            log("Still no available nodes. Will retry in next check.")
            save_status(current_proxy, emergency=True)


if __name__ == "__main__":
    main()
