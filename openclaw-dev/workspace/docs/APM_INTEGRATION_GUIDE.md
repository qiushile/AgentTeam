# 应用层 APM 集成指南 (Application Performance Monitoring)

## 一、选型对比

### OpenTelemetry (推荐)

| 维度 | 说明 |
|------|------|
| **类型** | 开源标准 (CNCF 项目) |
| **语言支持** | 全语言 (Java, Python, Node.js, Go, .NET 等) |
| **数据采集** | Traces, Metrics, Logs 三合一 |
| **生态** | 厂商无关，可对接 Jaeger, Zipkin, Prometheus, Datadog 等 |
| **成本** | 完全开源免费 |
| **社区** | CNCF 孵化项目，Google/Microsoft/AWS 等大厂支持 |

### Jaeger

| 维度 | 说明 |
|------|------|
| **类型** | 开源分布式追踪系统 (CNCF 毕业项目) |
| **定位** | 专注 Traces (调用链追踪) |
| **存储** | Elasticsearch, Cassandra, 内存 |
| **UI** | 内置 Web UI，支持依赖图、耗时分析 |
| **成本** | 完全开源免费 |
| **局限** | 不原生支持 Metrics 和 Logs |

### 对比结论

> **推荐方案**: OpenTelemetry (数据采集层) + Jaeger (可视化/存储层)
> - OpenTelemetry 作为统一 SDK 嵌入应用
> - Jaeger 作为后端存储和可视化
> - 后续可无缝切换其他后端 (Prometheus, Grafana Tempo, Datadog)

---

## 二、架构设计

```
┌─────────────────────────────────────────────────────┐
│                    Application Layer                 │
│  ┌──────────┐  ┌──────────┐  ┌────────────────────┐ │
│  │ Service A│  │ Service B│  │ Service C          │ │
│  │ (Node.js)│  │ (Python) │  │ (Java/Spring)      │ │
│  └────┬─────┘  └────┬─────┘  └────────┬───────────┘ │
│       │ OTel SDK     │ OTel SDK        │ OTel SDK    │
└───────┼──────────────┼─────────────────┼─────────────┘
        │              │                 │
        ▼              ▼                 ▼
┌─────────────────────────────────────────────────────┐
│              OpenTelemetry Collector                  │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────┐ │
│  │   Receiver   │→│  Processor   │→│   Exporter    │ │
│  │ (OTLP/HTTP)  │  │ (Batch/     │  │ (OTLP/Jaeger)│ │
│  │             │  │  Filter)    │  │              │ │
│  └─────────────┘  └─────────────┘  └──────┬───────┘ │
└────────────────────────────────────────────┼────────┘
                                             │
                    ┌────────────────────────┼────────┐
                    │        Backend         │         │
                    ▼                        ▼         │
              ┌──────────┐          ┌──────────────┐   │
              │  Jaeger  │          │  Prometheus  │   │
              │ (Traces) │          │  (Metrics)   │   │
              └──────────┘          └──────────────┘   │
                    │                        │         │
                    ▼                        ▼         │
              ┌──────────┐          ┌──────────────┐   │
              │ Grafana  │          │  AlertManager│   │
              │ (Dashboard)│         │  (Alerts)    │   │
              └──────────┘          └──────────────┘   │
                    └─────────────────────────────────┘
```

---

## 三、SLO/SLI 指标定义

### SLI (Service Level Indicators)

| SLI | 定义 | 采集方式 |
|-----|------|----------|
| **Availability** | 成功请求占比 | HTTP 状态码 (2xx/5xx) |
| **Latency** | p50/p95/p99 响应时间 | OTel Histogram |
| **Throughput** | 每秒请求数 (RPS) | OTel Counter |
| **Error Rate** | 错误请求占比 | OTel Counter (5xx) |
| **Saturation** | 资源利用率 | CPU/Memory/DB 连接池 |

### SLO (Service Level Objectives)

| 服务等级 | Availability | p99 Latency | Error Budget |
|---------|-------------|-------------|--------------|
| **Tier 0 (核心)** | 99.99% | < 200ms | 4.32 min/月 |
| **Tier 1 (重要)** | 99.9% | < 500ms | 43.2 min/月 |
| **Tier 2 (一般)** | 99.5% | < 1s | 3.65 h/月 |
| **Tier 3 (内部)** | 99% | < 2s | 7.3 h/月 |

---

## 四、实施步骤

### 4.1 OpenTelemetry Collector 部署

```yaml
# otel-collector-config.yaml
receivers:
  otlp:
    protocols:
      http:
        endpoint: 0.0.0.0:4318
      grpc:
        endpoint: 0.0.0.0:4317

processors:
  batch:
    timeout: 5s
    send_batch_size: 1000
  memory_limiter:
    limit_mib: 512
    check_interval: 5s

exporters:
  jaeger:
    endpoint: jaeger:14250
    tls:
      insecure: true
  prometheus:
    endpoint: 0.0.0.0:8889
    namespace: otel
  logging:
    loglevel: debug

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [jaeger, logging]
    metrics:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [prometheus, logging]
```

### 4.2 Node.js 服务集成

```javascript
// instrumentation.js
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-http');
const { OTLPMetricExporter } = require('@opentelemetry/exporter-metrics-otlp-http');
const { Resource } = require('@opentelemetry/resources');
const { SemanticResourceAttributes } = require('@opentelemetry/semantic-conventions');

const sdk = new NodeSDK({
  resource: new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: 'my-service',
    [SemanticResourceAttributes.SERVICE_VERSION]: '1.0.0',
  }),
  traceExporter: new OTLPTraceExporter({
    url: 'http://otel-collector:4318/v1/traces',
  }),
  metricExporter: new OTLPMetricExporter({
    url: 'http://otel-collector:4318/v1/metrics',
  }),
  instrumentations: [getNodeAutoInstrumentations()],
});

sdk.start();
```

```bash
# 启动时加载
node -r ./instrumentation.js app.js
```

### 4.3 Python 服务集成

```python
# instrumentation.py
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.flask import FlaskInstrumentation
from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentation
from opentelemetry.sdk.resources import Resource

resource = Resource.create({
    "service.name": "my-python-service",
    "service.version": "1.0.0",
})

trace.set_tracer_provider(TracerProvider(resource=resource))
span_processor = BatchSpanProcessor(OTLPSpanExporter(
    endpoint="http://otel-collector:4318/v1/traces"
))
trace.get_tracer_provider().add_span_processor(span_processor)

# Auto-instrument Flask + SQLAlchemy
FlaskInstrumentation().instrument()
SQLAlchemyInstrumentation().instrument()
```

```bash
opentelemetry-instrument python app.py
```

### 4.4 Jaeger 部署 (Docker Compose)

```yaml
# docker-compose.monitoring.yml
version: '3.8'
services:
  jaeger:
    image: jaegertracing/all-in-one:latest
    ports:
      - "16686:16686"   # UI
      - "14250:14250"   # gRPC
      - "14268:14268"   # HTTP
    environment:
      - COLLECTOR_OTLP_ENABLED=true
    deploy:
      resources:
        limits:
          memory: 512M

  otel-collector:
    image: otel/opentelemetry-collector-contrib:latest
    ports:
      - "4317:4317"   # OTLP gRPC
      - "4318:4318"   # OTLP HTTP
      - "8889:8889"   # Prometheus metrics
    volumes:
      - ./otel-collector-config.yaml:/etc/otelcol/config.yaml
    depends_on:
      - jaeger

  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana-data:/var/lib/grafana

volumes:
  grafana-data:
```

---

## 五、Grafana Dashboard 配置

### 关键面板

| 面板 | 指标 | 阈值告警 |
|------|------|----------|
| **请求延迟分布** | histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m])) | p99 > SLO |
| **错误率** | rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) | > 1% |
| **RPS** | rate(http_requests_total[5m]) | 突增/突降 |
| **服务依赖图** | Jaeger Service Graph | 新增/断裂依赖 |
| **Top 慢接口** | histogram_quantile(0.95, ...) | p95 > 500ms |
| **DB 查询延迟** | otel_db_query_duration_seconds | p99 > 100ms |

---

## 六、告警规则

```yaml
# alerting-rules.yml
groups:
  - name: slo-violations
    rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) > 0.01
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate on {{ $labels.service_name }}"
          description: "Error rate is {{ $value | humanizePercentage }} (threshold: 1%)"

      - alert: HighLatency
        expr: histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m])) > 0.5
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High p99 latency on {{ $labels.service_name }}"
          description: "p99 latency is {{ $value }}s (threshold: 500ms)"

      - alert: ServiceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Service {{ $labels.service_name }} is down"
```

---

## 七、成本估算

| 组件 | 小规模 (<10 服务) | 中规模 (10-50 服务) | 大规模 (>50 服务) |
|------|------------------|---------------------|-------------------|
| **OTel Collector** | 1 核 512MB | 2 核 1GB (×2) | 4 核 2GB (×3) |
| **Jaeger** | 1 核 512MB | 2 核 2GB | 4 核 4GB + ES 集群 |
| **Prometheus** | 1 核 1GB | 2 核 2GB | 4 核 4GB |
| **Grafana** | 0.5 核 256MB | 1 核 512MB | 2 核 1GB |
| **月度成本** | ~¥50/月 | ~¥200/月 | ~¥800/月 |

---

## 八、实施路线图

| 阶段 | 内容 | 周期 |
|------|------|------|
| **Phase 1** | OTel Collector 部署 + 1 个服务接入 | 1 周 |
| **Phase 2** | 全服务接入 + Jaeger 可视化 | 2 周 |
| **Phase 3** | Grafana Dashboard + 告警规则 | 1 周 |
| **Phase 4** | SLO 定义 + Error Budget 监控 | 1 周 |
| **Phase 5** | 自动化调优 + 文档完善 | 1 周 |

---

> 创建时间: 2026-07-27
> 创建者: 研发部高级研发专家
> 状态: 完成
