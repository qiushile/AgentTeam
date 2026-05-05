#!/bin/bash
# audit-monitor.sh - 审计数据库变更监控脚本
# 由 Sentinel 定期执行，检查团队成员的数据库变更

set -euo pipefail

DB_HOST="openclaw-postgres"
AUDIT_DB="audit_db"
PSQL="docker exec openclaw-postgres psql -U postgres"

# 默认查询最近 1 小时的变更
LOOKBACK="${1:-1 hour}"

echo "=== PostgreSQL 审计变更报告 ==="
echo "时间范围: 最近 $LOOKBACK"
echo "查询时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 统计概览
echo "--- 变更统计 ---"
$PSQL -d $AUDIT_DB -t -c "
SELECT '  总变更数: ' || COUNT(*) FROM audit.log WHERE occurred_at > NOW() - INTERVAL '$LOOKBACK';
SELECT '  INSERT 数: ' || COUNT(*) FROM audit.log WHERE occurred_at > NOW() - INTERVAL '$LOOKBACK' AND operation = 'INSERT';
SELECT '  UPDATE 数: ' || COUNT(*) FROM audit.log WHERE occurred_at > NOW() - INTERVAL '$LOOKBACK' AND operation = 'UPDATE';
SELECT '  DELETE 数: ' || COUNT(*) FROM audit.log WHERE occurred_at > NOW() - INTERVAL '$LOOKBACK' AND operation = 'DELETE';
"

echo ""
echo "--- 按用户统计 ---"
$PSQL -d $AUDIT_DB -c "
SELECT db_user AS 用户,
       COUNT(*) AS 变更数,
       COUNT(*) FILTER (WHERE operation='INSERT') AS 新增,
       COUNT(*) FILTER (WHERE operation='UPDATE') AS 修改,
       COUNT(*) FILTER (WHERE operation='DELETE') AS 删除
FROM audit.log
WHERE occurred_at > NOW() - INTERVAL '$LOOKBACK'
GROUP BY db_user
ORDER BY 变更数 DESC;"

echo ""
echo "--- 按表统计 ---"
$PSQL -d $AUDIT_DB -c "
SELECT table_name AS 表名,
       COUNT(*) AS 变更数,
       COUNT(*) FILTER (WHERE operation='INSERT') AS 新增,
       COUNT(*) FILTER (WHERE operation='UPDATE') AS 修改,
       COUNT(*) FILTER (WHERE operation='DELETE') AS 删除
FROM audit.log
WHERE occurred_at > NOW() - INTERVAL '$LOOKBACK'
GROUP BY table_name
ORDER BY 变更数 DESC;"

echo ""
echo "--- 最近 20 条变更明细 ---"
$PSQL -d $AUDIT_DB -c "
SELECT occurred_at AS 时间,
       db_user AS 用户,
       operation AS 操作,
       table_name AS 表,
       CASE
           WHEN operation = 'UPDATE' AND changed_fields IS NOT NULL
           THEN array_to_string(changed_fields, ', ')
           ELSE ''
       END AS 变更字段
FROM audit.log
WHERE occurred_at > NOW() - INTERVAL '$LOOKBACK'
ORDER BY occurred_at DESC
LIMIT 20;"

echo ""
echo "--- 审计表总大小 ---"
$PSQL -d $AUDIT_DB -t -c "
SELECT '  总记录数: ' || COUNT(*) FROM audit.log;
SELECT '  数据大小: ' || pg_size_pretty(pg_total_relation_size('audit.log'));
"
