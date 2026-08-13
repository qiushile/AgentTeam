#!/bin/bash
#
# Patch 兼容性检查脚本
# 检查 patches/inventory.json 中的每个 patch 是否已被 upstream 合入
#

set -euo pipefail

TEAM_DIR="/opt/openclaw-team"
INVENTORY="$TEAM_DIR/patches/inventory.json"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

log() {
    echo "[$TIMESTAMP] $*"
}

if [ ! -f "$INVENTORY" ]; then
    echo "❌ inventory.json 不存在: $INVENTORY"
    exit 1
fi

log "=== Patch 兼容性检查 ==="
echo ""

# 读取 patch 数量
patch_count=$(python3 -c "import json; d=json.load(open('$INVENTORY')); print(len(d['patches']))")
log "共 $patch_count 个 patch 需要检查"
echo ""

# 逐个检查
python3 << 'PYEOF'
import json
import subprocess
import sys
import os

INVENTORY = "/opt/openclaw-team/patches/inventory.json"
HERMES_REPO = "/opt/WorkStation/hermes-agent"

with open(INVENTORY, "r", encoding="utf-8") as f:
    data = json.load(f)

results = []

for patch in data["patches"]:
    pid = patch["id"]
    target_repo = patch["target_repo"]
    target_file = patch["target_file"]
    upstream_status = patch["upstream_status"]
    applied = patch["applied"]

    result = {
        "id": pid,
        "target_file": target_file,
        "current_status": upstream_status,
        "applied": applied,
        "check_result": "unknown",
        "details": ""
    }

    if target_repo == "hermes-agent":
        # 检查 upstream 是否已合入
        try:
            # 在 upstream main 中搜索关键代码特征
            check_cmd = f"cd {HERMES_REPO} && git show origin/main:{target_file} 2>/dev/null | grep -c 'command_preview'"
            proc = subprocess.run(check_cmd, shell=True, capture_output=True, text=True)
            match_count = int(proc.stdout.strip()) if proc.stdout.strip().isdigit() else 0

            if match_count > 0:
                result["check_result"] = "merged"
                result["details"] = f"upstream 已包含 command_preview ({match_count} 处匹配)"
            else:
                result["check_result"] = "not_merged"
                result["details"] = "upstream 未包含此修改"

            # 检查 patch 是否能干净应用
            patch_file = os.path.join("/opt/openclaw-team", patch["patch_file"])
            if os.path.exists(patch_file):
                check_apply = f"cd {HERMES_REPO} && git apply --check {patch_file} 2>&1"
                proc2 = subprocess.run(check_apply, shell=True, capture_output=True, text=True)
                if proc2.returncode == 0:
                    result["can_apply"] = True
                    result["details"] += " | patch 可干净应用"
                else:
                    result["can_apply"] = False
                    result["details"] += f" | patch 应用失败: {proc2.stderr.strip()[:100]}"
        except Exception as e:
            result["check_result"] = "error"
            result["details"] = str(e)

    results.append(result)

    # 输出
    status_icon = {
        "merged": "✅",
        "not_merged": "⚠️",
        "error": "❌",
        "unknown": "❓"
    }
    icon = status_icon.get(result["check_result"], "❓")
    print(f"{icon} [{pid}] {result['details']}")

# 汇总
print("")
merged = sum(1 for r in results if r["check_result"] == "merged")
not_merged = sum(1 for r in results if r["check_result"] == "not_merged")
errors = sum(1 for r in results if r["check_result"] == "error")

print(f"汇总: {merged} 已合入 | {not_merged} 未合入 | {errors} 检查失败")

if merged > 0:
    print("")
    print("💡 已合入的 patch 可以安全删除，减少维护负担")
if not_merged > 0:
    print("")
    print("⚠️  未合入的 patch 在更新后需要重新应用")
PYEOF
