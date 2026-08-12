# OpenTelemetry 接入指南

## 概述

OpenTelemetry (OTel) 是 CNCF 可观测性标准，统一了 Traces、Metrics、Logs 的数据采集。本文档面向研发团队，提供从选型到接入现有服务的实操指南。

## 一、技术选型对比

### Tracing Backend

| 方案 | 优点 | 缺点 | 适用场景 |
|---|---|---|---|
| **Jaeger** | CNCF 毕业、轻量、内存存储可选 | 存储插件有限、大规模性能差 | 中小团队快速起步 |
| **Tempo (Grafana)** | 无索引架构、对象存储、与 Grafana 集成 | 功能相对简单 | 已有 Grafana 栈的团队 |
| **SkyWalking** | Java 生态强、自带 APM UI | 架构重、资源消耗大 | 以 Java 为主的传统企业 |
| **Honeycomb/Lightstep** | SaaS 免运维、分析能力强 | 成本高、数据出境 | 预算充足的商业化场景 |

**推荐**：Grafana Tempo + OpenTelemetry Collector + Jaeger UI（兼容查询），轻量且与现有 Grafana 监控栈无缝集成。

### SDK 选型

| 语言 | SDK | 自动插桩能力 |
|---|---|---|
| Node.js | `@opentelemetry/sdk-node` | Express/Fastify/HTTP/PG 自动埋点 |
| Python | `opentelemetry-distro` | Flask/Django/Requests/SQLAlchemy 自动埋点 |
| Java | `opentelemetry-java-instrumentation` | Spring/Tomcat/JDBC 零代码接入 |
| Go | `go.opentelemetry.io/otel` | 需手动埋点（生态较新） |

## 二、架构设计

```
┌──────────────┐    OTLP    ┌──────────────────────┐    OTLP    ┌──────────────┐
│  应用服务 A   │ ─────────▶ │                      │ ─────────▶ │   Grafana    │
│  (Node.js)   │            │  OpenTelemetry       │            │   Tempo      │
├──────────────┤    OTLP    │  Collector           ├──────────▶ │   (Backend)  │
│  应用服务 B   │ ─────────▶ │  (DaemonSet / Sidecar)│            └──────────────┘
│  (Python)    │            │                      │
├──────────────┤            │                      │    OTLP    ┌──────────────┐
│  应用服务 C   │ ─────────▶ │                      │ ─────────▶ │  Prometheus  │
│  (Java)      │            │                      │            │  (Metrics)   │
└──────────────┘            └──────────────────────┘            └──────────────┘
```

**部署模式选择**：
- **Sidecar 模式**：每个 Pod 一个 Collector 容器，适合 Kubernetes 环境
- **DaemonSet 模式**：每个节点一个 Collector，资源更省
- **Gateway 模式**：集中式 Collector，适合非容器化部署

**推荐**：K8s 环境下使用 DaemonSet + Gateway 双层架构。

## 三、快速接入

### 3.1 Node.js 服务接入

```bash
npm install @opentelemetry/api @opentelemetry/sdk-node \
  @opentelemetry/auto-instrumentations-node \
  @opentelemetry/exporter-trace-otlp-http \
  @opentelemetry/exporter-metrics-otlp-http
```

```javascript
// tracing.js — 在应用入口第一行加载
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-http');
const { Resource } = require('@opentelemetry/resources');
const { SemanticResourceAttributes } = require('@opentelemetry/semantic-conventions');

const sdk = new NodeSDK({
  resource: new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: 'user-service',
    [SemanticResourceAttributes.SERVICE_VERSION]: '1.0.0',
    'deployment.environment': process.env.NODE_ENV || 'development',
  }),
  traceExporter: new OTLPTraceExporter({
    url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://otel-collector:4318/v1/traces',
  }),
  instrumentations: [
    getNodeAutoInstrumentations({
      '@opentelemetry/instrumentation-http': { ignoreIncomingPaths: ['/health'] },
      '@opentelemetry/instrumentation-express': { requestHook: true },
      '@opentelemetry/instrumentation-pg': { requireParentSpan: true },
    }),
  ],
});

sdk.start();
```

启动方式：`node -r ./tracing.js app.js`

### 3.2 Python 服务接入

```bash
pip install opentelemetry-distro opentelemetry-exporter-otlp \
  opentelemetry-instrumentation-flask opentelemetry-instrumentation-psycopg2
```

```bash
# 零代码方式启动
export OTEL_SERVICE_NAME="order-service"
export OTEL_EXPORTER_OTLP_ENDPOINT="http://otel-collector:4318"
opentelemetry-instrument --traces_exporter otlp --metrics_exporter otlp \
  flask run --host=0.0.0.0
```

### 3.3 Java 服务接入（零代码）

```bash
# 下载 Java Agent
curl -LO https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/latest/download/opentelemetry-javaagent.jar

# 启动时附加
java -javaagent:opentelemetry-javaagent.jar \
  -Dotel.service.name=payment-service \
  -Dotel.exporter.otlp.endpoint=http://otel-collector:4318 \
  -jar app.jar
```

## 四、Collector 配置

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
    timeout: 10s
    send_batch_size: 1024
  memory_limiter:
    limit_mib: 512
    check_interval: 5s
  attributes:
    actions:
      - key: deployment.environment
        from_attribute: env
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

## 五、SLO/SLI 指标定义

### 5.1 核心 SLI

| 指标 | 计算方式 | 目标 |
|---|---|---|
| **可用性** | 成功请求数 / 总请求数 | ≥ 99.9% |
| **延迟** | P99 响应时间 | < 500ms (API) |
| **吞吐量** | 每分钟请求数 | 满足业务峰值 × 1.5 |
| **错误率** | 5xx 响应数 / 总请求数 | < 0.1% |

### 5.2 SLO 查询示例（PromQL）

```promql
# 可用性 SLO — 30 天窗口
sum(rate(http_requests_total{status=~"2.."}[30d]))
/
sum(rate(http_requests_total[30d]))

# 延迟 SLO — P99 响应时间
histogram_quantile(0.99,
  sum(rate(http_request_duration_seconds_bucket{service="user-service"}[5m]))
  by (le))

# 错误预算消耗
1 - (
  sum(rate(http_requests_total{status=~"5.."}[7d]))
  /
  sum(rate(http_requests_total[7d]))
) / (1 - 0.999)
```

### 5.3 告警规则

```yaml
groups:
  - name: slo-alerts
    rules:
      - alert: HighErrorRate
        expr: |
          sum(rate(http_requests_total{status=~"5.."}[5m]))
          / sum(rate(http_requests_total[5m])) > 0.01
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "服务 {{ $labels.service }} 错误率 > 1%"

      - alert: HighLatency
        expr: |
          histogram_quantile(0.99,
            sum(rate(http_request_duration_seconds_bucket[5m])) by (le))
          > 0.5
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "P99 延迟 > 500ms"
```

## 六、最佳实践

1. **采样策略**：开发环境 100%，生产环境 10% 头部采样 + 100% 错误采样
2. **Span 命名**：遵循 `HTTP_METHOD /route` 格式，避免高基数标签
3. **Propagation**：统一使用 W3C Trace Context (traceparent header)
4. **日志关联**：通过 `trace_id` 和 `span_id` 关联 OTel Traces 与结构化日志
5. **资源消耗**：Collector 内存限制 512MB，Batch Processor 防止突发
6. **版本控制**：SDK 和 Collector 版本保持同步，定期升级

## 七、接入清单

- [ ] 部署 OpenTelemetry Collector (DaemonSet)
- [ ] 部署 Grafana Tempo (Trace Backend)
- [ ] Node.js 服务加载 `tracing.js`
- [ ] Python 服务使用 `opentelemetry-instrument` 启动
- [ ] Java 服务附加 `-javaagent`
- [ ] 配置 Prometheus 抓取 Collector metrics
- [ ] 定义 Grafana Dashboard (Traces + SLO)
- [ ] 配置告警规则 (P0/P1/P2)
- [ ] 编写接入文档与团队培训

---

> 创建日期: 2026-08-12
> 作者: 研发部高级研发专家
> 状态: 初稿完成
> 相关: APM_INTEGRATION_GUIDE.md, MONITORING_ALERTING_STRATEGY.md
