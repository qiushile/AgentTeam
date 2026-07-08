# 慢查询日志分析机制

## 1. 概述

自动采集、分析和报告 PostgreSQL 慢查询，持续优化数据库性能。

## 2. 配置步骤

### 2.1 启用 pg_stat_statements 扩展
```sql
-- postgresql.conf
shared_preload_libraries = 'pg_stat_statements'

-- 在 dev_db 中创建扩展
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
GRANT EXECUTE ON FUNCTION pg_stat_statements_reset() TO dev_user;
GRANT SELECT ON pg_stat_statements TO dev_user;
```

### 2.2 启用慢查询日志
```sql
-- postgresql.conf
log_min_duration_statement = 1000    -- 记录 > 1s 的查询 (毫秒)
log_checkpoints = on
log_connections = on
log_disconnections = on
log_lock_waits = on
log_temp_files = 0                   -- 记录所有临时文件使用
log_autovacuum_min_duration = 0
```

### 2.3 日志格式
```
log_line_prefix = '%m [%p] %q%u@%d '
# 输出示例: 2026-07-08 14:30:00.123 CST [12345] dev_user@dev_db
```

## 3. 慢查询分析查询

### 3.1 Top 10 最慢查询 (按平均耗时)
```sql
SELECT 
  queryid,
  substring(query, 1, 200) as query_preview,
  calls,
  round(mean_exec_time::numeric, 2) as avg_ms,
  round(min_exec_time::numeric, 2) as min_ms,
  round(max_exec_time::numeric, 2) as max_ms,
  round(total_exec_time::numeric / 1000, 2) as total_sec,
  round(shared_blks_hit::numeric / nullif(calls, 0)) as avg_blocks_hit,
  round(shared_blks_read::numeric / nullif(calls, 0)) as avg_blocks_read
FROM pg_stat_statements
WHERE dbid = (SELECT oid FROM pg_database WHERE datname = 'dev_db')
ORDER BY mean_exec_time DESC
LIMIT 10;
```

### 3.2 Top 10 最耗总时间查询 (按累计耗时)
```sql
SELECT 
  queryid,
  substring(query, 1, 200) as query_preview,
  calls,
  round(mean_exec_time::numeric, 2) as avg_ms,
  round(total_exec_time::numeric / 1000, 2) as total_sec,
  round(100.0 * total_exec_time / (SELECT sum(total_exec_time) FROM pg_stat_statements WHERE dbid = (SELECT oid FROM pg_database WHERE datname = 'dev_db')), 2) as pct_of_total
FROM pg_stat_statements
WHERE dbid = (SELECT oid FROM pg_database WHERE datname = 'dev_db')
ORDER BY total_exec_time DESC
LIMIT 10;
```

### 3.3 低效查询 (高调用次数 + 低命中率)
```sql
SELECT 
  queryid,
  substring(query, 1, 200) as query_preview,
  calls,
  round(mean_exec_time::numeric, 2) as avg_ms,
  round(100.0 * shared_blks_hit / nullif(shared_blks_hit + shared_blks_read, 0), 2) as hit_pct
FROM pg_stat_statements
WHERE dbid = (SELECT oid FROM pg_database WHERE datname = 'dev_db')
  AND (shared_blks_hit + shared_blks_read) > 0
  AND 100.0 * shared_blks_hit / (shared_blks_hit + shared_blks_read) < 90
  AND calls > 100
ORDER BY calls DESC
LIMIT 10;
```

## 4. 自动化报告脚本

### 4.1 每日慢查询报告
```bash
#!/bin/bash
# slow_query_daily_report.sh

OUTPUT="/tmp/slow_query_report_$(date +%Y%m%d).txt"

psql -h 172.23.0.20 -U postgres -d dev_db -c "
SELECT 
  substring(query, 1, 150) as query,
  calls,
  round(mean_exec_time::numeric, 2) as avg_ms,
  round(total_exec_time::numeric / 1000, 2) as total_sec
FROM pg_stat_statements
WHERE dbid = (SELECT oid FROM pg_database WHERE datname = 'dev_db')
ORDER BY total_exec_time DESC
LIMIT 20;
" > $OUTPUT

echo "报告已生成: $OUTPUT"
```

### 4.2 异常检测
```sql
-- 对比当前与基线的慢查询变化
WITH baseline AS (
  SELECT queryid, mean_exec_time as baseline_ms
  FROM pg_stat_statements_history 
  WHERE snapshot_date = current_date - 1
),
current AS (
  SELECT queryid, mean_exec_time as current_ms
  FROM pg_stat_statements
  WHERE dbid = (SELECT oid FROM pg_database WHERE datname = 'dev_db')
)
SELECT 
  c.queryid,
  b.baseline_ms,
  c.current_ms,
  round(100.0 * (c.current_ms - b.baseline_ms) / nullif(b.baseline_ms, 0), 1) as change_pct
FROM current c
JOIN baseline b ON c.queryid = b.queryid
WHERE c.current_ms > b.baseline_ms * 2  -- 耗时翻倍
ORDER BY change_pct DESC;
```

## 5. 优化建议自动生成

根据查询特征推荐优化方案：

| 特征 | 推荐方案 |
|------|---------|
| 全表扫描 + 大表 | 添加 WHERE 条件索引 |
| 高 calls + 低 avg_ms | 考虑缓存或批量化 |
| 低 hit_pct | 检查索引是否有效 |
| 高 max_ms / avg_ms | 数据分布不均，分析执行计划 |
| 大量临时文件 | 增加 work_mem |

## 6. 告警规则

| 条件 | 级别 | 动作 |
|------|------|------|
| 单查询 > 10s | P1 | 飞书告警 + 记录日志 |
| 慢查询占比 > 15% | P1 | 飞书告警 |
| 同一查询 avg_ms 翻倍 | P2 | 飞书警告 |
| 临时文件使用 > 100MB | P2 | 飞书警告 |

---

> 创建时间: 2026-07-08
> 创建者: 研发部高级研发专家
> 状态: 待评审
