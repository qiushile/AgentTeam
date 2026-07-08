# 数据库连接池监控与告警方案

## 1. 概述

监控 PostgreSQL 连接池使用情况，预防连接耗尽导致的系统故障。

## 2. 连接池架构

### 2.1 当前状态
- **数据库**: PostgreSQL (172.23.0.20:5432)
- **应用**: 直连模式（无连接池中间件）
- **max_connections**: 默认 100

### 2.2 推荐架构：pgBouncer
```
应用服务器 → pgBouncer (端口 6432) → PostgreSQL (端口 5432)
```

**pgBouncer 模式选择**:
| 模式 | 说明 | 适用场景 |
|------|------|---------|
| session | 会话级复用 | 长连接应用 |
| transaction | 事务级复用 | 短事务应用（推荐） |
| statement | 语句级复用 | 无事务应用 |

## 3. 监控指标

### 3.1 PostgreSQL 层
```sql
-- 当前连接数
SELECT count(*) FROM pg_stat_activity WHERE datname = 'dev_db';

-- 连接数按状态分布
SELECT state, count(*) 
FROM pg_stat_activity 
WHERE datname = 'dev_db' 
GROUP BY state;

-- 空闲连接占比
SELECT 
  count(*) FILTER (WHERE state = 'idle') as idle,
  count(*) FILTER (WHERE state = 'active') as active,
  count(*) FILTER (WHERE state = 'idle in transaction') as idle_txn,
  count(*) as total,
  round(100.0 * count(*) FILTER (WHERE state = 'idle') / nullif(count(*),0), 1) as idle_pct
FROM pg_stat_activity 
WHERE datname = 'dev_db';

-- 最长运行查询
SELECT pid, now() - query_start as duration, query 
FROM pg_stat_activity 
WHERE state = 'active' AND datname = 'dev_db'
ORDER BY query_start ASC
LIMIT 5;

-- 锁等待
SELECT blocked.pid as blocked_pid, blocking.pid as blocking_pid
FROM pg_stat_activity blocked
JOIN pg_locks bl ON blocked.pid = bl.pid
JOIN pg_stat_activity blocking ON blocking.pid = (
  SELECT pid FROM pg_locks WHERE locktype = 'transactionid' AND granted = true
  AND relation = bl.relation
)
WHERE bl.granted = false AND blocked.datname = 'dev_db';
```

### 3.2 pgBouncer 层 (部署后)
```sql
-- pgBouncer 管理库查询
SHOW pools;          -- 连接池状态
SHOW clients;        -- 客户端连接
SHOW servers;        -- 服务端连接
SHOW stats;          -- 统计数据
SHOW lists;          -- 队列统计
```

## 4. 告警阈值

| 指标 | Warning | Critical | 说明 |
|------|---------|----------|------|
| 连接使用率 | > 60% | > 80% | 当前连接数 / max_connections |
| 空闲连接占比 | > 50% | > 70% | 可能存在连接泄漏 |
| idle in transaction | > 5 | > 10 | 长事务阻塞 |
| 锁等待超时 | > 10s | > 30s | 死锁风险 |
| 慢查询比例 | > 5% | > 15% | 查询性能下降 |
| pgBouncer 等待队列 | > 10 | > 50 | 连接池耗尽 |

## 5. 实施脚本

### 5.1 连接数检查脚本
```bash
#!/bin/bash
# check_connections.sh

PG_HOST="172.23.0.20"
PG_PORT="5432"
PG_DB="dev_db"
PG_USER="postgres"

MAX_CONN=100
CURRENT_CONN=$(psql -h $PG_HOST -p $PG_PORT -U $PG_USER -d $PG_DB -t -c \
  "SELECT count(*) FROM pg_stat_activity WHERE datname = '$PG_DB';")

IDLE_CONN=$(psql -h $PG_HOST -p $PG_PORT -U $PG_USER -d $PG_DB -t -c \
  "SELECT count(*) FROM pg_stat_activity WHERE datname = '$PG_DB' AND state = 'idle';")

USAGE_PCT=$((CURRENT_CONN * 100 / MAX_CONN))

echo "$(date) | Connections: $CURRENT_CONN/$MAX_CONN (${USAGE_PCT}%) | Idle: $IDLE_CONN"

if [ $USAGE_PCT -gt 80 ]; then
  echo "CRITICAL: Connection usage ${USAGE_PCT}%"
  # 发送飞书告警
elif [ $USAGE_PCT -gt 60 ]; then
  echo "WARNING: Connection usage ${USAGE_PCT}%"
fi
```

### 5.2 慢查询报告脚本
```bash
#!/bin/bash
# slow_query_report.sh

psql -h 172.23.0.20 -U postgres -d dev_db -c "
SELECT 
  query,
  calls,
  round(mean_exec_time::numeric, 2) as mean_ms,
  round(total_exec_time::numeric / 1000, 2) as total_sec,
  round(100.0 * total_exec_time / (SELECT sum(total_exec_time) FROM pg_stat_statements), 2) as pct_total
FROM pg_stat_statements
WHERE dbid = (SELECT oid FROM pg_database WHERE datname = 'dev_db')
ORDER BY mean_exec_time DESC
LIMIT 10;
"
```

## 6. pgBouncer 配置 (待部署)

```ini
# /etc/pgbouncer/pgbouncer.ini
[databases]
dev_db = host=172.23.0.20 port=5432 dbname=dev_db

[pgbouncer]
listen_port = 6432
listen_addr = *
auth_type = md5
auth_file = /etc/pgbouncer/userlist.txt
pool_mode = transaction
max_client_conn = 200
default_pool_size = 20
min_pool_size = 5
reserve_pool_size = 5
reserve_pool_timeout = 3
server_lifetime = 3600
server_idle_timeout = 600
log_connections = 1
log_disconnections = 1
log_pooler_errors = 1
```

## 7. Grafana Dashboard

推荐面板：
1. **连接数趋势** - 实时/历史连接数曲线
2. **连接状态分布** - 饼图 (active/idle/idle in txn)
3. **慢查询 Top 10** - 表格 (查询文本 + 平均耗时)
4. **锁等待告警** - 实时状态面板
5. **连接使用率** - 仪表盘 (60%/80% 阈值线)

---

> 创建时间: 2026-07-08
> 创建者: 研发部高级研发专家
> 状态: 待评审
