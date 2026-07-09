# 研发部 Onboarding 指南

## 1. 环境搭建

### 1.1 前置条件
- Node.js 20+
- PostgreSQL 16+
- Docker & Docker Compose
- Git

### 1.2 克隆项目
```bash
git clone <repo-url>
cd <project-dir>
npm install
```

### 1.3 环境变量
```bash
cp .env.example .env
# 编辑 .env 填入数据库连接信息等
```

### 1.4 数据库初始化
```bash
npm run db:migrate
npm run db:seed
```

### 1.5 启动开发服务器
```bash
npm run dev
```

## 2. 项目结构

```
project/
├── src/
│   ├── api/          # API 路由
│   ├── services/     # 业务逻辑
│   ├── models/       # 数据模型
│   ├── utils/        # 工具函数
│   └── config/       # 配置文件
├── docs/             # 文档
│   ├── POSTGRES_BACKUP_STRATEGY.md
│   ├── CODE_QUALITY_STANDARDS.md
│   ├── API_DOCUMENTATION_STRATEGY.md
│   └── ...
├── scripts/          # 运维脚本
│   ├── backup.sh
│   ├── restore.sh
│   ├── dev-query.js
│   └── dev-task.js
├── .github/          # CI/CD
│   ├── workflows/
│   └── dependabot.yml
├── .eslintrc.json
├── .prettierrc
└── .editorconfig
```

## 3. 开发流程

### 3.1 分支策略
- `main` - 生产环境
- `develop` - 开发环境
- `feature/描述` - 功能开发
- `fix/描述` - bug 修复
- `hotfix/描述` - 紧急修复

### 3.2 提交规范
```
<type>(<scope>): <description>

feat: 添加用户认证模块
fix: 修复数据库连接泄漏
docs: 更新 API 文档
chore: 更新依赖版本
```

### 3.3 代码审查
1. 创建 PR 到 `develop`
2. 至少 1 人 review
3. CI 检查通过 (lint/test/security)
4. 合并

## 4. 常用命令

| 命令 | 说明 |
|------|------|
| `npm run dev` | 启动开发服务器 |
| `npm run build` | 生产构建 |
| `npm test` | 运行测试 |
| `npm run lint` | 代码检查 |
| `npm run lint:fix` | 自动修复代码格式 |
| `npm run db:migrate` | 执行数据库迁移 |

## 5. 协作工具

- **任务管理**: PostgreSQL `shared.tasks` / `dev_schema.dev_tasks`
- **文档**: workspace/docs/ 目录
- **沟通**: 飞书
- **代码仓库**: GitHub

## 6. 快速上手 checklist

- [ ] 环境搭建完成
- [ ] 项目可以本地运行
- [ ] 通过 `npm test`
- [ ] 阅读 CODE_QUALITY_STANDARDS.md
- [ ] 了解 CI/CD 流程
- [ ] 获取飞书访问权限
- [ ] 领取第一个任务

---

> 创建时间: 2026-07-09
> 创建者: 研发部高级研发专家
