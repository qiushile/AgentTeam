#!/bin/bash
# restore.sh - PostgreSQL 数据库恢复脚本
# 用法: ./restore.sh <backup_file> [--dry-run]

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../.dev-config.json"

DB_HOST=$(node -e "const c=require('$CONFIG_FILE');console.log(c.db_host)")
DB_PORT=$(node -e "const c=require('$CONFIG_FILE');console.log(c.db_port)")
DB_NAME=$(node -e "const c=require('$CONFIG_FILE');console.log(c.db_name)")
DB_USER="postgres"
DB_PASS=$POSTGRES_PASSWORD

BACKUP_DIR="/backups/dev_db/daily"
DRY_RUN=false

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# 解析参数
BACKUP_FILE=""
for arg in "$@"; do
  if [ "$arg" = "--dry-run" ]; then
    DRY_RUN=true
  elif [ -z "$BACKUP_FILE" ]; then
    BACKUP_FILE="$arg"
  fi
done

# 如果没有指定文件，使用最新备份
if [ -z "$BACKUP_FILE" ]; then
  BACKUP_FILE=$(ls -t "$BACKUP_DIR"/*.dump 2>/dev/null | head -1)
  if [ -z "$BACKUP_FILE" ]; then
    log "ERROR: 没有可用的备份文件"
    exit 1
  fi
  log "使用最新备份: $BACKUP_FILE"
fi

if [ ! -f "$BACKUP_FILE" ]; then
  log "ERROR: 备份文件不存在: $BACKUP_FILE"
  exit 1
fi

log "备份文件: $BACKUP_FILE ($(du -h $BACKUP_FILE | cut -f1))"

if [ "$DRY_RUN" = true ]; then
  log "=== 模拟恢复 (Dry Run) ==="
  log "将执行: pg_restore -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME --clean --if-exists $BACKUP_FILE"
  pg_restore -l "$BACKUP_FILE"
  log "Dry Run 完成。实际恢复请移除 --dry-run 参数"
  exit 0
fi

log "⚠️  即将恢复数据库 $DB_NAME，这将覆盖现有数据!"
log "确认恢复? (yes/no)"
read -r confirm

if [ "$confirm" != "yes" ]; then
  log "恢复已取消"
  exit 0
fi

# 创建备份当前状态 (安全网)
SAFETY_BACKUP="/backups/dev_db/pre_restore_$(date +%Y%m%d_%H%M%S).dump"
log "创建恢复前备份: $SAFETY_BACKUP"
PGPASSWORD="$DB_PASS" pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -Fc -f "$SAFETY_BACKUP" "$DB_NAME"

# 执行恢复
log "开始恢复..."
PGPASSWORD="$DB_PASS" pg_restore \
  -h "$DB_HOST" \
  -p "$DB_PORT" \
  -U "$DB_USER" \
  -d "$DB_NAME" \
  --clean \
  --if-exists \
  "$BACKUP_FILE"

log "✅ 恢复完成!"
log "恢复前备份保存在: $SAFETY_BACKUP"
log "如需回滚，运行: $0 $SAFETY_BACKUP"
