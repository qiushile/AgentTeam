# APM 选型与接入报告

> 日期: 2026-09-06
> 作者: 研发部高级研发专家 (dev_user)
> 状态: ✅ 已完成

---

## 一、选型对比：OpenTelemetry vs Jaeger vs SkyWalking

### 1.1 核心定位

| 维度 | OpenTelemetry | Jaeger | SkyWalking |
|------|--------------|--------|------------|
| **定位** | 数据采集标准 (SDK + Collector) | 分布式追踪后端 | 全栈 APM 平台 |
| **CNCF 状态** | 孵化项目 | **毕业项目** | 毕业项目 |
| **数据采集** | Traces + Metrics + Logs | 仅 Traces | Traces + Metrics + Logs |
| **语言 SDK** | 全语言 (官方维护) | 无 (依赖 OTel 或其他 SDK) | Java 最强，其他语言覆盖有限 |
| **存储后端** | 无 (Collector 导出数据) | ES/Cassandra/内存 | ES/H2/MySQL/TiDB |
| **可视化** | 无 (对接 Grafana 等) | 内置 Web UI | 内置 Dashboard + 拓扑图 |
| **侵入性** | 低 (auto-instrumentation) | 无 (纯后端) | 中 (Java Agent 零侵入，其他需 SDK) |
| **运维复杂度** | 中 (需额外后端) | 低 (all-in-one) | 中 (OAP Server + UI + 存储) |
| **社区活跃度** | ⭐⭐⭐⭐⭐ (CNCF + 大厂支持) | ⭐⭐⭐⭐ (稳定维护) | ⭐⭐⭐⭐ (Apache 社区) |

### 1.2 适用场景分析

| 场景 | 推荐方案 | 理由 |
|------|---------|------|
| **小型团队 (<5 人)，快速上手** | SkyWalking | 全栈开箱即用，Java Agent 零侵入 |
| **多语言团队，长期标准** | **OpenTelemetry + Jaeger** | ✅ 厂商无关，CNCF 标准，未来可替换后端 |
| **仅需要 Traces** | Jaeger | 专注分布式追踪，轻量 |
| **Java 为主的技术栈** | SkyWalking | Java Agent 自动插桩最成熟 |
| **需要统一 Metrics + Traces + Logs** | OpenTelemetry | 唯一标准三合一方案 |

### 1.3 最终选型

> **推荐方案：OpenTelemetry (数据采集层) + Jaeger/Tempo (可视化后端) + Prometheus (Metrics) + Grafana (Dashboard)**
>
> **理由**:
> 1. OpenTelemetry 是 CNCF 标准，避免厂商锁定
> 2. 团队技术栈以 Node.js 为主，OTel auto-instrumentation 覆盖完善
> 3. 后续可无缝切换后端 (Jaeger → Tempo → Datadog)
> 4. Grafana + Prometheus 已有文档基础 (MONITORING_ALERTING_STRATEGY.md)
> 5. SkyWalking 对 Node.js 支持较弱，不推荐

---

## 二、SLO/SLI 指标定义

### 2.1 SLI (Service Level Indicators)

| SLI | 定义 | OTel 采集方式 | 聚合粒度 |
|-----|------|-------------|---------|
| **Availability** | 成功请求数 / 总请求数 | Counter (2xx vs 5xx) | 5 min |
| **Latency** | p50 / p95 / p99 响应时间 | Histogram | 5 min |
| **Throughput** | 每秒请求数 (RPS) | Counter (rate) | 1 min |
| **Error Rate** | 错误请求占比 | Counter (status 5xx) | 5 min |
| **DB Latency** | p95 数据库查询耗时 | Histogram (db.client.duration) | 5 min |
| **Saturation** | CPU / 内存 / DB 连接池利用率 | Gauge | 1 min |

### 2.2 SLO (Service Level Objectives)

| 服务等级 | Availability | p99 Latency | Error Budget | 示例 |
|---------|-------------|-------------|--------------|------|
| **Tier 0 (核心)** | 99.99% | < 200ms | 4.32 min/月 | 飞书消息路由、数据库写入 |
| **Tier 1 (重要)** | 99.9% | < 500ms | 43.2 min/月 | 任务查询、API 网关 |
| **Tier 2 (一般)** | 99.5% | < 1s | 3.65 h/月 | 文档生成、报告导出 |
| **Tier 3 (内部)** | 99.0% | < 2s | 7.3 h/月 | 后台巡检、数据清理 |

### 2.3 Error Budget 监控

```promql
# 剩余 Error Budget 百分比
(1 - (
  sum(rate(http_requests_total{status=~"5.."}[30d]))
  /
  sum(rate(http_requests_total[30d]))
)) / (1 - 0.999) * 100
# > 100% = 预算充足, < 100% = 预算耗尽
```

---

## 三、接入方案

### 3.1 架构

```
┌──────────────────────────────────────────────────────┐
│                  Node.js 应用                         │
│  ┌────────────────────────────────────────────────┐  │
│  │  @opentelemetry/sdk-node                       │  │
│  │  ├── auto-instrumentations-node (HTTP, PG, FS) │  │
│  │  └── exporter-trace-otlp-http                  │  │
│  └────────────────────┬───────────────────────────┘  │
└───────────────────────┼──────────────────────────────┘
                        │ OTLP (HTTP/gRPC)
                        ▼
┌──────────────────────────────────────────────────────┐
│              OpenTelemetry Collector                   │
│  Receiver (OTLP) → Processor (Batch) → Exporter       │
└───────┬──────────────────────┬────────────────────────┘
        │                      │
        ▼                      ▼
┌───────────────┐    ┌─────────────────┐
│   Jaeger      │    │   Prometheus    │
│   (Traces)    │    │   (Metrics)     │
└───────┬───────┘    └────────┬────────┘
        │                     │
        ▼                     ▼
┌─────────────────────────────────┐
│         Grafana Dashboard       │
│  ├── Traces (Jaeger datasource) │
│  ├── Metrics (Prometheus)       │
│  ├── SLO/Error Budget           │
│  └── 告警 (AlertManager)        │
└─────────────────────────────────┘
```

### 3.2 部署清单

| 组件 | 镜像 | 端口 | 资源 |
|------|------|------|------|
| OTel Collector | `otel/opentelemetry-collector-contrib:0.107.0` | 4317(gRPC), 4318(HTTP), 8889 | 1C/512M |
| Jaeger | `jaegertracing/all-in-one:latest` | 16686(UI), 14250(gRPC) | 1C/512M |
| Prometheus | `prom/prometheus:latest` | 9090 | 1C/1G |
| Grafana | `grafana/grafana:latest` | 3000 | 0.5C/256M |

### 3.3 Node.js 接入代码

详见 `docs/APM_INTEGRATION_GUIDE.md` 和 `docs/OTEL_DEPLOYMENT_PLAN.md`。

---

## 四、验收标准

| # | 验收项 | 验证方式 |
|---|--------|---------|
| 1 | OTel Collector 正常运行 | `curl localhost:8888/metrics` 返回数据 |
| 2 | Jaeger 接收 traces | Jaeger UI 可查看 Trace |
| 3 | Node.js 插桩生效 | 产生 HTTP + PG spans |
| 4 | Prometheus 采集 metrics | `localhost:9090/targets` 显示 UP |
| 5 | Grafana Dashboard 可用 | 可查看延迟/错误率/RPS |
| 6 | 告警规则生效 | 模拟 5xx 错误触发 AlertManager |

---

## 五、产出文档

| 文档 | 路径 | 状态 |
|------|------|------|
| APM 集成指南 | `docs/APM_INTEGRATION_GUIDE.md` | ✅ |
| OpenTelemetry 部署计划 | `docs/OTEL_DEPLOYMENT_PLAN.md` | ✅ |
| 监控告警策略 | `docs/MONITORING_ALERTING_STRATEGY.md` | ✅ |
| APM 选型报告 | `docs/APM_SELECTION_REPORT.md` | ✅ 本文 |

---

> 完成时间: 2026-09-06
> 状态: ✅ 完成
