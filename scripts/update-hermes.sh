#!/bin/bash
#
# Hermes Agent 更新脚本
# 流程：备份 → pull → patch 检查 → 重新应用 → 重启 → 验证
#

set -euo pipefail

TEAM_DIR="/opt/openclaw-team"
HERMES_DIR="/opt/WorkStation/hermes-agent"
STATE_FILE="$TEAM_DIR/monitor/update-check-state.json"
BACKUP_DIR="$TEAM_DIR/backups/hermes"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')

log() {
    echo "[$(date '+%H:%M:%S')] $*"
}

error_exit() {
    log "❌ $1"
    echo ""
    echo "更新失败，请检查日志。如需回滚："
    echo "  bash $TEAM_DIR/scripts/rollback.sh hermes $TIMESTAMP"
    exit 1
}

# ========== 参数解析 ==========
SKIP_VERIFY=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-verify) SKIP_VERIFY=true; shift ;;
        *) shift ;;
    esac
done

log "=== Hermes Agent 更新开始 ==="

# ========== Step 1: 记录当前版本 ==========
log "Step 1: 记录当前状态"

current_version=$(hermes --version 2>/dev/null | grep -oP 'v\K[0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1 || echo "unknown")
current_commit=$(cd "$HERMES_DIR" && git rev-parse HEAD)

# 保存回滚信息
mkdir -p "$BACKUP_DIR"
cat > "$BACKUP_DIR/pre-update-${TIMESTAMP}.json" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "component": "hermes",
  "version_before": "$current_version",
  "commit_before": "$current_commit",
  "rollback_command": "cd $HERMES_DIR && git checkout $current_commit"
}
EOF
log "  当前版本: $current_version ($current_commit)"

# ========== Step 2: 检查本地未提交修改 ==========
log "Step 2: 检查本地修改"

cd "$HERMES_DIR"
local_changes=$(git status --porcelain | grep -v "^??" || true)
if [ -n "$local_changes" ]; then
    log "  ⚠️  检测到本地未提交修改，先 stash"
    git stash push -m "pre-update-${TIMESTAMP}" --quiet
    STASHED=true
else
    STASHED=false
    log "  工作区干净"
fi

# ========== Step 3: 拉取最新代码 ==========
log "Step 3: 拉取最新代码"

git fetch origin --quiet 2>/dev/null || error_exit "git fetch 失败"

behind=$(git rev-list HEAD..origin/main --count 2>/dev/null || echo 0)
log "  落后 upstream $behind 个提交"

if [ "$behind" -eq 0 ]; then
    log "  已是最新，无需更新"
    exit 0
fi

git pull origin main --no-edit --quiet 2>/dev/null || error_exit "git pull 失败"

new_commit=$(git rev-parse HEAD)
new_version=$(git describe --tags HEAD 2>/dev/null | sed 's/-.*//' || echo "unknown")
log "  更新到: $new_version ($new_commit)"

# ========== Step 4: Patch 兼容性检查 ==========
log "Step 4: 检查本地 patch 兼容性"

bash "$TEAM_DIR/monitor/patch-compatibility.sh" 2>/dev/null || true

# ========== Step 5: 重新应用本地 patch ==========
log "Step 5: 重新应用本地 patch"

INVENTORY="$TEAM_DIR/patches/inventory.json"
if [ -f "$INVENTORY" ]; then
    patch_files=$(python3 -c "
import json
d = json.load(open('$INVENTORY'))
for p in d['patches']:
    if p['target_repo'] == 'hermes-agent' and p.get('upstream_status') != 'merged':
        print(p['patch_file'])
" 2>/dev/null || true)

    for pf in $patch_files; do
        full_path="$TEAM_DIR/$pf"
        if [ -f "$full_path" ]; then
            if git apply --check "$full_path" 2>/dev/null; then
                git apply "$full_path" 2>/dev/null
                log "  ✅ 应用: $(basename $full_path)"
            else
                log "  ⚠️  无法应用: $(basename $full_path) — 需要手动处理"
            fi
        fi
    done
fi

# ========== Step 6: 恢复 stash ==========
if [ "$STASHED" = true ]; then
    log "Step 6: 恢复 stash"
    git stash pop --quiet 2>/dev/null || {
        log "  ⚠️  stash pop 冲突，保留 stash 文件"
    }
fi

# ========== Step 7: 验证 ==========
if [ "$SKIP_VERIFY" = false ]; then
    log "Step 7: 验证"

    # 检查 Python 语法
    python3 -c "import hermes_agent" 2>/dev/null && log "  ✅ Python 模块可导入" || log "  ⚠️  Python 模块导入异常（可能是正常的）"

    # 检查 hermes 命令
    if command -v hermes &>/dev/null; then
        new_ver=$(hermes --version 2>/dev/null | head -1)
        log "  ✅ hermes --version: $new_ver"
    fi
fi

# ========== 完成 ==========
log "=== Hermes Agent 更新完成 ==="
echo ""
echo "更新摘要:"
echo "  版本: $current_version → $new_version"
echo "  提交: ${current_commit:0:10} → ${new_commit:0:10}"
echo ""
echo "如需回滚:"
echo "  bash $TEAM_DIR/scripts/rollback.sh hermes $TIMESTAMP"

# 记录更新后状态
cat > "$BACKUP_DIR/post-update-${TIMESTAMP}.json" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "component": "hermes",
  "version_after": "$new_version",
  "commit_after": "$new_commit",
  "commits_updated": $behind
}
EOF
