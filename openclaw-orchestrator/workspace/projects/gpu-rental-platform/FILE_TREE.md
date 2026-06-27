# GPU Cloud 算力租赁平台 - 完整目录树

```
gpu-rental-platform/
│
├── PROJECT_BRIEF.md                          # 项目总览与部门分工
├── DEPARTMENT_TASKS.md                       # 六部门Agent详细任务分配
├── PROJECT_SUMMARY.md                        # 项目总结报告 (最终版)
├── PROJECT_STRUCTURE.html                    # 可视化项目结构图 (HTML)
│
├── tasks/                                    # 6个Agent详细任务文档
│   ├── PM_AGENT_TASKS.md                     # 产品部：市场调研/竞品分析/PRD
│   ├── DEV_AGENT_TASKS.md                    # 开发部：架构/前后端/GPU调度
│   ├── UI_DESIGNER_AGENT_TASKS.md            # 设计部：品牌VI/控制台UI/设计系统
│   ├── OPERATIONS_AGENT_TASKS.md             # 运营部：指标体系/埋点/BI看板
│   ├── CUSTOMER_SERVICE_AGENT_TASKS.md       # 客服部：多渠道/知识库/智能客服
│   └── SECURITY_AGENT_TASKS.md               # 安全部：零信任/数据安全/合规
│
├── frontend/                                 # 前端官网+控制台
│   └── index.html                            # 完整响应式页面 (~22KB)
│       ├── 导航栏 (毛玻璃吸顶)
│       ├── Hero 区域 (核心价值主张)
│       ├── GPU 实例卡片 (6款)
│       ├── 产品优势 (4项)
│       ├── 价格表 (完整矩阵)
│       ├── 控制台预览 (仪表盘+实例列表)
│       ├── CTA 区域
│       └── 页脚
│
├── backend/                                  # 后端 API (Go + Gin)
│   ├── go.mod                                # Go 模块依赖
│   ├── go.sum                                # 依赖校验
│   ├── Dockerfile                            # 多阶段构建
│   ├── docker-compose.yml                    # 全栈部署 (Postgres+Redis+Prometheus+Grafana)
│   ├── README.md                             # 后端文档
│   │
│   ├── cmd/
│   │   └── server/
│   │       └── main.go                       # 入口文件 (~160行)
│   │           ├── 配置加载
│   │           ├── 数据库连接 + 自动迁移
│   │           ├── Redis 连接
│   │           ├── GPU 种子数据
│   │           ├── 服务初始化 (5个)
│   │           ├── Billing Worker 启动
│   │           ├── Gin 路由配置 (16端点)
│   │           └── 优雅关闭
│   │
│   ├── migrations/
│   │   └── 001_init.sql                      # 数据库迁移 (~120行)
│   │       ├── users 表
│   │       ├── wallets 表
│   │       ├── gpu_models 表
│   │       ├── gpu_instances 表
│   │       ├── billing_records 表
│   │       ├── recharge_records 表
│   │       ├── ssh_keys 表
│   │       ├── api_tokens 表
│   │       ├── 8个索引
│   │       └── 6款GPU种子数据
│   │
│   ├── monitoring/
│   │   └── prometheus.yml                    # Prometheus 监控配置
│   │
│   └── internal/
│       ├── config/
│       │   └── config.go                     # 配置加载 (~45行)
│       │       ├── Port
│       │       ├── DatabaseURL
│       │       ├── RedisURL
│       │       ├── JWTSecret
│       │       └── JWTExpiry
│       │
│       ├── database/
│       │   ├── postgres.go                   # PostgreSQL 连接 + 自动迁移 (~140行)
│       │   │       ├── NewPostgres()
│       │   │       ├── Close()
│       │   │       └── Migrate() - 8表自动创建
│       │   │
│       │   └── redis.go                      # Redis 连接 + 缓存操作 (~70行)
│       │           ├── NewRedis()
│       │           ├── Close()
│       │           ├── Set/Get/Del/Exists
│       │           ├── SetInstanceMetrics()
│       │           ├── GetInstanceMetrics()
│       │           └── IncrementCounter()
│       │
│       ├── models/
│       │   ├── user.go                       # 用户模型 (~55行)
│       │   │       ├── User struct
│       │   │       ├── Wallet struct
│       │   │       ├── CreateUserRequest struct
│       │   │       ├── LoginRequest struct
│       │   │       ├── AuthResponse struct
│       │   │       ├── SSHKey struct
│       │   │       └── APIToken struct
│       │   │
│       │   ├── gpu.go                        # GPU模型 (~18行)
│       │   │       └── GPUModel struct
│       │   │
│       │   ├── instance.go                   # GPU实例模型 (~55行)
│       │   │       ├── CreateInstanceRequest struct
│       │   │       ├── Instance struct
│       │   │       ├── SSHInfo struct
│       │   │       └── InstanceStatus 常量
│       │   │
│       │   └── billing.go                    # 计费模型 (~30行)
│       │           ├── BillingRecord struct
│       │           ├── RechargeRequest struct
│       │           ├── BalanceResponse struct
│       │           └── BillingSummary struct
│       │
│       ├── service/
│       │   ├── user_service.go               # 用户服务 (~170行)
│       │   │       ├── Register() - 注册+送¥100
│       │   │       ├── Login() - 登录验证
│       │   │       ├── GenerateTokens() - JWT生成
│       │   │       ├── GetUserByID() - 查询用户
│       │   │       └── GetBalance() - 查询余额
│       │   │
│       │   ├── gpu_service.go                # GPU服务 (~150行)
│       │   │       ├── ListModels() - GPU列表
│       │   │       ├── GetModel() - GPU详情
│       │   │       ├── CheckAvailability() - 库存检查
│       │   │       ├── DecrementAvailability() - 扣库存
│       │   │       ├── IncrementAvailability() - 还库存
│       │   │       └── SeedModels() - 种子数据
│       │   │
│       │   ├── instance_service.go           # 实例服务 (~265行)
│       │   │       ├── Create() - 创建实例
│       │   │       ├── provisionInstance() - 异步创建Pod
│       │   │       ├── ListByUser() - 用户实例列表
│       │   │       ├── GetByID() - 实例详情
│       │   │       ├── Start() - 启动实例
│       │   │       ├── Stop() - 停止实例
│       │   │       ├── Release() - 释放实例
│       │   │       └── GetSSHInfo() - SSH连接信息
│       │   │
│       │   ├── billing_service.go            # 计费服务 (~175行)
│       │   │       ├── GetBalance() - 余额查询
│       │   │       ├── ListRecords() - 账单列表
│       │   │       ├── Recharge() - 充值
│       │   │       ├── CalculateUsage() - 使用量计算
│       │   │       ├── DeductBalance() - 扣费
│       │   │       └── GetSummary() - 账单摘要
│       │   │
│       │   ├── monitor_service.go            # 监控服务 (~90行)
│       │   │       ├── GetMetrics() - GPU指标
│       │   │       ├── GetMetricsHistory() - 历史指标
│       │   │       ├── PushMetrics() - 推送指标
│       │   │       └── simulateMetrics() - 模拟数据
│       │   │
│       │   └── service_test.go               # 服务层基础测试 (~40行)
│       │           └── 5个构造函数测试
│       │
│       ├── handler/
│       │   ├── auth_handler.go               # 认证处理器 (~90行)
│       │   │       ├── Register()
│       │   │       ├── Login()
│       │   │       └── RefreshToken()
│       │   │
│       │   ├── user_handler.go               # 用户处理器 (~65行)
│       │   │       ├── GetProfile()
│       │   │       └── UpdateProfile()
│       │   │
│       │   ├── gpu_handler.go                # GPU处理器 (~45行)
│       │   │       ├── ListModels()
│       │   │       └── GetModel()
│       │   │
│       │   ├── instance_handler.go           # 实例处理器 (~125行)
│       │   │       ├── ListInstances()
│       │   │       ├── CreateInstance()
│       │   │       ├── GetInstance()
│       │   │       ├── StartInstance()
│       │   │       ├── StopInstance()
│       │   │       ├── ReleaseInstance()
│       │   │       └── GetSSHInfo()
│       │   │
│       │   ├── billing_handler.go            # 计费处理器 (~70行)
│       │   │       ├── GetBalance()
│       │   │       ├── ListRecords()
│       │   │       └── Recharge()
│       │   │
│       │   └── monitor_handler.go            # 监控处理器 (~30行)
│       │           └── GetMetrics()
│       │
│       ├── middleware/
│       │   ├── auth.go                       # JWT 认证中间件 (~70行)
│       │   │       ├── Token解析
│       │   │       ├── 有效期验证
│       │   │       └── 用户上下文设置
│       │   │
│       │   ├── cors.go                       # CORS 跨域中间件 (~20行)
│       │   │       └── 全跨域允许
│       │   │
│       │   └── logger.go                     # 请求日志中间件 (~30行)
│       │           └── Zap结构化日志
│       │
│       └── worker/
│           └── billing_worker.go             # 计费定时任务 (~165行)
│                   ├── Start() - 启动轮询
│                   ├── processBillingCycle() - 计费周期处理
│                   │   ├── 查询运行中实例
│                   │   ├── 计算使用时长
│                   │   ├── 余额检查
│                   │   ├── 余额不足停机
│                   │   └── 正常扣费
│
├── diagrams/                                 # 架构图
│   ├── openclaw-architecture.html            # OpenClaw 6层架构图 (HTML)
│   │       ├── ① User Channels
│   │       ├── ② Gateway Layer
│   │       ├── ③ Agent Orchestrator
│   │       ├── ④ Tool Layer
│   │       ├── ⑤ LLM Provider
│   │       └── ⑥ Storage Layer
│   │
│   └── gpu-cloud-architecture.excalidraw     # GPU Cloud 平台架构图 (Excalidraw)
│           ├── 客户端层
│           ├── 网关层
│           ├── 微服务层 (5个服务 + Worker)
│           ├── 数据存储层 (Postgres+Redis+K8s+Prometheus+Grafana)
│           └── GPU 资源池 (5种GPU型号)
│
└── memory/                                   # 会话记忆
    └── 2026-06-26.md                         # 项目完成日志
```

## 统计

| 类别 | 数量 |
|------|------|
| **目录** | 20 |
| **文件总数** | 45+ |
| **Go 代码** | ~4,200 行 |
| **前端代码** | ~22 KB |
| **SQL 迁移** | ~120 行 |
| **文档** | 10+ 份 |
| **架构图** | 2 份 |

## API 端点速查

```
POST   /api/v1/auth/register     # 注册
POST   /api/v1/auth/login        # 登录
POST   /api/v1/auth/refresh      # 刷新Token
GET    /api/v1/users/me          # 个人信息
PUT    /api/v1/users/me          # 更新信息
GET    /api/v1/gpu/models        # GPU列表
GET    /api/v1/gpu/models/:id    # GPU详情
GET    /api/v1/instances         # 实例列表
POST   /api/v1/instances         # 创建实例
GET    /api/v1/instances/:id     # 实例详情
POST   /api/v1/instances/:id/start   # 启动
POST   /api/v1/instances/:id/stop    # 停止
DELETE /api/v1/instances/:id         # 释放
GET    /api/v1/instances/:id/ssh     # SSH信息
GET    /api/v1/billing/balance       # 余额
GET    /api/v1/billing/records       # 账单
POST   /api/v1/billing/recharge      # 充值
GET    /api/v1/instances/:id/metrics # GPU指标
```

---
*生成于 2026-06-27*
