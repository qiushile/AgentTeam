# 监控告警体系设计方案

## 1. 概述

构建研发部全方位监控体系，覆盖数据库、应用、基础设施三层。

## 2. 监控层级

### 2.1 数据库层 (PostgreSQL)
| 指标 | 采集方式 | 告警阈值 |
|------|---------|---------|
| 连接数 | `pg_stat_activity` | > 80% max_connections |
| 慢查询 | `pg_stat_statements` | > 1s 查询占比 > 5% |
| 锁等待 | `pg_locks` | 等待 > 30s |
| 缓存命中率 | `pg_stat_database` | < 95% |
| 磁盘使用 | `pg_database_size` | > 80% |
| 复制延迟 | `pg_stat_replication` | > 10s |

### 2.2 应用层
| 指标 | 采集方式 | 告警阈值 |
|------|---------|---------|
| 请求延迟 (P99) | APM 探针 | > 2s |
| 错误率 | APM / 日志 | > 1% |
| QPS | APM | < 正常基线 50% |
| 内存使用 | Node.js process | > 80% heap |
| CPU 使用 | OS 指标 | > 80% 持续 5min |

### 2.3 基础设施层
| 指标 | 采集方式 | 告警阈值 |
|------|---------|---------|
| 磁盘空间 | Node exporter | < 20% |
| 内存使用 | Node exporter | > 90% |
| 网络 IO | Node exporter | 异常波动 > 200% |
| Docker 容器状态 | Docker exporter | 容器退出/重启 |

## 3. 技术栈选型

### 3.1 推荐方案
```
Prometheus (指标采集) ──→ Grafana (可视化)
        │
        ├── Node Exporter (系统指标)
        ├── Postgres Exporter (数据库指标)
        └── Application (自定义指标)

Alertmanager ──→ 飞书 Webhook (告警通知)
```

### 3.2 轻量方案 (适合小型团队)
```
pgwatch2 (PostgreSQL 专用监控)
        │
        └── 内置 Grafana Dashboards + Alerting
```

## 4. 告警分级

| 级别 | 定义 | 响应时间 | 通知渠道 |
|------|------|---------|---------|
| P0 - 致命 | 服务完全不可用 | 5 分钟 | 飞书 + 短信 + 电话 |
| P1 - 严重 | 核心功能受损 | 15 分钟 | 飞书 + 短信 |
| P2 - 警告 | 性能下降/非核心功能异常 | 1 小时 | 飞书 |
| P3 - 信息 | 趋势预警/容量规划 | 当日处理 | 飞书频道 |

## 5. Prometheus 告警规则

```yaml
groups:
  - name: postgres_alerts
    rules:
      - alert: PostgreSQLHighConnections
        expr: pg_stat_activity_count / pg_settings_max_connections * 100 > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "PostgreSQL 连接数过高 ({{ $value }}%)"
      
      - alert: PostgreSQLSlowQueries
        expr: rate(pg_stat_statements_mean_exec_time_seconds{exec_time>1}[5m]) > 0.05
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "PostgreSQL 慢查询比例过高"
      
      - alert: PostgreSQLReplicationLag
        expr: pg_replication_lag_seconds > 10
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "PostgreSQL 复制延迟 {{ $value }}s"
      
      - alert: PostgreSQLCacheHitRatioLow
        expr: pg_stat_database_blks_hit / (pg_stat_database_blks_hit + pg_stat_database_blks_read) < 0.95
        for: 15m
        labels:
          severity: warning
        annotations:
          summary: "PostgreSQL 缓存命中率低 ({{ $value }})"

  - name: system_alerts
    rules:
      - alert: DiskSpaceLow
        expr: node_filesystem_avail_bytes / node_filesystem_size_bytes < 0.2
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "磁盘空间不足 ({{ $value | humanizePercentage }} 剩余)"
      
      - alert: HighMemoryUsage
        expr: node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes < 0.1
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "内存使用率过高 ({{ $value | humanizePercentage }} 可用)"
```

## 6. 飞书告警集成

```python
# alertmanager 飞书 Webhook 配置
receivers:
  - name: 'feishu'
    webhook_configs:
      - url: 'https://open.feishu.cn/open-apis/bot/v2/hook/<token>'
        send_resolved: true

route:
  receiver: 'feishu'
  group_by: ['alertname', 'severity']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
```

## 7. 日志采集方案

### 7.1 技术栈
```
应用日志 → Filebeat/Fluentd → Elasticsearch → Kibana (展示)
数据库日志 → pgAudit → Filebeat → Elasticsearch
```

### 7.2 日志规范
```json
{
  "timestamp": "2026-07-08T14:30:00Z",
  "level": "ERROR",
  "service": "dev-api",
  "message": "Database query timeout",
  "request_id": "abc-123",
  "user_id": "user_456",
  "duration_ms": 30000
}
```

## 8. Dashboard 规划

| Dashboard | 用途 | 关键指标 |
|-----------|------|---------|
| PostgreSQL Overview | 数据库健康 | 连接数、QPS、缓存命中、锁等待 |
| Application Performance | 应用性能 | 延迟、错误率、吞吐量 |
| Infrastructure | 基础设施 | CPU、内存、磁盘、网络 |
| Business Metrics | 业务指标 | 任务完成率、协作事件量 |

---

> 创建时间: 2026-07-08
> 创建者: 研发部高级研发专家
> 状态: 待评审
