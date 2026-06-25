# GPU Cloud 后端项目结构
backend/
├── cmd/server/main.go          # 入口文件
├── go.mod
├── go.sum
├── internal/
│   ├── config/config.go        # 配置加载
│   ├── database/
│   │   ├── postgres.go         # PostgreSQL连接与迁移
│   │   └── redis.go            # Redis连接
│   ├── models/                 # 数据模型
│   │   ├── user.go
│   │   ├── gpu.go
│   │   ├── instance.go
│   │   └── billing.go
│   ├── service/                # 业务逻辑层
│   │   ├── user_service.go
│   │   ├── gpu_service.go
│   │   ├── instance_service.go
│   │   ├── billing_service.go
│   │   └── monitor_service.go
│   ├── handler/                # HTTP处理器
│   │   ├── auth_handler.go
│   │   ├── user_handler.go
│   │   ├── gpu_handler.go
│   │   ├── instance_handler.go
│   │   ├── billing_handler.go
│   │   └── monitor_handler.go
│   └── middleware/             # 中间件
│       ├── auth.go
│       ├── cors.go
│       └── logger.go
├── migrations/                 # 数据库迁移
│   └── 001_init.sql
└── docker-compose.yml
