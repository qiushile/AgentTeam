# GPU Cloud Platform - Backend API

基于 Go + Gin + PostgreSQL + Redis 的 GPU 算力租赁平台后端。

## 快速开始

### 本地开发
```bash
# 1. 启动依赖服务
docker compose up -d postgres redis

# 2. 安装依赖
go mod tidy

# 3. 运行服务（自动执行数据库迁移）
go run cmd/server/main.go
```

### Docker 全栈部署
```bash
docker compose up -d
```

## API 端点

### 认证
- `POST /api/v1/auth/register` - 用户注册
- `POST /api/v1/auth/login` - 用户登录
- `POST /api/v1/auth/refresh` - 刷新 Token

### 用户
- `GET /api/v1/users/me` - 获取个人信息
- `PUT /api/v1/users/me` - 更新个人信息

### GPU 型号
- `GET /api/v1/gpu/models` - GPU 型号列表
- `GET /api/v1/gpu/models/:id` - GPU 型号详情

### 实例
- `GET /api/v1/instances` - 实例列表
- `POST /api/v1/instances` - 创建实例
- `GET /api/v1/instances/:id` - 实例详情
- `POST /api/v1/instances/:id/start` - 启动实例
- `POST /api/v1/instances/:id/stop` - 停止实例
- `DELETE /api/v1/instances/:id` - 释放实例
- `GET /api/v1/instances/:id/ssh` - SSH 连接信息

### 计费
- `GET /api/v1/billing/balance` - 查询余额
- `GET /api/v1/billing/records` - 账单记录
- `POST /api/v1/billing/recharge` - 充值

### 监控
- `GET /api/v1/instances/:id/metrics` - GPU 监控数据

## 技术栈
- **框架**: Go 1.21 + Gin
- **数据库**: PostgreSQL 15 (pgx)
- **缓存**: Redis 7 (go-redis)
- **认证**: JWT (golang-jwt)
- **日志**: Zap
- **容器**: Docker Compose
