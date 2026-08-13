#!/bin/bash
#
# OpenClaw 容器滚动更新脚本
# 流程：拉取新镜像 → 逐个重建容器 → 验证健康
#

set -euo pipefail

TEAM_DIR="/opt/openclaw-team"
BACKUP_DIR="$TEAM_DIR/backups/openclaw"
COMPOSE_FILE="$TEAM_DIR/docker-compose.yml"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')

log() {
    echo "[$(date '+%H:%M:%S')] $*"
}

error_exit() {
    log "❌ $1"
    exit 1
}

# ========== 参数解析 ==========
DRY_RUN=false
SERVICE=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=true; shift ;;
        --service) SERVICE="$2"; shift 2 ;;
        *) shift ;;
    esac
done

log "=== OpenClaw 容器更新开始 ==="

# ========== Step 1: 记录当前状态 ==========
log "Step 1: 记录当前状态"

current_image=$(docker inspect --format='{{.Config.Image}}' openclaw-orchestrator 2>/dev/null || echo "unknown")
current_version=$(echo "$current_image" | grep -oP 'v\K[0-9]+\.[0-9]+\.[0-9]+(-[0-9]+)?' || echo "unknown")

mkdir -p "$BACKUP_DIR"
cat > "$BACKUP_DIR/pre-update-${TIMESTAMP}.json" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "component": "openclaw",
  "image_before": "$current_image",
  "version_before": "$current_version",
  "container_count": $(docker ps --filter "name=openclaw-" -q 2>/dev/null | wc -l)
}
EOF
log "  当前镜像: $current_image"

# ========== Step 2: 获取最新稳定版 ==========
log "Step 2: 查询最新稳定版"

export HTTPS_PROXY=http://127.0.0.1:7890
latest_version=$(gh api repos/openclaw/openclaw/releases/latest -q '.tag_name' 2>/dev/null | sed 's/^v//')

if [ -z "$latest_version" ]; then
    error_exit "无法获取最新版本号"
fi

log "  最新稳定版: v$latest_version"

if [ "$current_version" = "$latest_version" ]; then
    log "  已是最新，无需更新"
    exit 0
fi

log "  更新: v$current_version → v$latest_version"

if [ "$DRY_RUN" = true ]; then
    log "  [DRY RUN] 不执行实际操作"
    exit 0
fi

# ========== Step 3: 拉取新镜像 ==========
log "Step 3: 拉取新镜像"

new_image="openclaw:v${latest_version}"
if ! docker image inspect "$new_image" &>/dev/null; then
    log "  镜像不存在，需要构建或拉取"
    # OpenClaw 镜像通常需要手动构建，这里只做检查
    echo ""
    echo "⚠️  新镜像 $new_image 不存在"
    echo "请先构建镜像，然后重新运行此脚本"
    echo ""
    echo "构建方式（参考）："
    echo "  docker build -t $new_image /path/to/openclaw-source"
    exit 1
fi
log "  ✅ 镜像已就绪: $new_image"

# ========== Step 4: 更新 docker-compose.yml ==========
log "Step 4: 更新 docker-compose.yml"

# 备份当前 compose 文件
cp "$COMPOSE_FILE" "$BACKUP_DIR/docker-compose.yml.pre-${TIMESTAMP}"

# 替换镜像版本
sed -i "s|openclaw:v[0-9.]*\(-[0-9]*\)\?|${new_image}|g" "$COMPOSE_FILE"
log "  ✅ 已更新镜像引用"

# ========== Step 5: 滚动重建容器 ==========
log "Step 5: 滚动重建容器"

# 获取所有 openclaw 容器（排除 postgres）
containers=$(docker ps --filter "name=openclaw-" --filter "name!=postgres" --format '{{.Names}}' 2>/dev/null | sort)
total=$(echo "$containers" | wc -l)
current=0

for container in $containers; do
    current=$((current + 1))
    log "  [$current/$total] 重建 $container"

    # 停止旧容器
    docker stop "$container" --time 10 2>/dev/null || true
    docker rm "$container" 2>/dev/null || true

    # 使用新镜像启动
    cd "$TEAM_DIR"
    docker-compose up -d "$container" 2>/dev/null || {
        log "  ⚠️  $container 启动失败，尝试继续"
    }

    # 等待健康检查
    sleep 3
    status=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "unknown")
    log "    状态: $status"
done

# ========== Step 6: 验证 ==========
log "Step 6: 验证所有容器"

sleep 5
healthy=0
unhealthy=0

for container in $containers; do
    status=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "unknown")
    if [ "$status" = "healthy" ]; then
        healthy=$((healthy + 1))
    else
        unhealthy=$((unhealthy + 1))
        log "  ⚠️  $container: $status"
    fi
done

log "  健康: $healthy / $total"

# ========== 完成 ==========
log "=== OpenClaw 容器更新完成 ==="
echo ""
echo "更新摘要:"
echo "  版本: v$current_version → v$latest_version"
echo "  容器: $healthy 健康 / $unhealthy 异常 / $total 总计"
echo ""

if [ $unhealthy -gt 0 ]; then
    echo "⚠️  有 $unhealthy 个容器未通过健康检查"
    echo "检查日志: docker logs <container-name>"
fi

# 记录更新后状态
cat > "$BACKUP_DIR/post-update-${TIMESTAMP}.json" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "component": "openclaw",
  "image_after": "$new_image",
  "version_after": "$latest_version",
  "healthy": $healthy,
  "unhealthy": $unhealthy,
  "total": $total
}
EOF
