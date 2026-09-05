# GPU Cloud - 高性能算力租赁平台

## 项目概述

GPU 算力租赁平台，支持按需租赁 A100、H100、RTX4090 等高性能 GPU，秒级创建，按分钟计费。

## 技术栈

| 组件 | 技术 |
|------|------|
| 后端 | Go 1.21 + Gin |
| 数据库 | PostgreSQL 15 |
| 缓存 | Redis 7 |
| 部署 | Docker + Kubernetes |
| 认证 | JWT |

## 项目结构

```
├── cmd/server/          # 入口
│   └── main.go
├── config/              # 配置
│   └── config.go
├── internal/            # 内部包
│   ├── db/             # 数据库连接
│   ├── handler/        # HTTP 处理器
│   ├── middleware/     # 中间件
│   ├── model/          # 数据模型
│   └── router/         # 路由
├── services/           # 业务服务
│   ├── database.go
│   ├── migrations.go
│   └── redis.go
├── worker/             # 后台任务
│   └── billing.go
├── frontend/           # 前端页面
│   └── index.html
├── sql/                # 数据库脚本
│   ├── schema.sql
│   └── seed.sql
├── Dockerfile
├── docker-compose.yml
└── Makefile
```

## API 端点

| 方法 | 路径 | 说明 | 认证 |
|------|------|------|------|
| POST | /api/v1/auth/register | 用户注册 | ❌ |
| POST | /api/v1/auth/login | 用户登录 | ❌ |
| GET | /api/v1/gpu/prices | GPU 价格列表 | ❌ |
| GET | /api/v1/user/me | 获取用户信息 | ✅ |
| POST | /api/v1/instances | 创建 GPU 实例 | ✅ |
| GET | /api/v1/instances | 查看实例列表 | ✅ |
| POST | /api/v1/instances/:id/stop | 停止实例 | ✅ |
| DELETE | /api/v1/instances/:id | 删除实例 | ✅ |
| POST | /api/v1/orders | 创建充值订单 | ✅ |
| GET | /api/v1/orders | 查看订单历史 | ✅ |
| GET | /api/v1/usage | 查看使用记录 | ✅ |
| POST | /api/v1/api-keys | 创建 API 密钥 | ✅ |
| GET | /api/v1/api-keys | 查看密钥列表 | ✅ |
| DELETE | /api/v1/api-keys/:id | 撤销密钥 | ✅ |
| GET | /health | 健康检查 | ❌ |

## 快速启动

### 方式一：Docker Compose

```bash
docker-compose up -d
```

### 方式二：本地开发

```bash
# 1. 启动依赖
docker-compose up -d postgres redis

# 2. 安装依赖
make deps

# 3. 运行
make run
```

### 方式三：构建二进制

```bash
make build
./bin/gpu-platform
```

## GPU 型号与价格

| GPU 型号 | 显存 | vCPU | 价格/小时 |
|----------|------|------|-----------|
| RTX 4090 | 24GB | 8 | ¥1.50 |
| V100 | 32GB | 8 | ¥3.00 |
| A100 40GB | 40GB | 8 | ¥8.00 |
| A100 80GB | 80GB | 16 | ¥15.00 |
| H100 | 80GB | 16 | ¥25.00 |

## 计费说明

- 按 5 分钟周期自动计费
- 计费 Worker 每 5 分钟运行一次
- 余额不足时实例将被停止
- 使用记录可在 `/api/v1/usage` 查看

## 数据库表

| 表名 | 说明 |
|------|------|
| users | 用户信息 |
| gpu_instances | GPU 实例 |
| orders | 充值订单 |
| usage_logs | 使用记录 |
| api_keys | API 密钥 |
| system_logs | 系统日志 |
| notifications | 通知 |
| billing_records | 计费记录 |

## 许可证

MIT
