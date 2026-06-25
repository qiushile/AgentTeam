# Dev Agent（技术开发部）任务清单

## 任务 1：系统架构设计
**优先级**: P0 | **截止时间**: 第3周

### 整体架构
```
用户端 → CDN/WAF → API Gateway → 微服务层 → GPU资源池
                                  ↓
                            PostgreSQL + Redis
                                  ↓
                        Kubernetes (GPU调度)
```

### 核心模块设计
1. **用户服务 (user-service)**
   - 注册/登录（JWT认证）
   - 实名认证（企业/个人）
   - 权限与角色管理（RBAC）
   - 账户与钱包管理

2. **实例服务 (instance-service)**
   - GPU实例CRUD操作
   - 实例状态机（pending→running→stopped→terminated）
   - SSH密钥管理
   - 镜像选择与自定义

3. **调度服务 (scheduler-service)**
   - GPU资源池管理
   - 节点发现与注册
   - 资源分配算法（Bin Packing + 负载均衡）
   - 故障自动迁移

4. **计费服务 (billing-service)**
   - 按小时/按秒计费引擎
   - 余额预扣与实扣
   - 欠费停机逻辑
   - 账单生成与导出

5. **监控服务 (monitor-service)**
   - GPU指标采集（利用率、温度、显存、功耗）
   - Prometheus + Grafana集成
   - 告警规则配置
   - 日志聚合（ELK）

### 技术栈选型
- **前端**: React 18 + TypeScript + Vite + Ant Design 5 + Zustand
- **后端**: Go 1.21 + Gin + gRPC
- **数据库**: PostgreSQL 15 + Redis 7
- **消息队列**: RabbitMQ / Kafka（计费异步处理）
- **容器**: Kubernetes 1.28 + NVIDIA GPU Operator
- **部署**: Helm + ArgoCD
- **监控**: Prometheus + Grafana + Loki

---

## 任务 2：数据库设计
**优先级**: P0 | **截止时间**: 第3周

### 核心表结构
```sql
-- 用户表
CREATE TABLE users (
    id UUID PRIMARY KEY,
    username VARCHAR(50) UNIQUE,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    password_hash VARCHAR(255),
    status VARCHAR(20), -- active/suspended
    created_at TIMESTAMP DEFAULT NOW()
);

-- 钱包表
CREATE TABLE wallets (
    user_id UUID PRIMARY KEY REFERENCES users(id),
    balance DECIMAL(10,2) DEFAULT 0,
    currency VARCHAR(3) DEFAULT 'CNY'
);

-- GPU型号表
CREATE TABLE gpu_models (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50), -- A100-80G, RTX-4090, H100
    vram_gb INT,
    price_per_hour DECIMAL(6,2),
    total_count INT,
    available_count INT
);

-- GPU实例表
CREATE TABLE gpu_instances (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    gpu_model_id INT REFERENCES gpu_models(id),
    status VARCHAR(20), -- pending/running/stopped/terminated
    ssh_key TEXT,
    ip_address INET,
    created_at TIMESTAMP DEFAULT NOW(),
    started_at TIMESTAMP,
    stopped_at TIMESTAMP
);

-- 计费记录表
CREATE TABLE billing_records (
    id BIGSERIAL PRIMARY KEY,
    instance_id UUID REFERENCES gpu_instances(id),
    user_id UUID REFERENCES users(id),
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    amount DECIMAL(8,2),
    status VARCHAR(20) -- pending/paid/failed
);
```

---

## 任务 3：核心API开发
**优先级**: P0 | **截止时间**: 第5周

### API清单
| 模块 | 接口 | 方法 | 说明 |
|------|------|------|------|
| 认证 | /api/v1/auth/register | POST | 用户注册 |
| 认证 | /api/v1/auth/login | POST | 用户登录 |
| 用户 | /api/v1/users/me | GET | 获取当前用户信息 |
| GPU | /api/v1/gpu/models | GET | 获取GPU型号列表 |
| 实例 | /api/v1/instances | GET | 获取用户实例列表 |
| 实例 | /api/v1/instances | POST | 创建GPU实例 |
| 实例 | /api/v1/instances/{id}/start | POST | 启动实例 |
| 实例 | /api/v1/instances/{id}/stop | POST | 停止实例 |
| 实例 | /api/v1/instances/{id}/release | DELETE | 释放实例 |
| 计费 | /api/v1/billing/balance | GET | 查询余额 |
| 计费 | /api/v1/billing/records | GET | 查询账单记录 |
| 监控 | /api/v1/instances/{id}/metrics | GET | 获取实例监控数据 |

---

## 任务 4：GPU调度核心
**优先级**: P0 | **截止时间**: 第6周

### 调度逻辑
1. **资源发现**: 定时扫描可用GPU节点
2. **资源分配**: 根据用户请求匹配最优GPU
3. **容器创建**: 通过Kubernetes API创建Pod
4. **状态同步**: 实时同步实例状态到数据库
5. **故障处理**: 节点故障时自动迁移实例

### Kubernetes集成
- 使用 NVIDIA GPU Operator 管理GPU设备
- 通过 Device Plugin 暴露GPU资源
- 使用 Toleration + NodeSelector 实现GPU隔离
- 通过 CSI 插件挂载持久化存储

---

## 任务 5：前端控制台开发
**优先级**: P1 | **截止时间**: 第7周

### 页面清单
1. **仪表盘**: GPU实例概览、资源使用统计、账单摘要
2. **实例管理**: 创建/停止/启动/释放实例、SSH连接信息
3. **GPU选型**: 各GPU型号参数对比与价格展示
4. **账单中心**: 消费明细、发票申请、充值记录
5. **监控面板**: 实时GPU利用率/温度/显存图表
6. **设置中心**: 个人信息、SSH密钥管理、API Token

---

## 任务 6：基础设施搭建
**优先级**: P1 | **截止时间**: 第4周

### CI/CD流水线
- GitHub Actions / GitLab CI
- 自动化测试（单元测试 + 集成测试）
- Docker镜像构建与推送
- Helm Chart部署
- 蓝绿部署/金丝雀发布

### 环境规划
- dev: 开发环境
- staging: 预发布环境
- production: 生产环境
