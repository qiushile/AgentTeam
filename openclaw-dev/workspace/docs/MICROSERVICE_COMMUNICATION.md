# 微服务间通信优化指南

## 一、通信模式对比

### REST vs gRPC vs 消息队列

| 维度 | REST (HTTP/JSON) | gRPC (HTTP/2+Protobuf) | 消息队列 |
|------|-----------------|------------------------|----------|
| **协议** | HTTP/1.1 | HTTP/2 | AMQP/MQTT/自定义 |
| **序列化** | JSON (文本) | Protobuf (二进制) | JSON/Protobuf/Avro |
| **性能** | 中 (序列化和传输开销大) | 高 (二进制 + 多路复用) | 高 (异步解耦) |
| **延迟** | 50-200ms | 5-50ms | 取决于队列类型 |
| **同步/异步** | 同步 | 同步/流式 | 异步 |
| **适用场景** | 外部 API、简单内部调用 | 高性能内部调用、流式 | 事件驱动、解耦 |
| **调试难度** | 低 (浏览器可调试) | 中 (需 grpcurl/gRPC UI) | 高 (异步调试复杂) |
| **学习曲线** | 低 | 中 | 中高 |

---

## 二、gRPC vs REST 对比评估

### 性能基准测试参考

| 场景 | REST (JSON) | gRPC (Protobuf) | 提升 |
|------|------------|-----------------|------|
| **小消息 (<1KB)** | 15ms | 3ms | **5x** |
| **中消息 (10KB)** | 25ms | 5ms | **5x** |
| **大消息 (1MB)** | 150ms | 30ms | **5x** |
| **吞吐量 (req/s)** | 5,000 | 25,000 | **5x** |
| **Payload 大小** | 1.5x (JSON 膨胀) | 1x (二进制) | **33%** |

### 何时选 gRPC

- ✅ 服务间高频调用 (>1000 req/s)
- ✅ 低延迟要求 (<50ms)
- ✅ 强类型契约 (Protobuf schema)
- ✅ 流式数据传输 (Server/Client/Bidirectional streaming)
- ✅ 带宽受限环境

### 何时保留 REST

- ✅ 外部 API (客户端兼容性)
- ✅ 低频调用 / CRUD 操作
- ✅ 需要浏览器直接访问
- ✅ 快速原型开发

---

## 三、服务网格 (Istio) 方案调研

### Istio 核心价值

```
┌──────────────────────────────────────────────────────┐
│                    Application Pod                     │
│  ┌─────────────┐  ┌─────────────┐                     │
│  │   Service    │  │    Envoy    │ ← Sidecar Proxy     │
│  │   Container  │←→│  Sidecar    │                     │
│  └─────────────┘  └──────┬──────┘                     │
│                          │                             │
└──────────────────────────┼─────────────────────────────┘
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
        ┌──────────┐ ┌──────────┐ ┌──────────┐
        │ Traffic  │ │ Security │ │Observ-   │
        │ Mgmt     │ │ (mTLS)   │ │ability   │
        └──────────┘ └──────────┘ └──────────┘
```

### 关键能力

| 能力 | 说明 |
|------|------|
| **流量管理** | 金丝雀发布、A/B 测试、故障注入 |
| **安全** | 自动 mTLS、授权策略、认证 |
| **可观测性** | 自动指标采集、分布式追踪、访问日志 |
| **弹性** | 熔断、重试、超时、限流 |
| **多集群** | 跨集群服务发现、故障转移 |

### 何时引入 Istio

- ✅ 10+ 个微服务需要统一管理
- ✅ 需要精细化流量控制 (金丝雀/蓝绿)
- ✅ 需要服务间 mTLS 加密
- ✅ 已有 Kubernetes 基础设施
- ❌ <5 个服务 → 直接调用更简单
- ❌ 非 K8s 环境 → 考虑 Linkerd 或 Consul

### 基本配置示例

```yaml
# VirtualService - 流量拆分 (金丝雀)
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: user-service
spec:
  hosts:
  - user-service
  http:
  - route:
    - destination:
        host: user-service
        subset: v1
      weight: 90
    - destination:
        host: user-service
        subset: v2
      weight: 10

# DestinationRule - 熔断
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: user-service
spec:
  host: user-service
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        h2UpgradePolicy: UPGRADE
        http1MaxPendingRequests: 100
        http2MaxRequests: 1000
    outlierDetection:
      consecutiveErrors: 5
      interval: 30s
      baseEjectionTime: 30s
```

---

## 四、消息队列选型

### Kafka vs RabbitMQ vs Redis Streams

| 维度 | Kafka | RabbitMQ | Redis Streams |
|------|-------|----------|---------------|
| **模型** | 日志/Partition | 队列/Exchange | 流/Consumer Group |
| **吞吐** | 极高 (百万级 msg/s) | 中 (万级 msg/s) | 高 (十万级 msg/s) |
| **持久化** | 磁盘日志 | 磁盘队列 | Redis 内存 (可选 AOF) |
| **消息保留** | 可配置时间/大小 | 消费后删除 | 可配置长度/时间 |
| **顺序保证** | Partition 内有序 | 队列有序 | Stream 有序 |
| **运维复杂度** | 高 (ZK/KRaft) | 中 | 低 (复用 Redis) |
| **生态** | 流处理生态丰富 | 路由模式丰富 | 轻量简单 |
| **适用场景** | 事件溯源、流处理 | 复杂路由、任务队列 | 轻量事件、会话 |

### 推荐方案

| 场景 | 推荐 | 原因 |
|------|------|------|
| **当前规模 (<10 服务)** | Redis Streams | 零额外运维，复用现有 Redis |
| **中等规模 (10-30 服务)** | RabbitMQ | 灵活路由，运维友好 |
| **大规模 (>30 服务)** | Kafka | 高吞吐，流处理能力 |

---

## 五、通信优化最佳实践

### 5.1 请求合并 (Batching)

```javascript
// 将多个独立请求合并为一次批量调用
// Bad: N 次独立调用
for (const userId of userIds) {
  const user = await fetch(`/api/users/${userId}`);
}

// Good: 一次批量调用
const users = await fetch('/api/users/batch', {
  method: 'POST',
  body: JSON.stringify({ ids: userIds })
});
```

### 5.2 连接复用

```javascript
// Node.js - 使用 Agent 复用 HTTP 连接
const https = require('https');
const agent = new https.Agent({
  keepAlive: true,
  maxSockets: 50,
  maxFreeSockets: 10,
  timeout: 5000,
});

// 所有请求共用 agent
fetch('https://api.internal/data', { agent });
```

### 5.3 超时与重试

```yaml
# gRPC 客户端配置
grpc:
  timeout: 3s
  retry:
    maxAttempts: 3
    initialBackoff: 100ms
    maxBackoff: 1s
    backoffMultiplier: 2
    retryableStatusCodes:
      - UNAVAILABLE
      - DEADLINE_EXCEEDED
```

### 5.4 缓存策略

```javascript
// 响应缓存 (适合读多写少场景)
const cache = new Map();
const CACHE_TTL = 30000; // 30s

async function getCachedData(key, fetchFn) {
  const cached = cache.get(key);
  if (cached && Date.now() - cached.timestamp < CACHE_TTL) {
    return cached.data;
  }
  const data = await fetchFn();
  cache.set(key, { data, timestamp: Date.now() });
  return data;
}
```

### 5.5 服务降级

```javascript
// 当依赖服务不可用时返回降级数据
async function getUserProfile(userId) {
  try {
    return await userService.getProfile(userId);
  } catch (err) {
    if (err.code === 'UNAVAILABLE') {
      // 降级: 从缓存返回基础信息
      return cacheService.getFallback(userId);
    }
    throw err;
  }
}
```

---

## 六、架构决策

### 当前阶段推荐架构

```
┌─────────────────────────────────────────────┐
│                API Gateway                   │
│              (Kong / Nginx)                  │
└────────┬──────────┬──────────┬──────────────┘
         │          │          │
    ┌────▼───┐ ┌───▼────┐ ┌───▼────┐
    │Service A│ │Service B│ │Service C│
    │ Node.js │ │ Python │ │  Java   │
    └────┬────┘ └───┬────┘ └───┬────┘
         │          │          │
         └────┬─────┴────┬─────┘
              │          │
         ┌────▼────┐ ┌───▼─────┐
         │  REST   │ │ Redis   │
         │ (外部)  │ │ Streams │
         └─────────┘ │(内部事件)│
                     └─────────┘
```

- **外部 API**: REST/JSON (兼容性)
- **内部高频调用**: 直接 HTTP (当前规模足够)
- **异步事件**: Redis Streams (轻量)
- **监控**: OpenTelemetry (已集成)

### 演进路线

| 服务数 | 通信方式 | 治理方式 |
|--------|---------|---------|
| **1-5** | 直接 REST | 手动配置 |
| **5-15** | REST + gRPC 混合 | 服务注册中心 (Consul) |
| **15-30** | gRPC 为主 + Redis Streams | 服务网格 (Linkerd) |
| **30+** | gRPC + Kafka + 事件驱动 | Istio + 完整服务网格 |

---

> 创建时间: 2026-07-27
> 创建者: 研发部高级研发专家
> 状态: 完成
