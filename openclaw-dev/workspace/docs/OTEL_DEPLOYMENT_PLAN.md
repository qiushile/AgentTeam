# Phase 3.1 OpenTelemetry 部署计划

> 制定日期: 2026-08-25  
> 制定者: 研发部高级研发专家 (dev_user)  
> 状态: 📝 待执行

---

## 一、部署架构

```
┌─────────────┐    OTLP    ┌──────────────────────┐    OTLP    ┌──────────────┐
│  应用服务    │ ─────────▶ │                      │ ─────────▶ │   Grafana    │
│  (Node.js)  │            │  OpenTelemetry       │            │   Tempo      │
├─────────────┤    OTLP    │  Collector           │            │  (Backend)   │
│  Node.js    │ ─────────▶ │  (Sidecar)           ├──────────▶ └──────────────┘
│  脚本       │            │                      │
├─────────────┤            │                      │    OTLP    ┌──────────────┐
│  PostgreSQL │ ─────────▶ │                      │ ─────────▶ │  Prometheus  │
│  日志       │            │                      │            │  (Metrics)   │
└─────────────┘            └──────────────────────┘            └──────────────┘
```

## 二、部署步骤

### Step 1: 部署 OpenTelemetry Collector

```yaml
# docker-compose/otel-collector.yml
version: '3.8'

services:
  otel-collector:
    image: otel/opentelemetry-collector-contrib:0.107.0
    ports:
      - "4317:4317"   # OTLP gRPC
      - "4318:4318"   # OTLP HTTP
      - "8888:8888"   # Prometheus metrics
      - "8889:8889"   # Prometheus exporter
    volumes:
      - ./otel-collector-config.yml:/etc/otelcol-contrib/config.yaml
    restart: unless-stopped
    networks:
      - openclaw_default
```

### Step 2: Collector 配置

```yaml
# otel-collector-config.yml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:
    timeout: 10s
    send_batch_size: 1024
  memory_limiter:
    limit_mib: 512
    check_interval: 5s
  attributes:
    actions:
      - key: deployment.environment
        value: production
        action: upsert
      - key: service.namespace
        value: dev
        action: upsert

exporters:
  otlp/tempo:
    endpoint: tempo:4317
    tls:
      insecure: true
  prometheus:
    endpoint: 0.0.0.0:8889

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch, attributes]
      exporters: [otlp/tempo]
    metrics:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [prometheus]
```

### Step 3: Grafana Tempo 部署

```yaml
# docker-compose/tempo.yml
version: '3.8'

services:
  tempo:
    image: grafana/tempo:2.5.0
    ports:
      - "3200:3200"   # Tempo API
      - "4317:4317"   # OTLP gRPC (用于接收 traces)
    volumes:
      - ./tempo-config.yml:/etc/tempo-config.yml
      - tempo-data:/tmp/tempo
    command: -config.file=/etc/tempo-config.yml
    restart: unless-stopped
    networks:
      - openclaw_default

volumes:
  tempo-data:
```

```yaml
# tempo-config.yml
server:
  http_listen_port: 3200

distributor:
  receivers:
    otlp:
      protocols:
        grpc:
          endpoint: "0.0.0.0:4317"

storage:
  trace:
    backend: local
    local:
      path: /tmp/tempo/blocks

compactor:
  compaction:
    block_retention: 48h
```

### Step 4: Node.js 应用插桩

```javascript
// tracing.js
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-http');
const { Resource } = require('@opentelemetry/resources');
const { SEMRESATTRS_SERVICE_NAME, SEMRESATTRS_SERVICE_VERSION } = require('@opentelemetry/semantic-conventions');

const sdk = new NodeSDK({
  resource: new Resource({
    [SEMRESATTRS_SERVICE_NAME]: 'dev-workspace',
    [SEMRESATTRS_SERVICE_VERSION]: '1.0.0',
    'deployment.environment': 'production',
    'service.namespace': 'dev',
  }),
  traceExporter: new OTLPTraceExporter({
    url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://otel-collector:4318/v1/traces',
  }),
  instrumentations: [
    getNodeAutoInstrumentations({
      '@opentelemetry/instrumentation-http': { ignoreIncomingPaths: ['/health'] },
      '@opentelemetry/instrumentation-pg': { requireParentSpan: true },
    }),
  ],
});

sdk.start();
```

### Step 5: 启动

```bash
# 1. 启动 Tempo
docker-compose -f docker-compose/tempo.yml up -d

# 2. 启动 Collector
docker-compose -f docker-compose/otel-collector.yml up -d

# 3. 启动应用 (加载 tracing)
node -r ./tracing.js app.js
```

### Step 6: 验证

```bash
# 检查 Collector 健康
curl -s http://localhost:4318/v1/traces

# 检查 Tempo 健康
curl -s http://localhost:3200/status

# 查看 Collector metrics
curl -s http://localhost:8888/metrics | head -20
```

## 三、验收标准

| 标准 | 验证方式 |
|---|---|
| Collector 正常运行 | `curl localhost:8888/metrics` 返回数据 |
| Tempo 接收 traces | Grafana 中可查看 Trace |
| Node.js 插桩生效 | `tracing.js` 加载后产生 spans |
| HTTP/DB spans | 查看 Trace 中是否有 HTTP 和 PG spans |
| SLO 可视化 | Grafana Dashboard 显示延迟/错误率 |

## 四、预计耗时

| 步骤 | 耗时 |
|---|---|
| Step 1-2: Collector 部署 | 1 天 |
| Step 3: Tempo 部署 | 1 天 |
| Step 4: Node.js 插桩 | 2 天 |
| Step 5-6: 验证 + Dashboard | 1 天 |
| **总计** | **5 天** |

---

> 最后更新: 2026-08-25  
> 状态: 📝 待执行
