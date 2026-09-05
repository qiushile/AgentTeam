# 微服务通信方案调研报告

> 日期: 2026-09-06
> 作者: 研发部高级研发专家 (dev_user)
> 状态: ✅ 已完成

---

## 一、gRPC vs REST 对比评估

### 结论：REST 为主，gRPC 按需引入

| 场景 | 推荐 | 理由 |
|------|------|------|
| 外部 API | **REST** | 浏览器兼容，生态成熟 |
| 内部低频调用 (<100 req/s) | **REST** | 调试简单，开发效率高 |
| 内部高频调用 (>1000 req/s) | **gRPC** | 5x 性能提升，低延迟 |
| 流式数据传输 | **gRPC** | 原生 Streaming 支持 |
| 强类型契约需求 | **gRPC** | Protobuf Schema |

> 当前团队规模 (1-5 服务)，REST 足够。预留 gRPC 接入能力。

---

## 二、服务网格 (Istio) 方案调研

### 结论：当前阶段不引入

| 服务规模 | 推荐方案 | Istio |
|---------|---------|-------|
| **1-5 服务** (当前) | 直接调用 | ❌ 过度工程 |
| **5-15 服务** | Consul 服务发现 | ❌ 仍不需要 |
| **15-30 服务** | Linkerd (轻量) | ⚠️ 可考虑 |
| **30+ 服务** | Istio | ✅ 推荐 |

### Istio 核心价值 (供未来参考)

- 流量管理：金丝雀发布、A/B 测试、故障注入
- 安全：自动 mTLS、授权策略
- 可观测性：自动指标采集、分布式追踪
- 弹性：熔断、重试、超时、限流

> 已有 OpenTelemetry 覆盖可观测性需求，Istio 的收益在 15+ 服务时才显现。

---

## 三、消息队列选型

### 结论：当前使用 Redis Streams

| MQ | 吞吐 | 运维成本 | 适用规模 | 当前推荐 |
|----|------|---------|---------|---------|
| **Redis Streams** | 10万 msg/s | 低 (复用 Redis) | <10 服务 | ✅ **首选** |
| **RabbitMQ** | 1万 msg/s | 中 | 10-30 服务 | 备选 |
| **Kafka** | 百万 msg/s | 高 (ZK/KRaft) | 30+ 服务 | 未来 |

### Redis Streams 使用示例

```javascript
// 生产者
await redis.xadd('task:events', '*', 'type', 'task_created', 'taskId', '123', 'ts', Date.now());

// 消费者组
await redis.xgroupCreate('task:events', 'dev-workers', '0', { MKSTREAM: true });
const [stream, messages] = await redis.xReadGroup('dev-workers', 'worker-1', ['task:events', '>'], { BLOCK: 5000 });
```

---

## 四、推荐架构 (当前阶段)

```
┌──────────────┐
│  API Gateway  │  REST/JSON (外部)
└──────┬───────┘
       │
  ┌────┴────┐
  │ Service  │  直接 HTTP (内部)
  └────┬────┘
       │
  ┌────┴────────────┐
  │  Redis Streams   │  异步事件
  │  OpenTelemetry   │  可观测性
  └─────────────────┘
```

### 演进路线

| 阶段 | 服务数 | 通信方式 | 治理 |
|------|--------|---------|------|
| **Now** | 1-5 | REST + Redis Streams | 手动配置 |
| **Next** | 5-15 | REST + gRPC 混合 | Consul |
| **Future** | 15-30 | gRPC + Redis Streams | Linkerd |
| **Scale** | 30+ | gRPC + Kafka | Istio |

---

## 五、产出文档

| 文档 | 路径 | 状态 |
|------|------|------|
| 微服务通信优化指南 | `docs/MICROSERVICE_COMMUNICATION.md` | ✅ |
| 微服务通信调研报告 | `docs/MICROSERVICE_COMMUNICATION_REPORT.md` | ✅ 本文 |

---

> 完成时间: 2026-09-06
> 状态: ✅ 完成
