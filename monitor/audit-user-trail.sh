#!/bin/bash
# audit-user-trail.sh - 查询指定 Agent 的完整变更追溯
# 用法: ./audit-user-trail.sh <db_user> [时间范围]
# 示例: ./audit-user-trail.sh dev_user "24 hours"

set -euo pipefail

DB_USER="${1:?用法: $0 <db_user> [时间范围]}"
LOOKBACK="${2:-24 hours}"

echo "=== Agent 变更追溯报告 ==="
echo "目标用户: $DB_USER"
echo "时间范围: 最近 $LOOKBACK"
echo ""

docker exec openclaw-postgres psql -U postgres -d audit_db -c "
SELECT occurred_at AS 时间,
       operation AS 操作,
       table_name AS 表,
       changed_fields AS 变更字段,
       CASE WHEN operation = 'INSERT'
            THEN jsonb_pretty(new_data)
            WHEN operation = 'DELETE'
            THEN jsonb_pretty(old_data)
            ELSE NULL
       END AS 完整数据
FROM audit.log
WHERE db_user = '$DB_USER'
  AND occurred_at > NOW() - INTERVAL '$LOOKBACK'
ORDER BY occurred_at DESC;"

echo ""
echo "=== UPDATE 变更详情 ==="
docker exec openclaw-postgres psql -U postgres -d audit_db -c "
SELECT occurred_at AS 时间,
       table_name AS 表,
       changed_fields AS 变更字段,
       jsonb_pretty(old_data) AS 变更前,
       jsonb_pretty(new_data) AS 变更后
FROM audit.log
WHERE db_user = '$DB_USER'
  AND operation = 'UPDATE'
  AND occurred_at > NOW() - INTERVAL '$LOOKBACK'
ORDER BY occurred_at DESC;"
