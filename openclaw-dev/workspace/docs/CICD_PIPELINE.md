# CI/CD 流水线设计方案

## 1. 概述

设计自动化构建、测试、部署流水线，支持持续集成与持续交付。

## 2. 流水线架构

```
开发者 Push → GitHub → CI 触发 → 构建 → 测试 → 安全扫描 → SonarQube → 构建镜像 → 部署 → 通知
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

  sonarqube:
    name: 📊 SonarQube Analysis
    runs-on: ubuntu-latest
    needs: [test, security]
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # 完整历史用于 PR 分析
      - uses: sonarsource/sonarqube-scan-action@v2
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
          SONAR_HOST_URL: ${{ secrets.SONAR_HOST_URL }}
      - uses: sonarsource/sonarqube-quality-gate-action@v1
        timeout-minutes: 5
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}

  build:
    name: 📦 Build
    runs-on: ubuntu-latest
    needs: [test, security, sonarqube]
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

#### 蓝绿部署实战

```yaml
# .github/workflows/blue-green-deploy.yml
name: Blue-Green Deploy
on:
  workflow_dispatch:
    inputs:
      environment:
        description: '部署环境'
        required: true
        type: choice
        options: [staging, production]

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment }}
    steps:
      - name: 确定当前活跃环境
        id: current
        run: |
          # 检查当前是 Blue 还是 Green
          curl -sf http://${{ secrets.DEPLOY_HOST }}/api/version || echo "blue"
          echo "active=blue" >> $GITHUB_OUTPUT

      - name: 部署到非活跃环境
        run: |
          INACTIVE=${{ steps.current.outputs.active == 'blue' && 'green' || 'blue' }}
          ssh ${{ secrets.DEPLOY_USER }}@${{ secrets.DEPLOY_HOST }} "
            docker pull ghcr.io/${{ github.repository }}:${{ github.sha }}
            docker-compose -f docker-compose.$INACTIVE.yml up -d
          "

      - name: 健康检查
        run: |
          INACTIVE=${{ steps.current.outputs.active == 'blue' && 'green' || 'blue' }}
          for i in {1..15}; do
            if curl -sf http://${{ secrets.DEPLOY_HOST }}:${{ secrets.HEALTH_PORT_$INACTIVE }}/health; then
              echo "✅ 健康检查通过"
              exit 0
            fi
            sleep 4
          done
          echo "❌ 健康检查失败"
          exit 1

      - name: 切换流量
        run: |
          ssh ${{ secrets.DEPLOY_USER }}@${{ secrets.DEPLOY_HOST }} "
            nginx -s reload
          "

      - name: 观察期 (5 分钟)
        run: sleep 300

      - name: 验证部署
        run: |
          # 检查错误率
          ERROR_RATE=$(curl -s http://${{ secrets.DEPLOY_HOST }}/api/metrics | grep error_rate)
          if [ "$ERROR_RATE" -gt 5 ]; then
            echo "❌ 错误率过高，触发回滚"
            exit 1
          fi

      - name: 清理旧环境
        if: success()
        run: |
          ACTIVE=${{ steps.current.outputs.active }}
          ssh ${{ secrets.DEPLOY_USER }}@${{ secrets.DEPLOY_HOST }} "
            docker-compose -f docker-compose.$ACTIVE.yml down
          "
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

### 7.1 飞书通知 (待凭证恢复后启用)

```yaml
  notify:
    name: 📢 Notify
    needs: [deploy]
    if: always()
    runs-on: ubuntu-latest
    steps:
      - name: 飞书通知
        run: |
          curl -X POST ${{ secrets.FEISHU_WEBHOOK }} \
            -H "Content-Type: application/json" \
            -d '{
              "msg_type": "interactive",
              "card": {
                "header": {
                  "title": {
                    "tag": "plain_text",
                    "content": "${{ job.status == \"success\" && \"✅ 部署成功\" || \"❌ 部署失败\" }}"
                  }
                },
                "elements": [
                  {
                    "tag": "div",
                    "text": {
                      "content": "环境: ${{ github.event.inputs.environment }}\n版本: ${{ github.sha }}\n触发者: ${{ github.actor }}"
                    }
                  }
                ]
              }
            }'
```

### 7.2 通知矩阵

| 事件 | 飞书 | 邮件 | 短信 | 电话 |
|------|------|------|------|------|
| CI 失败 | ✅ | - | - | - |
| 部署成功 | ✅ | ✅ | - | - |
| 部署失败 | ✅ | ✅ | ✅ | - |
| 回滚触发 | ✅ | ✅ | ✅ | ✅ |
| SonarQube 质量门禁失败 | ✅ | ✅ | - | - |

---

> 创建时间: 2026-07-08  
> 最后更新: 2026-08-24  
> 创建者: 研发部高级研发专家  
> 变更: 补充 SonarQube 集成、蓝绿部署实战配置、飞书通知模板
