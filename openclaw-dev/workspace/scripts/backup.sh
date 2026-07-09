#!/bin/bash
# backup.sh - PostgreSQL 数据库备份脚本
# 用法: ./backup.sh [full|incremental]
# 全量备份: 每日凌晨 2 点执行 (crontab)
# 增量备份: 每小时执行关键表热备份

set -e

# 配置 - 从 .dev-config.json 读取
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../.dev-config.json"

DB_HOST=$(node -e "const c=require('$CONFIG_FILE');console.log(c.db_host)")
DB_PORT=$(node -e "const c=require('$CONFIG_FILE');console.log(c.db_port)")
DB_NAME=$(node -e "const c=require('$CONFIG_FILE');console.log(c.db_name)")
DB_USER="postgres"  # 备份需要 postgres 用户
DB_PASS=$POSTGRES_PASSWORD  # 从环境变量读取

BACKUP_DIR="/backups/dev_db"
DAILY_DIR="$BACKUP_DIR/daily"
HOURLY_DIR="$BACKUP_DIR/hourly"
RETENTION_DAYS=7
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# 创建备份目录
mkdir -p "$DAILY_DIR" "$HOURLY_DIR"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# 全量备份
full_backup() {
  local backup_file="$DAILY_DIR/dev_db_${TIMESTAMP}.dump"
  log "开始全量备份: $backup_file"
  
  PGPASSWORD="$DB_PASS" pg_dump \
    -h "$DB_HOST" \
    -p "$DB_PORT" \
    -U "$DB_USER" \
    -Fc \
    -Z 9 \
    -f "$backup_file" \
    "$DB_NAME"
  
  local size=$(du -h "$backup_file" | cut -f1)
  log "全量备份完成: $size"
  
  # 校验备份文件大小
  if [ ! -s "$backup_file" ]; then
    log "ERROR: 备份文件为空!"
    exit 1
  fi
  
  # 清理旧备份
  log "清理 ${RETENTION_DAYS} 天前的备份..."
  find "$DAILY_DIR" -name "*.dump" -mtime +${RETENTION_DAYS} -delete
  log "清理完成"
}

# 增量备份 (关键表热备份)
incremental_backup() {
  local backup_file="$HOURLY_DIR/dev_db_${TIMESTAMP}.sql"
  log "开始增量备份: $backup_file"
  
  PGPASSWORD="$DB_PASS" pg_dump \
    -h "$DB_HOST" \
    -p "$DB_PORT" \
    -U "$DB_USER" \
    --data-only \
    --table='shared.*' \
    --table='dev_schema.*' \
    -f "$backup_file" \
    "$DB_NAME"
  
  local size=$(du -h "$backup_file" | cut -f1)
  log "增量备份完成: $size"
  
  # 清理 3 天前的增量备份
  find "$HOURLY_DIR" -name "*.sql" -mtime +3 -delete
}

# 验证备份
verify_backup() {
  local latest=$(ls -t "$DAILY_DIR"/*.dump 2>/dev/null | head -1)
  if [ -z "$latest" ]; then
    log "ERROR: 没有可用的备份文件进行验证"
    exit 1
  fi
  
  log "验证最新备份: $latest"
  PGPASSWORD="$DB_PASS" pg_restore -l "$latest" > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    log "备份验证通过"
  else
    log "ERROR: 备份验证失败!"
    exit 1
  fi
}

# 主逻辑
case "${1:-full}" in
  full)
    full_backup
    verify_backup
    ;;
  incremental)
    incremental_backup
    ;;
  verify)
    verify_backup
    ;;
  *)
    echo "用法: $0 [full|incremental|verify]"
    exit 1
    ;;
esac
