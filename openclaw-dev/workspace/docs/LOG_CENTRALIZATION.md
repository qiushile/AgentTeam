# 日志集中化方案

## 1. 架构选型

### 1.1 轻量方案 (推荐小型团队): Loki + Grafana ✅
```
应用/DB → Promtail → Loki → Grafana
```

**优势**: 与现有 Grafana 监控栈无缝集成，资源消耗仅为 ELK 的 1/10。

### 1.2 备选方案
| 方案 | 优点 | 缺点 | 适用场景 |
|------|------|------|---------|
| **Loki + Grafana** | 轻量、与 Grafana 集成、标签查询 | 全文检索能力有限 | 小型团队、已有 Grafana |
| ELK | 功能全面、全文检索强大 | 资源消耗大 (ES 内存需求高) | 中大型团队、复杂检索需求 |
| Graylog | 部署简单、内置告警 | 社区版功能有限 | 快速部署需求 |

### 1.3 部署架构 (Loki)

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  应用容器    │────▶│  Promtail   │────▶│    Loki     │────▶│   Grafana   │
│  (Node.js)  │     │  (日志采集)  │     │  (日志存储)  │     │  (查询展示)  │
├─────────────┤     └─────────────┘     └─────────────┘     └─────────────┘
│  PostgreSQL │────▶│  Promtail   │
│  日志       │     │  (日志采集)  │
└─────────────┘     └─────────────┘
```

### 1.4 Docker Compose 配置

```yaml
# docker-compose.logging.yml
version: '3.8'

services:
  loki:
    image: grafana/loki:2.9
    ports:
      - "3100:3100"
    volumes:
      - ./loki-config.yml:/etc/loki/local-config.yaml
      - loki-data:/loki
    command: -config.file=/etc/loki/local-config.yaml

  promtail:
    image: grafana/promtail:2.9
    volumes:
      - ./promtail-config.yml:/etc/promtail/config.yml
      - /var/log:/var/log
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
    command: -config.file=/etc/promtail/config.yml

volumes:
  loki-data:
```

```yaml
# loki-config.yml
auth_enabled: false

server:
  http_listen_port: 3100

common:
  path_prefix: /loki
  replication_factor: 1
  storage:
    filesystem:
      chunks_directory: /loki/chunks
      rules_directory: /loki/rules

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

limits_config:
  reject_old_samples: true
  reject_old_samples_max_age: 168h
```

```yaml
# promtail-config.yml
server:
  http_listen_port: 9080

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: app-logs
    static_configs:
      - targets:
          - localhost
        labels:
          job: dev-api
          __path__: /var/log/app/*.log

  - job_name: docker-logs
    docker_sd_configs:
      - host: unix:///var/run/docker.sock
        refresh_interval: 5s
    relabel_configs:
      - source_labels: ['__meta_docker_container_name']
        target_label: 'container'
      - source_labels: ['__meta_docker_container_log_stream']
        target_label: 'stream'

  - job_name: postgres-logs
    static_configs:
      - targets:
          - localhost
        labels:
          job: postgresql
          __path__: /var/log/postgresql/*.log
```

## 2. 日志规范

### 2.1 结构化日志格式 (JSON)
```json
{
  "timestamp": "2026-08-24T14:30:00.123Z",
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

### 2.3 Loki 标签最佳实践

**推荐标签**:
- `job`: 服务名称 (dev-api, postgresql)
- `container`: 容器名称
- `stream`: stdout/stderr
- `level`: 日志级别

**避免高基数标签**:
- ❌ `user_id` (每个用户一个值)
- ❌ `request_id` (每个请求一个值)
- ✅ 将这些放在日志内容中，不作为标签

## 3. Grafana 日志面板配置

### 3.1 推荐 Dashboard

1. **错误趋势** - LogQL: `{job="dev-api", level="ERROR"} |= ""`
2. **慢查询 Top N** - LogQL: `{job="postgresql"} |= "duration" | json | duration_ms > 1000`
3. **服务健康** - LogQL: `rate({job="dev-api", level="ERROR"}[5m])`
4. **日志流分布** - 按 container/stream 分组

### 3.2 Grafana 数据源配置

```yaml
# Grafana provisioning (datasources/loki.yml)
apiVersion: 1
datasources:
  - name: Loki
    type: loki
    access: proxy
    url: http://loki:3100
    isDefault: false
    jsonData:
      maxLines: 1000
```

## 4. 告警规则

| 规则 | LogQL 条件 | 级别 |
|------|-----------|------|
| 错误率飙升 | `rate({job="dev-api", level="ERROR"}[5m]) > 10` | P1 |
| 服务无日志 | `absent({job="dev-api"})` 持续 10 分钟 | P0 |
| 磁盘空间 | 日志文件 > 1GB | P2 |
| DB 连接失败 | `{job="dev-api"} |= "ECONNREFUSED"` | P0 |

## 5. ELK 方案 (保留参考)

> 如果需要全文检索能力，可迁移至 ELK。以下为 Filebeat 配置参考。

### 5.1 Filebeat 配置
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

output.elasticsearch:
  hosts: ["http://elasticsearch:9200"]
  index: "dev-logs-%{+yyyy.MM.dd}"

logging.level: info
```

---

> 创建时间: 2026-07-08  
> 最后更新: 2026-08-24  
> 创建者: 研发部高级研发专家  
> 变更: 补充 Loki + Grafana 完整方案，添加 Docker Compose 配置和 LogQL 示例
