# 研发部 Onboarding 指南

## 1. 环境搭建

### 1.1 前置条件
- Node.js 20+ (推荐 nvm 管理)
- PostgreSQL 16+ (当前: 172.23.0.20:5432)
- Docker & Docker Compose
- Git

### 1.2 工作区结构
```
/home/node/.openclaw/workspace/
├── docs/             # 技术文档 (36 篇)
│   ├── POSTGRES_BACKUP_STRATEGY.md
│   ├── CODE_QUALITY_STANDARDS.md
│   ├── SECURITY_BASELINE.md
│   ├── DEV_WORKPLAN_2026H2_2027Q1.md
│   └── ... (详见 docs/README.md)
├── scripts/          # 运维脚本
│   ├── db-health-monitor.js  # DB 健康监控
│   ├── backup.sh             # 数据库备份
│   └── restore.sh            # 数据库恢复
├── lib/              # 工具库
│   └── task-scheduler.js     # 任务调度系统
├── logs/             # 运行日志
│   ├── db-health.log
│   └── task-scheduler.log
├── .dev-config.json  # DB 连接配置
├── package.json
└── .eslintrc.json
```

### 1.3 依赖安装
```bash
cd /home/node/.openclaw/workspace
npm install
```

### 1.4 数据库连接
```bash
# 配置已存放在 .dev-config.json
# DB: dev_db @ 172.23.0.20:5432
# 用户: dev_user
# 密码: 环境变量 DEV_DB_PASS
```

### 1.5 验证环境
```bash
# 运行 DB 健康检查
node scripts/db-health-monitor.js

# 查看任务统计
node lib/task-scheduler.js stats

# 代码检查
npm run lint
```

## 2. 开发流程

### 2.1 分支策略
- `main` - 生产环境
- `develop` - 开发环境
- `feature/描述` - 功能开发
- `fix/描述` - bug 修复
- `hotfix/描述` - 紧急修复

### 2.2 提交规范
```
<type>(<scope>): <description>

feat: 添加用户认证模块
fix: 修复数据库连接泄漏
docs: 更新 API 文档
chore: 更新依赖版本
```

### 2.3 代码审查
1. 创建 PR 到 `develop`
2. 至少 1 人 review
3. CI 检查通过 (lint/test/security/SonarQube)
4. 合并

## 3. 常用命令

| 命令 | 说明 |
|------|------|
| `npm run health-check` | DB 健康检查 |
| `npm run task-stats` | 任务统计 |
| `npm run task-list` | 待处理任务列表 |
| `npm run task-overdue` | 超时任务检查 |
| `npm run lint` | 代码检查 |
| `npm run lint:fix` | 自动修复代码格式 |
| `npm test` | 运行测试 |

## 4. 任务管理

### 4.1 任务表
- **全局任务**: `shared.tasks` (跨部门协作)
- **研发任务**: `dev_schema.dev_tasks` (研发部专用)

### 4.2 优先级
- P0: 阻塞性问题 (立即处理)
- P1: 重要不阻塞 (1-3 天)
- P2: 优化型 (1-2 周)
- P3: 锦上添花 (按月)

### 4.3 查询任务
```bash
# 查看所有待处理任务
node lib/task-scheduler.js list

# 查看我的任务
node lib/task-scheduler.js list --assignee=dev_user

# 查看超时任务
node lib/task-scheduler.js overdue

# 查看统计
node lib/task-scheduler.js stats
```

## 5. 文档导航

### 5.1 核心文档
| 文档 | 说明 |
|------|------|
| `DEV_WORKPLAN_2026H2_2027Q1.md` | 6 个月工作计划 |
| `SECURITY_BASELINE.md` | 安全基线检查清单 |
| `CODE_QUALITY_STANDARDS.md` | 代码质量规范 |
| `CICD_PIPELINE.md` | CI/CD 流水线方案 |

### 5.2 运维手册 (Runbook)
| 文档 | 说明 |
|------|------|
| `RUNBOOK_DB_RECOVERY.md` | DB 故障恢复 |
| `RUNBOOK_AGENT_RECOVERY.md` | Agent 重启/恢复 |
| `RUNBOOK_FEISHU_TROUBLESHOOTING.md` | 飞书连接排查 |

### 5.3 数据库相关
| 文档 | 说明 |
|------|------|
| `POSTGRES_BACKUP_STRATEGY.md` | 备份策略 |
| `DB_CONNECTION_POOL_MONITORING.md` | 连接池监控 |
| `SLOW_QUERY_ANALYSIS.md` | 慢查询分析 |
| `DATABASE_MIGRATION_GUIDE.md` | 数据迁移指南 |

## 6. 协作工具

- **任务管理**: PostgreSQL `shared.tasks` / `dev_schema.dev_tasks`
- **文档**: workspace/docs/ 目录
- **沟通**: 飞书 (当前凭证失效，待修复)
- **代码仓库**: GitHub (`.github/workflows/`)

## 7. 快速上手 Checklist

- [ ] 环境搭建完成 (`npm install`)
- [ ] DB 健康检查通过 (`npm run health-check`)
- [ ] 代码检查通过 (`npm run lint`)
- [ ] 阅读 CODE_QUALITY_STANDARDS.md
- [ ] 了解 CI/CD 流程 (CICD_PIPELINE.md)
- [ ] 了解任务管理系统 (task-scheduler.js)
- [ ] 领取第一个任务

---

> 创建时间: 2026-07-09  
> 最后更新: 2026-08-24  
> 创建者: 研发部高级研发专家  
> 变更: 替换占位符为实际值，添加任务管理系统说明，更新文档导航
