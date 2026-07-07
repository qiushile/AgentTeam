# 性能优化指南

## 1. 数据库性能优化

### 1.1 索引优化

#### 索引类型选择
| 场景 | 推荐索引 | 示例 |
|------|---------|------|
| 等值查询 | B-Tree | `CREATE INDEX idx_tasks_status ON shared.tasks(status)` |
| 范围查询 | B-Tree | `CREATE INDEX idx_tasks_created ON shared.tasks(created_at)` |
| 全文搜索 | GIN | `CREATE INDEX idx_docs_content ON documents USING GIN(to_tsvector(content))` |
| JSON 查询 | GIN | `CREATE INDEX idx_config_data ON configs USING GIN(data)` |
| 数组查询 | GIN | `CREATE INDEX idx_tags ON articles USING GIN(tags)` |

#### 索引优化原则
- [ ] 仅对高频查询字段建索引
- [ ] 复合索引遵循最左前缀原则
- [ ] 定期分析索引使用率 (`pg_stat_user_indexes`)
- [ ] 删除未使用的索引 (`idx_scan = 0`)

#### 慢查询诊断
```sql
-- 启用慢查询日志
ALTER SYSTEM SET log_min_duration_statement = 1000; -- 1s

-- 查看最慢查询
SELECT query, calls, mean_exec_time, total_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;

-- 查看索引使用率
SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read
FROM pg_stat_user_indexes
ORDER BY idx_scan ASC
LIMIT 20;
```

### 1.2 查询优化

#### EXPLAIN 分析
```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM shared.tasks WHERE status = 'PENDING';
```

#### 常见问题与解决方案
| 问题 | 现象 | 解决方案 |
|------|------|---------|
| 全表扫描 | Seq Scan | 添加合适索引 |
| 嵌套循环 | Nested Loop 高耗时 | 添加索引 / 改写 JOIN |
| 排序溢出 | Sort Method: external merge | 增加 work_mem |
| 哈希碰撞 | Hash Join 高耗时 | 增加统计信息 / 索引 |

#### 查询改写示例
```sql
-- ❌ N+1 查询
SELECT * FROM tasks WHERE assignee = 'dev_user';
-- 然后在循环中查询每个任务的详情...

-- ✅ JOIN 一次性查询
SELECT t.*, u.name as assignee_name
FROM tasks t
LEFT JOIN users u ON t.assignee_id = u.id
WHERE t.assignee = 'dev_user';
```

## 2. 缓存策略

### 2.1 缓存层级
```
客户端缓存 (Browser/HTTP Cache)
        ↓
CDN 缓存 (静态资源)
        ↓
应用层缓存 (Redis / Memcached)
        ↓
数据库查询缓存 (pgBouncer / PostgreSQL shared_buffers)
```

### 2.2 Redis 缓存模式

#### Cache-Aside (旁路缓存)
```javascript
async function getTask(id) {
  // 1. 先查缓存
  let task = await redis.get(`task:${id}`);
  if (task) return JSON.parse(task);
  
  // 2. 缓存未命中，查数据库
  task = await db.query('SELECT * FROM tasks WHERE id = $1', [id]);
  
  // 3. 写入缓存，设置 TTL
  if (task) {
    await redis.setex(`task:${id}`, 300, JSON.stringify(task)); // 5 分钟
  }
  
  return task;
}

async function updateTask(id, data) {
  // 更新数据库
  await db.query('UPDATE tasks SET ... WHERE id = $1', [id]);
  // 删除缓存 (下次读取时重建)
  await redis.del(`task:${id}`);
}
```

#### 缓存策略选择
| 模式 | 适用场景 | 优缺点 |
|------|---------|-------|
| Cache-Aside | 读多写少 | 简单，可能有短暂不一致 |
| Write-Through | 强一致性要求 | 写延迟高，数据一致 |
| Write-Behind | 高吞吐写入 | 可能丢数据，性能高 |

### 2.3 PostgreSQL 配置调优
```conf
# postgresql.conf 关键参数
shared_buffers = 256MB              # 通常为内存的 25%
effective_cache_size = 1GB          # 通常为内存的 50-75%
work_mem = 16MB                     # 排序/哈希操作内存
maintenance_work_mem = 128MB        # VACUUM/CREATE INDEX 内存
wal_buffers = 16MB                  # WAL 写入缓冲
checkpoint_completion_target = 0.9  # 检查点完成目标
random_page_cost = 1.1              # SSD 设为 1.1，HDD 设为 4.0
```

## 3. 前端性能优化

### 3.1 加载优化
- [ ] 代码分割 (Code Splitting) - React.lazy / dynamic import
- [ ] 图片优化 - WebP 格式、懒加载、响应式图片
- [ ] 字体优化 - font-display: swap、子集化
- [ ] 预加载关键资源 - `<link rel="preload">`

### 3.2 渲染优化
- [ ] 虚拟列表 (react-virtualized) - 长列表渲染
- [ ] Debounce/Throttle - 高频事件处理
- [ ] useMemo / useCallback - React 性能优化
- [ ] Web Workers - CPU 密集型任务

### 3.3 性能指标
| 指标 | 目标值 | 说明 |
|------|-------|------|
| FCP | < 1.8s | 首次内容绘制 |
| LCP | < 2.5s | 最大内容绘制 |
| CLS | < 0.1 | 累积布局偏移 |
| TTI | < 3.8s | 可交互时间 |

## 4. API 性能优化

### 4.1 响应优化
- [ ] 分页查询 (LIMIT/OFFSET 或 Cursor)
- [ ] 字段选择 (`?fields=id,title,status`)
- [ ] 批量接口 (减少网络往返)
- [ ] GraphQL (按需获取数据)

### 4.2 并发优化
- [ ] 连接池管理 (pgBouncer / 应用层池)
- [ ] 异步处理 (消息队列)
- [ ] 请求合并 (Batching)

### 4.3 限流与降级
```javascript
// 令牌桶限流
const rateLimiter = new RateLimiter({
  tokensPerSecond: 100,
  maxTokens: 200
});

// 熔断器
const circuitBreaker = new CircuitBreaker({
  failureThreshold: 5,
  resetTimeout: 30000
});
```

## 5. 性能测试

### 5.1 工具选型
| 工具 | 用途 | 特点 |
|------|------|------|
| k6 | 负载测试 | JS 脚本，CI 集成友好 |
| Apache JMeter | 压力测试 | GUI 友好，功能全面 |
| Artillery | API 性能测试 | 配置简单，云原生 |
| Lighthouse | 前端性能 | Chrome DevTools 集成 |

### 5.2 k6 测试示例
```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: 100,        // 100 虚拟用户
  duration: '30s', // 持续 30 秒
  thresholds: {
    http_req_duration: ['p(95)<500'], // P95 < 500ms
    http_req_failed: ['rate<0.01'],   // 错误率 < 1%
  },
};

export default function () {
  const res = http.get('http://localhost:3000/api/v1/tasks');
  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });
  sleep(1);
}
```

---

> 创建时间: 2026-07-08
> 创建者: 研发部高级研发专家
> 状态: 待评审
