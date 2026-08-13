#!/bin/bash
#
# 版本更新检测脚本
# 用法：update-check.sh [hermes|openclaw|all]
# 检查 GitHub 最新稳定版并与本地版本对比
#

set -euo pipefail

TEAM_DIR="/opt/openclaw-team"
STATE_FILE="$TEAM_DIR/monitor/update-check-state.json"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
DATE=$(date '+%Y-%m-%d')

# 代理设置（国内访问 GitHub）
export HTTPS_PROXY=http://127.0.0.1:7890

log() {
    echo "[$TIMESTAMP] $*"
}

# ========== 版本检测函数 ==========

check_hermes_version() {
    local result=""
    local has_update="false"

    # 本地版本（使用 git tag 而非 hermes --version，因为 tag 和 release 一致）
    local local_version
    if [ -d "/opt/WorkStation/hermes-agent/.git" ]; then
        local_version=$(cd /opt/WorkStation/hermes-agent && git describe --tags HEAD 2>/dev/null | sed 's/-.*//' | sed 's/^v//')
    elif command -v hermes &>/dev/null; then
        local_version=$(hermes --version 2>/dev/null | grep -oP 'v\K[0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
    else
        local_version="unknown"
    fi

    # 远程最新稳定版
    local remote_version remote_date
    remote_version=$(gh api repos/NousResearch/hermes-agent/releases/latest -q '.tag_name' 2>/dev/null | sed 's/^v//')
    remote_date=$(gh api repos/NousResearch/hermes-agent/releases/latest -q '.published_at[0:10]' 2>/dev/null)

    if [ -z "$remote_version" ]; then
        echo '{"component":"hermes","status":"error","message":"无法获取远程版本"}'
        return
    fi

    # 比对
    if [ "$local_version" != "$remote_version" ] && [ "$local_version" != "unknown" ]; then
        has_update="true"
    fi

    # 本地 git 状态
    local behind=0
    if [ -d "/opt/WorkStation/hermes-agent/.git" ]; then
        cd /opt/WorkStation/hermes-agent
        git fetch origin --quiet 2>/dev/null || true
        behind=$(git rev-list HEAD..origin/main --count 2>/dev/null || echo 0)
    fi

    cat <<EOF
{
  "component": "hermes",
  "local_version": "$local_version",
  "remote_version": "$remote_version",
  "remote_date": "$remote_date",
  "has_update": $has_update,
  "commits_behind": $behind,
  "status": "checked"
}
EOF
}

check_openclaw_version() {
    local result=""
    local has_update="false"

    # 本地版本（从 docker 容器获取）
    local local_version
    local_version=$(docker inspect --format='{{.Config.Image}}' openclaw-orchestrator 2>/dev/null | grep -oP 'v\K[0-9]+\.[0-9]+\.[0-9]+(-[0-9]+)?' || echo "unknown")

    # 远程最新稳定版
    local remote_version remote_date
    remote_version=$(gh api repos/openclaw/openclaw/releases/latest -q '.tag_name' 2>/dev/null | sed 's/^v//')
    remote_date=$(gh api repos/openclaw/openclaw/releases/latest -q '.published_at[0:10]' 2>/dev/null)

    if [ -z "$remote_version" ]; then
        echo '{"component":"openclaw","status":"error","message":"无法获取远程版本"}'
        return
    fi

    # 比对
    if [ "$local_version" != "$remote_version" ] && [ "$local_version" != "unknown" ]; then
        has_update="true"
    fi

    # 容器数量
    local container_count
    container_count=$(docker ps --filter "ancestor=openclaw:${local_version}" -q 2>/dev/null | wc -l || echo 0)

    cat <<EOF
{
  "component": "openclaw",
  "local_version": "$local_version",
  "remote_version": "$remote_version",
  "remote_date": "$remote_date",
  "has_update": $has_update,
  "container_count": $container_count,
  "status": "checked"
}
EOF
}

# ========== 主流程 ==========

TARGET="${1:-all}"

log "=== 版本更新检测 ($TARGET) ==="

results=()

if [ "$TARGET" = "hermes" ] || [ "$TARGET" = "all" ]; then
    hermes_result=$(check_hermes_version)
    results+=("$hermes_result")
fi

if [ "$TARGET" = "openclaw" ] || [ "$TARGET" = "all" ]; then
    openclaw_result=$(check_openclaw_version)
    results+=("$openclaw_result")
fi

# 保存状态
{
    echo "{"
    echo "  \"last_check\": \"$TIMESTAMP\","
    echo "  \"results\": ["
    for i in "${!results[@]}"; do
        if [ $i -gt 0 ]; then echo ","; fi
        echo "    ${results[$i]}"
    done
    echo "  ]"
    echo "}"
} > "$STATE_FILE"

# 输出报告
echo ""
echo "📋 版本检测报告 ($DATE)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for r in "${results[@]}"; do
    comp=$(echo "$r" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['component'])")
    local_v=$(echo "$r" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('local_version','?'))")
    remote_v=$(echo "$r" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('remote_version','?'))")
    has_up=$(echo "$r" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('has_update',False))")
    remote_date=$(echo "$r" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('remote_date','?'))")

    if [ "$has_up" = "True" ]; then
        echo "⚠️  $comp: $local_v → $remote_v (发布于 $remote_date)"
    elif [ "$has_up" = "False" ]; then
        echo "✅  $comp: $local_v (最新)"
    else
        echo "❓  $comp: 检测异常"
    fi
done

echo ""
echo "状态已保存到: $STATE_FILE"

# 检查是否有更新需要处理
any_update=$(echo "${results[*]}" | grep -c '"has_update": true' || true)
if [ "$any_update" -gt 0 ]; then
    echo ""
    echo "🔔 发现 $any_update 个组件有新版本可用"
    echo "执行更新: bash $TEAM_DIR/scripts/update-hermes.sh / update-openclaw.sh"
fi
