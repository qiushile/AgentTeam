# CI/CD 流水线设计方案

## 1. 概述

设计自动化构建、测试、部署流水线，支持持续集成与持续交付。

## 2. 流水线架构

```
开发者 Push → GitHub → CI 触发 → 构建 → 测试 → 安全扫描 → 构建镜像 → 部署
```

## 3. CI 流水线 (Continuous Integration)

### 3.1 触发条件
- `feature/*` 分支 Push → 完整 CI 流程
- `develop` 分支 Push → CI + 集成测试
- `main` 分支 Push → CI + 部署到 Staging

### 3.2 Pipeline 阶段

```yaml
# .github/workflows/ci.yml
name: CI Pipeline
on:
  push:
    branches: ['**']
  pull_request:
    branches: [main, develop]

jobs:
  lint:
    name: 🔍 Code Lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm run lint
      - run: npm run format:check

  test:
    name: 🧪 Unit Tests
    runs-on: ubuntu-latest
    needs: lint
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_PASSWORD: test_pass
          POSTGRES_DB: test_db
        ports: ['5432:5432']
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm test -- --coverage
      - name: Upload Coverage
        uses: codecov/codecov-action@v3

  security:
    name: 🔒 Security Scan
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v4
      - run: npm audit --audit-level=high
      - name: Snyk Scan
        uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}

  build:
    name: 📦 Build
    runs-on: ubuntu-latest
    needs: [test, security]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm run build

  docker:
    name: 🐳 Docker Image
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/develop' || github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ghcr.io/${{ github.repository }}:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

## 4. CD 流水线 (Continuous Deployment)

### 4.1 环境定义
| 环境 | 触发条件 | 部署方式 | 数据 |
|------|---------|---------|------|
| Staging | `develop` 合并到 `main` | 自动 | 脱敏数据 |
| Production | Release Tag | 手动审批 | 生产数据 |

### 4.2 部署策略

#### 蓝绿部署
```yaml
# 部署新版本到 Green 环境
# 健康检查通过
# 切换流量 Green → Production
# 保留 Blue 环境 30 分钟作为回滚备用
```

#### 滚动更新 (Kubernetes)
```yaml
spec:
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
    type: RollingUpdate
```

### 4.3 部署脚本
```bash
#!/bin/bash
# deploy.sh

ENV=${1:-staging}
VERSION=${2:-latest}
IMAGE="ghcr.io/${GITHUB_REPOSITORY}:${VERSION}"

echo "Deploying ${IMAGE} to ${ENV}..."

# 拉取最新镜像
docker pull ${IMAGE}

# 停止旧容器
docker stop dev-api-${ENV} || true
docker rm dev-api-${ENV} || true

# 启动新容器
docker run -d \
  --name dev-api-${ENV} \
  --restart unless-stopped \
  -p ${ENV_PORT}:3000 \
  --env-file .env.${ENV} \
  ${IMAGE}

# 健康检查
echo "Waiting for health check..."
for i in {1..30}; do
  if curl -sf http://localhost:${ENV_PORT}/health > /dev/null; then
    echo "✅ Health check passed"
    exit 0
  fi
  sleep 2
done

echo "❌ Health check failed, rolling back..."
docker stop dev-api-${ENV}
docker start dev-api-${ENV}-backup
exit 1
```

## 5. 数据库迁移

### 5.1 工具选型
- **Flyway**: 基于 SQL 的迁移，适合简单场景
- **Prisma Migrate**: TypeScript 友好，适合 Prisma ORM
- **Liquibase**: 支持多数据库，适合复杂场景

### 5.2 集成到 CI/CD
```yaml
  db-migrate:
    name: 🗄️ DB Migration
    runs-on: ubuntu-latest
    needs: build
    steps:
      - uses: actions/checkout@v4
      - run: npm run db:migrate
        env:
          DATABASE_URL: ${{ secrets.STAGING_DATABASE_URL }}
```

## 6. 回滚策略

### 6.1 自动回滚触发条件
- 健康检查失败 (连续 3 次)
- 错误率 > 5% (部署后 5 分钟)
- P99 延迟 > 5s (部署后 5 分钟)

### 6.2 手动回滚
```bash
# 回滚到上一个版本
docker stop dev-api-production
docker start dev-api-production-backup
```

## 7. 通知机制

| 事件 | 通知渠道 |
|------|---------|
| CI 失败 | 飞书群机器人 |
| 部署成功 | 飞书群 + 邮件 |
| 部署失败 | 飞书 + 短信 |
| 回滚触发 | 飞书 + 电话 |

---

> 创建时间: 2026-07-08
> 创建者: 研发部高级研发专家
> 状态: 待评审
