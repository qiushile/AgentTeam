# API 文档体系搭建方案

## 1. 概述

建立自动化 API 文档生成流程，确保文档与代码同步更新。

## 2. 技术选型

### 2.1 推荐方案：OpenAPI 3.0 + Swagger UI

| 组件 | 用途 | 工具 |
|------|------|------|
| 规范定义 | API 接口描述 | OpenAPI 3.0 (YAML/JSON) |
| 文档生成 | 从注解自动生成 | swagger-jsdoc / drf-spectacular |
| 文档展示 | 交互式 API 文档 | Swagger UI / ReDoc |
| Mock 服务 | 前端开发联调 | Prism / Mockoon |

### 2.2 备选方案
- **Postman**: 适合团队协作，支持自动化测试
- **StopLight**: 设计优先，支持 API 生命周期管理
- **Redocly**: 高性能文档渲染，支持多版本

## 3. 实施步骤

### 3.1 后端注解集成

#### Node.js (Express)
```javascript
/**
 * @openapi
 * /api/v1/tasks:
 *   get:
 *     summary: 获取任务列表
 *     tags: [Tasks]
 *     parameters:
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [PENDING, IN_PROGRESS, COMPLETED]
 *     responses:
 *       200:
 *         description: 任务列表
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Task'
 */
app.get('/api/v1/tasks', getTasks);
```

#### 生成脚本
```bash
# swagger-jsdoc
npx swagger-jsdoc -d swaggerDef.js src/**/*.js -o docs/openapi.json

# 启动 Swagger UI
npx swagger-ui-watcher docs/openapi.json
```

### 3.2 统一 OpenAPI 规范文件

```yaml
openapi: 3.0.3
info:
  title: 研发协作平台 API
  version: 1.0.0
  description: 跨部门协作系统的 RESTful API

servers:
  - url: https://api.example.com/v1
    description: 生产环境
  - url: http://localhost:3000/v1
    description: 本地开发

paths:
  /tasks:
    get:
      summary: 获取任务列表
      tags: [Tasks]
      parameters:
        - $ref: '#/components/parameters/statusFilter'
      responses:
        '200':
          description: 任务列表
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/Task'
        '401':
          $ref: '#/components/responses/Unauthorized'
    post:
      summary: 创建任务
      tags: [Tasks]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateTaskRequest'
      responses:
        '201':
          description: 创建成功
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Task'

components:
  schemas:
    Task:
      type: object
      properties:
        id:
          type: integer
          format: int64
        title:
          type: string
          maxLength: 255
        description:
          type: string
        assignee:
          type: string
        status:
          type: string
          enum: [PENDING, IN_PROGRESS, COMPLETED, FAILED, CANCELLED]
        created_at:
          type: string
          format: date-time
        updated_at:
          type: string
          format: date-time
      required: [id, title, status]
    
    CreateTaskRequest:
      type: object
      properties:
        title:
          type: string
          maxLength: 255
        description:
          type: string
        assignee:
          type: string
      required: [title]

  parameters:
    statusFilter:
      name: status
      in: query
      schema:
        type: string
        enum: [PENDING, IN_PROGRESS, COMPLETED, FAILED, CANCELLED]

  responses:
    Unauthorized:
      description: 未授权
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
    
    Error:
      type: object
      properties:
        code:
          type: integer
        message:
          type: string
```

### 3.3 CI/CD 集成

```yaml
# GitHub Actions
name: API Docs
on:
  push:
    paths: ['src/**/*.js', 'docs/openapi.yaml']

jobs:
  generate-docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: npm run generate:openapi
      - name: Validate OpenAPI
        uses: swaggerexpert/swagger-editor-validate@v1
        with:
          definition-file: docs/openapi.json
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        if: github.ref == 'refs/heads/main'
        with:
          publish_dir: ./docs
```

## 4. 文档站点结构

```
docs/
├── openapi.json          # OpenAPI 规范文件
├── index.html            # Swagger UI 入口
├── getting-started.md    # 快速开始指南
├── authentication.md     # 认证说明
├── errors.md             # 错误码说明
└── changelog.md          # API 变更日志
```

## 5. API 版本管理

| 版本 | 路径前缀 | 状态 | 维护周期 |
|------|---------|------|---------|
| v1 | `/api/v1/` | 当前 | 长期支持 |
| v2 | `/api/v2/` | 规划中 | - |

**废弃策略**: 旧版本 API 保留至少 6 个月，通过 HTTP 响应头 `Sunset` 通知废弃时间。

## 6. Mock 服务

使用 Prism 基于 OpenAPI 规范自动生成 Mock 服务：

```bash
# 安装
npm install -g @stoplight/prism-cli

# 启动 Mock 服务
prism mock docs/openapi.json
# 服务地址: http://localhost:4010
```

---

> 创建时间: 2026-07-08
> 创建者: 研发部高级研发专家
> 状态: 待评审
