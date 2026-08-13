#!/bin/bash
#
# 回滚脚本
# 用法：rollback.sh <component> <timestamp>
#   component: hermes | openclaw
#   timestamp: 更新时间戳（从 backups/ 目录获取）
#

set -euo pipefail

TEAM_DIR="/opt/openclaw-team"
BACKUP_DIR="$TEAM_DIR/backups"

log() {
    echo "[$(date '+%H:%M:%S')] $*"
}

usage() {
    echo "用法: $0 <component> <timestamp>"
    echo ""
    echo "component: hermes | openclaw"
    echo "timestamp: 更新时间戳（格式: YYYYMMDD_HHMMSS）"
    echo ""
    echo "可用的回滚点:"
    echo ""
    echo "Hermes:"
    ls -1 "$BACKUP_DIR/hermes/pre-update-"*.json 2>/dev/null | sed 's/.*pre-update-//' | sed 's/.json//' || echo "  无"
    echo ""
    echo "OpenClaw:"
    ls -1 "$BACKUP_DIR/openclaw/pre-update-"*.json 2>/dev/null | sed 's/.*pre-update-//' | sed 's/.json//' || echo "  无"
    exit 1
}

if [ $# -lt 2 ]; then
    usage
fi

COMPONENT="$1"
TIMESTAMP="$2"

log "=== 回滚 $COMPONENT 到 $TIMESTAMP ==="

case "$COMPONENT" in
    hermes)
        HERMES_DIR="/opt/WorkStation/hermes-agent"
        PRE_FILE="$BACKUP_DIR/hermes/pre-update-${TIMESTAMP}.json"

        if [ ! -f "$PRE_FILE" ]; then
            echo "❌ 回滚点不存在: $PRE_FILE"
            usage
        fi

        # 读取回滚信息
        commit_before=$(python3 -c "import json; print(json.load(open('$PRE_FILE'))['commit_before'])")
        version_before=$(python3 -c "import json; print(json.load(open('$PRE_FILE'))['version_before'])")

        log "目标版本: $version_before ($commit_before)"
        echo ""
        read -p "确认回滚? (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            log "取消回滚"
            exit 0
        fi

        cd "$HERMES_DIR"
        git checkout "$commit_before" --quiet
        log "✅ 已回滚到 $version_before"
        ;;

    openclaw)
        PRE_FILE="$BACKUP_DIR/openclaw/pre-update-${TIMESTAMP}.json"
        COMPOSE_BACKUP="$BACKUP_DIR/openclaw/docker-compose.yml.pre-${TIMESTAMP}"

        if [ ! -f "$PRE_FILE" ]; then
            echo "❌ 回滚点不存在: $PRE_FILE"
            usage
        fi

        image_before=$(python3 -c "import json; print(json.load(open('$PRE_FILE'))['image_before'])")
        version_before=$(python3 -c "import json; print(json.load(open('$PRE_FILE'))['version_before'])")

        log "目标镜像: $image_before"
        echo ""
        read -p "确认回滚? (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            log "取消回滚"
            exit 0
        fi

        # 恢复 docker-compose.yml
        if [ -f "$COMPOSE_BACKUP" ]; then
            cp "$COMPOSE_BACKUP" "$TEAM_DIR/docker-compose.yml"
            log "已恢复 docker-compose.yml"
        fi

        # 重建所有容器
        cd "$TEAM_DIR"
        docker-compose down --timeout 10 2>/dev/null || true
        docker-compose up -d 2>/dev/null

        log "✅ 已回滚到 $version_before"
        ;;

    *)
        echo "❌ 未知组件: $COMPONENT"
        usage
        ;;
esac

echo ""
log "回滚完成。请验证服务是否正常。"
