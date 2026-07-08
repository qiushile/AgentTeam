# 日志集中化方案

## 1. 架构选型

### 1.1 轻量方案 (推荐小型团队)
```
应用/DB → Filebeat → Elasticsearch → Kibana
```

### 1.2 替代方案
- **Graylog**: 更简单的部署，内置告警
- **Loki + Grafana**: 云原生，轻量级

## 2. 日志规范

### 2.1 结构化日志格式 (JSON)
```json
{
  "timestamp": "2026-07-08T14:30:00.123Z",
  "level": "ERROR",
  "service": "dev-api",
  "message": "Database connection timeout",
  "request_id": "req-abc-123",
  "user_id": "user-456",
  "duration_ms": 30000,
  "stack_trace": "Error: ...",
  "metadata": {
    "db_host": "172.23.0.20",
    "query": "SELECT ..."
  }
}
```

### 2.2 日志级别规范
| 级别 | 用途 | 示例 |
|------|------|------|
| DEBUG | 调试信息 | 变量值、中间状态 |
| INFO | 正常操作 | 请求处理、任务完成 |
| WARN | 警告 | 性能下降、重试 |
| ERROR | 错误 | 异常、失败 |
| FATAL | 致命 | 服务崩溃 |

## 3. 采集配置

### 3.1 Filebeat 配置
```yaml
filebeat.inputs:
  - type: log
    enabled: true
    paths:
      - /var/log/app/*.json
      - /var/log/postgresql/*.log
    json.keys_under_root: true
    json.add_error_key: true
    json.message_key: message

  - type: filestream
    enabled: true
    paths:
      - /var/log/syslog

output.elasticsearch:
  hosts: ["http://elasticsearch:9200"]
  index: "dev-logs-%{+yyyy.MM.dd}"

logging.level: info
```

## 4. Kibana Dashboard

推荐面板：
1. **错误趋势** - 按级别分组的错误数时间线
2. **慢查询 Top N** - 来自 PostgreSQL 日志
3. **服务健康** - 各服务的 ERROR 率
4. **请求延迟分布** - P50/P95/P99

## 5. 告警规则

| 规则 | 条件 | 级别 |
|------|------|------|
| 错误率飙升 | 5 分钟内 ERROR > 10/min | P1 |
| 服务无日志 | 10 分钟无日志输出 | P0 |
| 磁盘空间 | 日志占用 > 80% | P2 |

---

> 创建时间: 2026-07-08
> 创建者: 研发部高级研发专家
> 状态: 待评审
