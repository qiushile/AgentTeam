#!/usr/bin/env python3
"""Find the fastest node matching a keyword in a Clash Verge proxy group and switch to it.

Usage:
    python3 switch_fastest.py <group_keyword> <node_keyword>

Examples:
    python3 switch_fastest.py "AI网站" "圣何塞"
    python3 switch_fastest.py "节点选择" "日本"
    python3 switch_fastest.py "漏网之鱼" "新加坡"
"""

import json
import subprocess
import sys
import urllib.parse
import urllib.request

SOCKET_PATH = "/tmp/verge/verge-mihomo.sock"

def get_proxies():
    """Fetch all proxies from the Clash Verge Unix socket."""
    result = subprocess.run(
        ["curl", "-s", "--unix-socket", SOCKET_PATH, "http://localhost/proxies"],
        capture_output=True, text=True
    )
    if not result.stdout.strip():
        print("ERROR: Could not connect to Clash Verge socket. Is it running?")
        sys.exit(1)
    return json.loads(result.stdout)

def find_proxy_group(proxies, keyword):
    """Find a proxy group name containing the keyword."""
    for name, info in proxies.items():
        if keyword in name and info.get("type") in ["Selector", "URLTest", "Fallback", "LoadBalance"]:
            return name, info
    return None, None

def get_node_latency(proxies, node_name):
    """Get the last recorded latency for a node."""
    info = proxies.get(node_name, {})
    history = info.get("history", [])
    if history:
        return history[-1].get("delay", float("inf"))
    return float("inf")

def switch_proxy(group_name, target_node):
    """Switch a proxy group to a specific node."""
    encoded = urllib.parse.quote(group_name, safe="")
    url = f"http://localhost/proxies/{encoded}"
    data = json.dumps({"name": target_node}).encode()
    
    import http.client
    import socket
    
    conn = http.client.HTTPConnection("localhost", timeout=10)
    conn.sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    conn.sock.connect(SOCKET_PATH)
    conn.request("PUT", url, body=data, headers={"Content-Type": "application/json"})
    resp = conn.getresponse()
    
    if resp.status == 204 or resp.status == 200:
        return True
    else:
        print(f"ERROR: Switch failed (HTTP {resp.status})")
        return False

def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    
    group_keyword = sys.argv[1]
    node_keyword = sys.argv[2]
    
    proxies = get_proxies()
    
    # Find the target group
    group_name, group_info = find_proxy_group(proxies, group_keyword)
    if not group_name:
        print(f"ERROR: No proxy group found matching '{group_keyword}'")
        print("Available groups:")
        for name, info in proxies.items():
            if info.get("type") in ["Selector", "URLTest", "Fallback", "LoadBalance"]:
                print(f"  {name} ({info['type']}, current: {info.get('now', 'none')})")
        sys.exit(1)
    
    print(f"Found group: {group_name} (currently: {group_info.get('now', 'none')})")
    
    # Find matching nodes and their latencies
    node_candidates = []
    for node_name in group_info.get("all", []):
        if node_keyword in node_name:
            latency = get_node_latency(proxies, node_name)
            node_candidates.append((node_name, latency))
    
    if not node_candidates:
        print(f"ERROR: No nodes matching '{node_keyword}' in group '{group_name}'")
        sys.exit(1)
    
    # Sort by latency (fastest first, nodes with no latency last)
    node_candidates.sort(key=lambda x: x[1])
    
    print(f"\nMatching nodes ({len(node_candidates)} found), sorted by latency:")
    for i, (name, delay) in enumerate(node_candidates[:10]):
        marker = " ⚡ FASTEST" if i == 0 else ""
        delay_str = f"{delay}ms" if delay != float("inf") else "no data"
        current = " (current)" if name == group_info.get("now") else ""
        print(f"  {i+1}. {name}: {delay_str}{current}{marker}")
    
    if len(node_candidates) > 10:
        print(f"  ... and {len(node_candidates) - 10} more")
    
    fastest = node_candidates[0][0]
    print(f"\nSwitching {group_name} → {fastest}")
    
    if switch_proxy(group_name, fastest):
        print("✅ Success!")
    else:
        print("❌ Failed to switch")
        sys.exit(1)

if __name__ == "__main__":
    main()
